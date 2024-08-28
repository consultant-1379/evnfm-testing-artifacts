{{/* vim: set filetype=mustache: */}}

{{/*
Create a map from ".Values.global" with defaults if missing in values file.
This hides defaults from values file.
*/}}
{{ define "eric-pm-bulk-reporter.global" }}
  {{- $globalDefaults := dict "security" (dict "tls" (dict "enabled" true)) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "url" "armdocker.rnd.ericsson.se")) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "nodeSelector" (dict)) -}}
  {{ if .Values.global }}
    {{- mergeOverwrite $globalDefaults .Values.global | toJson -}}
  {{ else }}
    {{- $globalDefaults | toJson -}}
  {{ end }}
{{ end }}

{{/*
Expand the name of the chart.
*/}}
{{- define "eric-pm-bulk-reporter.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "eric-pm-bulk-reporter.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create version
*/}}
{{- define "eric-pm-bulk-reporter.version" -}}
{{- printf "%s" .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create image pull secrets
*/}}
{{- define "eric-pm-bulk-reporter.pullSecrets" -}}
  {{- if .Values.imageCredentials.pullSecret }}
    {{- print .Values.imageCredentials.pullSecret }}
  {{- else -}}
    {{- $g := fromJson (include "eric-pm-bulk-reporter.global" .) -}}
    {{- if $g.pullSecret }}
      {{- print $g.pullSecret }}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Create scheme for ready and liveness
*/}}
{{- define "eric-pm-bulk-reporter.scheme" -}}
{{- $g := fromJson (include "eric-pm-bulk-reporter.global" .) -}}
{{- if $g.security.tls.enabled }}
{{- print "HTTPS" }}
{{- else }}
{{- print "HTTP" }}
{{- end }}
{{- end -}}

{{/*
Create a merged set of nodeSelectors from global and service level.
*/}}
{{ define "eric-pm-bulk-reporter.nodeSelector" }}
{{- $g := fromJson (include "eric-pm-bulk-reporter.global" .) -}}
  {{- $global := $g.nodeSelector -}}
  {{- $deprecatedService := .Values.nodeSelector -}}
  {{- range $key, $val := $deprecatedService -}}
    {{- if not (kindIs "string" $val) -}}
      {{- $deprecatedService = omit $deprecatedService $key -}}
    {{- end -}}
  {{- end -}}

  {{- $service := dict -}}
  {{- if (empty $deprecatedService) -}}
    {{- $service = (index (default (dict) .Values.nodeSelector) "eric-pm-bulk-reporter") -}}
    {{- range $key, $val := $service -}}
      {{- if not (kindIs "string" $val) -}}
        {{- $service = omit $service $key -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- $context := "eric-pm-bulk-reporter.nodeSelector" -}}
  {{- include "eric-pm-bulk-reporter.aggregatedMerge" (dict "context" $context "location" .Template.Name "sources" (list $deprecatedService $service $global)) | trim -}}
{{ end }}

{{/*
Create bandwidth maxEgressRate
*/}}
{{- define "eric-pm-bulk-reporter.maxEgressRate" -}}
{{- if (hasKey .Values.bandwidth "eric-pm-bulk-reporter") -}}
  {{- (index .Values.bandwidth "eric-pm-bulk-reporter" "maxEgressRate") }}
{{- else -}}
{{- if .Values.bandwidth.maxEgressRate -}}
  {{- .Values.bandwidth.maxEgressRate }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create topologySpreadConstraints
*/}}
{{- define "eric-pm-bulk-reporter.topologySpreadConstraints" -}}
{{- if (kindIs "map" .Values.topologySpreadConstraints) -}}
  {{- if (hasKey .Values.topologySpreadConstraints "eric-pm-bulk-reporter") -}}
    {{- if (index .Values.topologySpreadConstraints "eric-pm-bulk-reporter") -}}
      {{- toYaml (index .Values.topologySpreadConstraints "eric-pm-bulk-reporter") }}
    {{- end -}}
  {{- end -}}
{{- else if .Values.topologySpreadConstraints -}}
  {{- toYaml .Values.topologySpreadConstraints }}
{{- end -}}
{{- end -}}

{{/*
Create IPv4 boolean service/global/<notset>
*/}}
{{- define "eric-pm-bulk-reporter-service.enabled-IPv4" -}}
{{- $g := fromJson (include "eric-pm-bulk-reporter.global" .) -}}
{{- if .Values.service.externalIPv4.enabled | quote -}}
{{- .Values.service.externalIPv4.enabled -}}
{{- else -}}
{{- if $g -}}
{{- if $g.externalIPv4 -}}
{{- if $g.externalIPv4.enabled | quote -}}
{{- $g.externalIPv4.enabled -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
DR-470222-010: a local parameter log.streamingMethod (choice="indirect, direct, dual")
and global parameter global.log.streamingMethod shall be used to determine logging method.
These parameters shall replace global.log.outputs/log.outputs which will be deprecated.
Support for parameter global.log.outputs is *maintained*, but with lower precedence.
Usage of global.log.outputs will be removed at the end of deprecation.
Order of precedence:
log.streamingMethod > global.log.streamingMethod > global.log.outputs > ""
*/}}
{{- define "eric-pm-bulk-reporter.streamingMethod" -}}
  {{- $streamingMethod := "" -}}
  {{- if (((.Values.global).log).outputs) -}}
    {{- if has "stdout" (((.Values).global).log).outputs -}}
      {{- $streamingMethod = "indirect" -}}
    {{- end -}}
    {{- if has "stream" (((.Values).global).log).outputs -}}
      {{- $streamingMethod = "direct" -}}
    {{- end -}}
    {{- if and (has "stdout" (((.Values).global).log).outputs) (has "stream" (((.Values).global).log).outputs) -}}
      {{- $streamingMethod = "dual" -}}
    {{- end -}}
  {{- end -}}
  {{- if ((((.Values).global).log).streamingMethod) -}}
    {{- $streamingMethod = (((.Values).global).log).streamingMethod -}}
  {{- end -}}
  {{- if (((.Values).log).streamingMethod) -}}
    {{- $streamingMethod = ((.Values).log).streamingMethod -}}
  {{- end -}}
  {{- printf "%s" $streamingMethod -}}
{{ end }}

{{/* Return "true" if streamingMethod is "dual" or "direct"
Otherwise, return "false"
*/}}

{{- define "eric-pm-bulk-reporter.logShipperEnabled" -}}
{{- $streamingMethod := (include "eric-pm-bulk-reporter.streamingMethod" .) -}}
{{- if or (eq $streamingMethod "dual") (eq $streamingMethod "direct") -}}
  {{- printf "%t" true -}}
{{- else -}}
  {{- printf "%t" false -}}
{{- end -}}
{{ end }}

{{/*
Define log outputs
Return of this template would be used as input of redirect-stdout
Possible return values: stdout, file, all
Mapping values between log.streamingMethod and legacy return of eric-pm-bulk-reporter.log.outputs
"indirect" --> "stdout"
"direct"   --> "file"
"dual"     --> "all"
Default: stdout
*/}}
{{- define "eric-pm-bulk-reporter.log.outputs" -}}
{{- $redirect := "" -}}
{{- $streamingMethod := (include "eric-pm-bulk-reporter.streamingMethod" .) -}}
{{- if eq $streamingMethod "dual" -}}
  {{- $redirect = "all" }}
{{- else if eq $streamingMethod "direct" -}}
  {{- $redirect = "file" }}
{{- else -}}
  {{- $redirect = "stdout" -}}
{{- end -}}
{{- print $redirect -}}
{{- end -}}

{{/*
Create IPv6 boolean service/global/<notset>
*/}}
{{- define "eric-pm-bulk-reporter-service.enabled-IPv6" -}}
{{- $g := fromJson (include "eric-pm-bulk-reporter.global" .) -}}
{{- if .Values.service.externalIPv6.enabled | quote -}}
{{- .Values.service.externalIPv6.enabled -}}
{{- else -}}
{{- if $g -}}
{{- if $g.externalIPv6 -}}
{{- if $g.externalIPv6.enabled | quote -}}
{{- $g.externalIPv6.enabled -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "eric-pm-bulk-reporter.fsGroup.coordinated" -}}
{{- $g := fromJson (include "eric-pm-bulk-reporter.global" .) -}}
    {{- if $g -}}
        {{- if $g.fsGroup -}}
            {{- if $g.fsGroup.manual -}}
                {{ $g.fsGroup.manual }}
            {{- else -}}
                {{- if $g.fsGroup.namespace -}}
                    {{- if eq $g.fsGroup.namespace true -}}
                         # The namespace default value is used
                    {{- else -}}
                        10000
                    {{- end -}}
                {{- else -}}
                    10000
                {{- end -}}
            {{- end -}}
        {{- else -}}
            10000
        {{- end -}}
    {{- else -}}
        10000
    {{- end -}}
{{- end -}}

{{/*
  DR-D1123-135 Configuration of supplementalGroups IDs
*/}}
{{- define "eric-pm-bulk-reporter.supplementalGroups" -}}
  {{- $globalGroups := list -}}
  {{- if .Values.global -}}
    {{- if .Values.global.podSecurityContext -}}
      {{- if .Values.global.podSecurityContext.supplementalGroups -}}
        {{- if kindIs "slice" .Values.global.podSecurityContext.supplementalGroups -}}
          {{- $globalGroups = .Values.global.podSecurityContext.supplementalGroups -}}
        {{- else -}}
          {{- printf "global.podSecurityContext.supplementalGroups, \"%s\", is not a list." .Values.global.podSecurityContext.supplementalGroups | fail -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- $localGroups := list -}}
  {{- if .Values.podSecurityContext -}}
    {{- if .Values.podSecurityContext.supplementalGroups -}}
      {{- if kindIs "slice" .Values.podSecurityContext.supplementalGroups -}}
        {{- $localGroups = .Values.podSecurityContext.supplementalGroups -}}
      {{- else -}}
        {{- printf "podSecurityContext.supplementalGroups, \"%s\", is not a list." .Values.podSecurityContext.supplementalGroups | fail -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- $mergedGroups := list -}}
  {{- range (concat $globalGroups $localGroups | uniq) -}}
    {{- if ne (. | toString) "" -}}
      {{- $mergedGroups = (append $mergedGroups . ) -}}
    {{- end -}}
  {{- end -}}

  {{- if gt (len $mergedGroups) 0 -}}
    {{ print "supplementalGroups:" }}
    {{- toYaml $mergedGroups | nindent 2 }}
  {{- end -}}
{{- end -}}

{{/*
Define Kubernetes labels
*/}}
{{- define "eric-pm-bulk-reporter.kubernetes-labels" }}
  app.kubernetes.io/name: {{ template "eric-pm-bulk-reporter.name" . }}
  app.kubernetes.io/version: {{ template "eric-pm-bulk-reporter.version" . }}
  app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- end -}}

{{- define "eric-pm-bulk-reporter.meta-labels" }}
{{- $g := fromJson (include "eric-pm-bulk-reporter.global" .) -}}
  {{- $static := dict -}}
  {{- $_ := set $static "app" (include "eric-pm-bulk-reporter.name" .) -}}
  {{- $_ := set $static "release" (.Release.Name | toString) -}}
  {{- $kubernetes := include "eric-pm-bulk-reporter.kubernetes-labels" . | fromYaml -}}
  {{- $global := $g.labels -}}
  {{- $service := .Values.labels -}}
  {{- include "eric-pm-bulk-reporter.mergeLabels" (dict "location" (.Template.Name) "sources" (list $static $kubernetes $global $service)) | trim }}
{{- end}}

{{- define "eric-pm-bulk-reporter.labels" -}}
  {{- $static := dict -}}
  {{- $_ := set $static "chart" (include "eric-pm-bulk-reporter.chart" .) -}}
  {{- $_ := set $static "heritage" (.Release.Service | toString) -}}
  {{- $meta := include "eric-pm-bulk-reporter.meta-labels" . | fromYaml -}}
  {{- include "eric-pm-bulk-reporter.mergeLabels" (dict "location" (.Template.Name) "sources" (list $static $meta)) | trim }}
{{- end -}}

{{/*
DR-D470217-001: Avoid interception of pod creation by SM admission webhook
*/}}
{{- define "eric-pm-bulk-reporter.servicemesh-labels" }}
  sidecar.istio.io/inject: "false"
{{- end }}

{{/*
Logshipper labels
*/}}
{{- define "eric-pm-bulk-reporter.logshipper-labels" }}
{{- include "eric-pm-bulk-reporter.labels" . -}}
{{- end }}

{{/*
  DR-D1123-124: Create security policy.
*/}}
{{- define "eric-pm-bulk-reporter.securityPolicy.annotations" -}}
# Automatically generated annotations for documentation purposes.
{{- end -}}

{{/*
Define helm-annotations
*/}}
{{- define "eric-pm-bulk-reporter.helm-annotations" }}
  ericsson.com/product-name: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productName | quote }}
  ericsson.com/product-number: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productNumber | quote }}
  ericsson.com/product-revision: {{regexReplaceAll "(.*)[+-].*" .Chart.Version "${1}" }}
{{- end}}

{{/*
Define annotations
*/}}
{{- define "eric-pm-bulk-reporter.annotations" -}}
{{- $g := fromJson (include "eric-pm-bulk-reporter.global" .) -}}
  {{- $helm := include "eric-pm-bulk-reporter.helm-annotations" . | fromYaml -}}
  {{- $global := $g.annotations -}}
  {{- $service := .Values.annotations -}}
  {{- include "eric-pm-bulk-reporter.mergeAnnotations" (dict "location" (.Template.Name) "sources" (list $helm $global $service)) | trim }}
{{- end -}}

{{- define "eric-pm-bulk-reporter.imagePath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $image := (get $productInfo.images .imageName) -}}
    {{- $registryUrl := $image.registry -}}
    {{- $repoPath := $image.repoPath -}}
    {{- $name := $image.name -}}
    {{- $tag := $image.tag -}}
    {{- $g := fromJson (include "eric-pm-bulk-reporter.global" .) -}}
    {{- if or .Values.imageCredentials.registry.url $g.registry.url -}}
        {{- $registryUrl = or .Values.imageCredentials.registry.url $g.registry.url -}}
    {{- end -}}
    {{- if or (not (kindIs "invalid" .Values.imageCredentials.repoPath)) (not (kindIs "invalid" $g.registry.repoPath)) -}}
        {{- $repoPath = or (.Values.imageCredentials.repoPath) ($g.registry.repoPath) -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
        {{- if hasKey .Values.imageCredentials .imageName -}}
            {{- $credImage := get .Values.imageCredentials .imageName }}
            {{- if $credImage.registry -}}
                {{- if $credImage.registry.url -}}
                    {{- $registryUrl = $credImage.registry.url -}}
                {{- end -}}
            {{- end -}}
            {{- if not (kindIs "invalid" $credImage.repoPath) -}}
                {{- $repoPath = $credImage.repoPath -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if $repoPath -}}
        {{- $repoPath = printf "%s/" $repoPath -}}
    {{- else -}}
        {{- $repoPath = print "" -}}
    {{- end -}}
    {{- if .Values.images -}}
      {{- if hasKey .Values.images .imageName -}}
          {{- $deprecatedImageParam := get .Values.images .imageName }}
          {{- if $deprecatedImageParam.name }}
              {{- $name = $deprecatedImageParam.name -}}
          {{- end -}}
          {{- if $deprecatedImageParam.tag }}
              {{- $tag = $deprecatedImageParam.tag -}}
          {{- end -}}
      {{- end -}}
    {{- end -}}
    {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}

{{/*
Define eric-pm-bulk-reporter.resources
*/}}
{{- define "eric-pm-bulk-reporter.resources" -}}
{{- if .limits }}
  limits:
  {{- if .limits.cpu }}
    cpu: {{ .limits.cpu | quote }}
  {{- end -}}
  {{- if (index .limits "ephemeral-storage") }}
    ephemeral-storage: {{ index .limits "ephemeral-storage" | quote }}
  {{- end -}}
  {{- if .limits.memory }}
    memory: {{ .limits.memory | quote }}
  {{- end -}}
{{- end -}}
{{- if .requests }}
  requests:
  {{- if .requests.cpu }}
    cpu: {{ .requests.cpu | quote }}
  {{- end -}}
  {{- if (index .requests "ephemeral-storage") }}
    ephemeral-storage: {{ index .requests "ephemeral-storage" | quote }}
  {{- end -}}
  {{- if .requests.memory }}
    memory: {{ .requests.memory | quote }}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
 CA Secret provided by PM Server
*/}}
{{- define "eric-pm-bulk-reporter.pmSecretName" -}}
  {{- if .Values.pmServer.pmServiceName -}}
    {{- .Values.pmServer.pmServiceName -}}
  {{- else -}}
    eric-pm-server
  {{- end -}}
{{- end -}}

{{/*
Get the sftp container port.
*/}}
{{- define "eric-pm-bulk-reporter.sftp-port" -}}
  {{- .Values.service.servicePort -}}
{{- end -}}

{{/*
Get the default port.
*/}}
{{- define "eric-pm-bulk-reporter.default-port" -}}
  {{- $g := fromJson (include "eric-pm-bulk-reporter.global" .) -}}
  {{- if $g.security.tls.enabled -}}
    9089
  {{- else -}}
    9090
  {{- end -}}
{{- end -}}

{{/*
Get the metrics port.
*/}}
{{- define "eric-pm-bulk-reporter.metrics-port" -}}
  {{- $g := fromJson (include "eric-pm-bulk-reporter.global" .) -}}
  {{- if $g.security.tls.enabled -}}
    9089
  {{- else -}}
    9090
  {{- end -}}
{{- end -}}

{{/*
Get the metrics scheme.
*/}}
{{- define "eric-pm-bulk-reporter.protmetheus-io-scheme" -}}
  {{- $g := fromJson (include "eric-pm-bulk-reporter.global" .) -}}
  {{- if $g.security.tls.enabled -}}
    {{- print "https" -}}
  {{- else -}}
    {{- print "http" -}}
  {{- end -}}
{{- end -}}

{{/*
PM bulk reporter Labels for Network Policies
*/}}
{{- define "eric-pm-bulk-reporter.peer.labels" -}}
{{- if (eq "true" (include "eric-pm-bulk-reporter.logShipperEnabled" .)) }}
{{ .Values.logShipper.output.logTransformer.host }}-access: "true"
{{- end }}
{{ .Values.security.tls.cmMediator.serviceName }}-access: "true"
{{ .Values.security.tls.pmServer.serviceName }}-access: "true"
{{ .Values.security.tls.objectStorage.serviceName }}-access: "true"
{{ .Values.security.keyManagement.serviceName }}-access: "true"
{{- if .Values.trace.enabled }}
{{ .Values.trace.agent.host }}-access: "true"
{{- end }}
{{- if .Values.thresholdReporter.enabled }}
{{ .Values.thresholdReporter.alarmHandlerHostname }}-access: "true"
{{- end }}
{{- if .Values.applicationId.enabled }}
{{ .Values.applicationId.asihHostname }}-access: "true"
{{- end }}
{{- if .Values.aumSupport.enabled }}
{{ .Values.aumSupport.serviceName }}-access: "true"
{{- end }}
{{- if and .Values.userConfig.ldap.enabled .Values.global }}
{{- if .Values.global.networkPolicy }}
{{- if .Values.global.networkPolicy.enabled }}
eric-sec-ldap-server-access: "true"
{{- end }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Define eric-pm-bulk-reporter.appArmorProfileAnnotation
*/}}
{{- define "eric-pm-bulk-reporter.appArmorProfileAnnotation" -}}
{{- $acceptedProfiles := list "unconfined" "runtime/default" "localhost" }}
{{- $commonProfile := dict -}}
{{- if .Values.appArmorProfile.type -}}
  {{- $_ := set $commonProfile "type" .Values.appArmorProfile.type -}}
  {{- if and (eq .Values.appArmorProfile.type "localhost") .Values.appArmorProfile.localhostProfile -}}
    {{- $_ := set $commonProfile "localhostProfile" .Values.appArmorProfile.localhostProfile -}}
  {{- end -}}
{{- end -}}
{{- $profiles := dict -}}
{{- $containers := list "eric-pm-br-initcontainer" "eric-pm-bulk-reporter" "eric-pm-sftp" -}}
{{- if (eq "true" (include "eric-pm-bulk-reporter.logShipperEnabled" .)) }}
  {{- $containers = append $containers "logshipper" -}}
{{- end -}}
{{- if .Values.thresholdReporter.enabled -}}
  {{- $containers = append $containers "eric-pm-alarm-reporter" -}}
{{- end -}}
{{- range $container := $containers -}}
  {{- $_ := set $profiles $container $commonProfile -}}
  {{- if (hasKey $.Values.appArmorProfile $container) -}}
    {{- if (index $.Values.appArmorProfile $container "type") -}}
      {{- $_ := set $profiles $container (index $.Values.appArmorProfile $container) -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- range $key, $value := $profiles -}}
  {{- if $value.type -}}
    {{- if not (has $value.type $acceptedProfiles) -}}
      {{- fail (printf "Unsupported appArmor profile type: %s, use one of the supported profiles %s" $value.type $acceptedProfiles) -}}
    {{- end -}}
    {{- if and (eq $value.type "localhost") (empty $value.localhostProfile) -}}
      {{- fail "The 'localhost' appArmor profile requires a profile name to be provided in localhostProfile parameter." -}}
    {{- end }}
container.apparmor.security.beta.kubernetes.io/{{ $key }}: {{ $value.type }}{{ eq $value.type "localhost" | ternary (printf "/%s" $value.localhostProfile) ""  }}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Define podPriority check
*/}}
{{- define "eric-pm-bulk-reporter.podpriority" }}
{{- if .Values.podPriority }}
  {{- if index .Values.podPriority "eric-pm-bulk-reporter" -}}
    {{- if (index .Values.podPriority "eric-pm-bulk-reporter" "priorityClassName") }}
      priorityClassName: {{ index .Values.podPriority "eric-pm-bulk-reporter" "priorityClassName" | quote }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}


{{/*
Define eric-pm-bulk-reporter.podSeccompProfile
*/}}
{{- define "eric-pm-bulk-reporter.podSeccompProfile" -}}
{{- if and .Values.seccompProfile .Values.seccompProfile.type }}
seccompProfile:
  type: {{ .Values.seccompProfile.type }}
  {{- if eq .Values.seccompProfile.type "Localhost" }}
  localhostProfile: {{ .Values.seccompProfile.localhostProfile }}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
Name of the directory containing the file containing authentication failure delay
*/}}
{{- define "eric-pm-bulk-reporter.authFailDelayMountPath" -}}
/var/mount/aum/auth_failure_delay
{{- end }}

{{/*
Define eric-pm-bulk-reporter.userConfig.validate
*/}}
{{- define "eric-pm-bulk-reporter.userConfig.validate" -}}
{{- if not ( or ( .Values.userConfig.ldap.enabled ) ( and .Values.userConfig.secretName ( .Values.userConfig.secretKey ))) }}
  {{- fail "No users available. Either LDAP or local users must be configured." }}
{{- end }}
{{- end -}}


{{/*
Create image pull policy, service level parameter takes precedence
*/}}
{{- define "eric-pm-bulk-reporter.pullPolicy" -}}
{{- $g := fromJson (include "eric-pm-bulk-reporter.global" .) -}}
{{- $pullPolicy := "IfNotPresent" -}}
{{- if .Values.global -}}
    {{- if $g.registry -}}
        {{- if $g.registry.imagePullPolicy -}}
            {{- $pullPolicy = $g.registry.imagePullPolicy -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- if .Values.imageCredentials.registry.imagePullPolicy -}}
    {{- $pullPolicy = .Values.imageCredentials.registry.imagePullPolicy -}}
{{- end -}}
{{- print $pullPolicy -}}
{{- end -}}

{{/*
  Define IPQoS DSCP value
*/}}
{{- define "eric-pm-bulk-reporter.dscp" -}}
  {{- $dscp := 0 -}}
  {{- if .Values.service.pmBulksftpPort.dscp -}}
    {{- $dscp = (.Values.service.pmBulksftpPort.dscp) | int -}}
    {{- if or (lt $dscp 0) (gt $dscp 63) -}}
      {{- fail "service.pmBulksftpPort.dscp must be in range [0..63]" }}
    {{- end -}}
  {{- end -}}
  {{- printf " %s" (mul $dscp 4 | toString) -}}
{{- end -}}

{{- define "eric-pm-bulk-reporter.adpLogEnvList" -}}
{{- $top := index . 0 -}}
{{- $name := index . 1 -}}
- name: NAMESPACE
  valueFrom:
    fieldRef:
      fieldPath: metadata.namespace
- name: POD_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
{{- end -}}

{{/*
  Translate logLevel to sssd log level
*/}}
{{- define "eric-pm-bulk-reporter.sssdDebugLevel" -}}
  {{- if eq .Values.env.logLevel "debug" -}}
    {{- print "0x07F0" -}}
  {{- else if eq .Values.env.logLevel "info" -}}
    {{- print "0x00F0" -}}
  {{- else if eq .Values.env.logLevel "warning" -}}
    {{- print "0x00F0" -}}
  {{- else if eq .Values.env.logLevel "error" -}}
    {{- print "0x0070" -}}
  {{- else if eq .Values.env.logLevel "critical" -}}
    {{- print "0x0030" -}}
  {{- else -}}
    {{- print "0x00F0" -}}
  {{- end -}}
{{- end -}}

{{/*
  Translate logLevel to sshd log level
*/}}
{{- define "eric-pm-bulk-reporter.sshdDebugLevel" -}}
  {{- if eq .Values.env.logLevel "debug" -}}
    {{- print "DEBUG" -}}
  {{- else if eq .Values.env.logLevel "info" -}}
    {{- print "INFO" -}}
  {{- else if eq .Values.env.logLevel "warning" -}}
    {{- print "ERROR" -}}
  {{- else if eq .Values.env.logLevel "error" -}}
    {{- print "ERROR" -}}
  {{- else if eq .Values.env.logLevel "critical" -}}
    {{- print "FATAL" -}}
  {{- else -}}
    {{- print "INFO" -}}
  {{- end -}}
{{- end -}}

{{/*
  Define HostKey for sshd_config
*/}}
{{- define "eric-pm-bulk-reporter.sftp-hostkeys" -}}
{{- $supportedHostKeyFiles := list "ssh_host_rsa_key" "ssh_host_dsa_key" "ssh_host_ecdsa_key" "ssh_host_ed25519_key" }}
{{- $g := fromJson (include "eric-pm-bulk-reporter.global" .) -}}
{{- if .Values.security.certificateManagement.enabled }}
  {{- if .Values.security.keyManagement.enabled }}
    {{- printf "security.keyManagement.enabled can't be set true with security.certificateManagement.enabled" | fail }}
  {{- end }}
HostKey /opt/sftp-rw-k8s/etc/ssh/ssh_host_certm_key
{{- else }}
  {{- if .Values.env.sshdHostKeyAlgorithmsOverride }}
    {{- $hostkeyfiles := splitList ":" .Values.env.sshdHostKeyAlgorithmsOverride }}
    {{- range $keyfile := $hostkeyfiles }}
       {{- if has $keyfile $supportedHostKeyFiles }}
{{ printf "HostKey /opt/sftp-rw-k8s/etc/ssh/%s" $keyfile }}
       {{- else }}
         {{- printf "Unknown host key file %s, choose from ssh_host_rsa_key, ssh_host_dsa_key, ssh_host_ecdsa_key and ssh_host_ed25519_key" $keyfile | fail }}
       {{- end }}
    {{- end }}
  {{- else }}
HostKey /opt/sftp-rw-k8s/etc/ssh/ssh_host_ed25519_key
HostKey /opt/sftp-rw-k8s/etc/ssh/ssh_host_dsa_key
{{- /*
  The following host keys are to be removed from default keys once deprecation ADPPRG-145476 ends
*/}}
HostKey /opt/sftp-rw-k8s/etc/ssh/ssh_host_rsa_key
HostKey /opt/sftp-rw-k8s/etc/ssh/ssh_host_ecdsa_key
  {{- end }}
{{- end }}
{{- end }}

{{/*
  Define eric-pm-bulk-reporter.caCert
*/}}
{{- define "eric-pm-bulk-reporter.caCert" -}}
  {{- if (((((.Values.global).security).tls).trustedInternalRootCa).secret) -}}
{{ (((((.Values.global).security).tls).trustedInternalRootCa).secret) }}
  {{- else -}}
eric-sec-sip-tls-trusted-root-cert
  {{- end -}}
{{- end -}}

{{/*
  Define PM Bulk Reporter CM Architecture
*/}}
{{- define "eric-pm-bulk-reporter.cm.architecture" -}}
{{- $g := fromJson (include "eric-pm-bulk-reporter.global" .) -}}
{{- $cmArchitecture := "cm-v1" -}}
{{- if .Values.global -}}
    {{- if $g.cm -}}
        {{- if $g.cm.architecture -}}
            {{- $cmArchitecture = $g.cm.architecture -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- print $cmArchitecture -}}
{{- end -}}
