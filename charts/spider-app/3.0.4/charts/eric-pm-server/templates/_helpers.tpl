{{/* vim: set filetype=mustache: */}}

{{/*
Create a map from ".Values.global" with defaults if missing in values file.
This hides defaults from values file.
*/}}
{{ define "eric-pm-server.global" }}
  {{- $globalDefaults := dict "security" (dict "tls" (dict "enabled" true)) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "url" "armdocker.rnd.ericsson.se")) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "timezone" "UTC") -}}
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
{{- define "eric-pm-server.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Expand the instance name of the chart.
*/}}
{{- define "eric-pm-server.instance" -}}
{{- .Release.Name -}}
{{- end -}}

{{/*
Generic value for `serviceName`
*/}}
{{- define "eric-pm-server.serviceName" -}}
{{ if .Values.server.ha.enabled }}
  serviceName: {{ .Values.promxy.headlessServiceName | quote }}
{{ else }}
  serviceName: {{ .Values.server.name | quote }}
{{ end }}
{{- end -}}

{{/*
Create version
*/}}
{{- define "eric-pm-server.version" -}}
{{- printf "%s" .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "eric-pm-server.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create image pull secrets
*/}}
{{- define "eric-pm-server.pullSecrets" -}}
  {{- if .Values.imageCredentials.pullSecret }}
    {{- print .Values.imageCredentials.pullSecret }}
  {{- else -}}
    {{- $g := fromJson (include "eric-pm-server.global" .) -}}
    {{- if $g.pullSecret }}
      {{- print $g.pullSecret }}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Create configuration reload url
*/}}
{{- define "eric-pm-server.configmap-reload.webhook" -}}
{{- $top := index . 0 }}
{{- $var := index . 1 }}
{{- $prefix := (include "eric-pm-server.prefix" $top) }}
{{- if and (ne $var "8082") $prefix -}}
{{- printf "http://127.0.0.1:%s/%s/-/reload" $var (trimPrefix "/" $prefix) -}}
{{- else -}}
{{- printf "http://127.0.0.1:%s/-/reload" $var -}}
{{- end -}}
{{- end -}}

{{/*
DR-470222-010: a local parameter log.streamingMethod (choice="indirect, direct, dual")
and global parameter global.log.streamingMethod shall be used to determine logging method.
These parameters shall replace global.log.outputs/log.outputs which will be deprecated.
Support for parameter global.log.outputs is *maintained*, but with lower precedence.
Usage of global.log.outputs will be removed at the end of deprecation.
Order of precedence:
log.streamingMethod > global.log.streamingMethod > global.log.outputs > ""
*/}}
{{- define "eric-pm-server.streamingMethod" -}}
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
{{- define "eric-pm-server.logShipperEnabled" -}}
{{- $streamingMethod := (include "eric-pm-server.streamingMethod" .) -}}
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
Mapping values between log.streamingMethod and legacy return of eric-pm-server.log.outputs
"indirect" --> "stdout"
"direct"   --> "file"
"dual"     --> "all"
Default: stdout
*/}}
{{- define "eric-pm-server.log.outputs" -}}
{{- $redirect := "stdout" -}}
{{- $streamingMethod := (include "eric-pm-server.streamingMethod" .) -}}
{{- if eq $streamingMethod "dual" -}}
  {{- $redirect = "all" }}
{{- else if eq $streamingMethod "direct" -}}
  {{- $redirect = "file" }}
{{- end -}}
{{- print $redirect -}}
{{- end -}}

{{/*
Create a merged set of nodeSelectors from global and service level.
*/}}
{{ define "eric-pm-server.nodeSelector" }}
  {{- $g := fromJson (include "eric-pm-server.global" .) -}}

  {{- $global := $g.nodeSelector -}}
  {{- $deprecatedService := .Values.nodeSelector -}}
  {{- range $key, $val := $deprecatedService -}}
    {{- if not (kindIs "string" $val) -}}
      {{- $deprecatedService = omit $deprecatedService $key -}}
    {{- end -}}
  {{- end -}}
  {{- $service := dict -}}
  {{- if (empty $deprecatedService) -}}
    {{- $service = fromJson (include "eric-pm-server.removeNonStringValues" (index .Values.nodeSelector "eric-pm-server")) -}}
  {{- end -}}
  {{- $context := "eric-pm-server.nodeSelector" -}}
  {{- include "eric-pm-server.aggregatedMerge" (dict "context" $context "location" .Template.Name "sources" (list $deprecatedService $service $global)) | trim -}}
{{ end }}

{{/*
Helper function to remove non-string values from a dictionary.
*/}}
{{ define "eric-pm-server.removeNonStringValues" }}
  {{- $dict := . -}}
  {{- range $key, $val :=  $dict -}}
    {{- if not (kindIs "string" $val) -}}
      {{- $dict = omit $dict $key -}}
    {{- end -}}
  {{- end -}}
  {{- $dict | toJson -}}
{{ end }}

{{/*
Create bandwidth maxEgressRate
*/}}
{{- define "eric-pm-server.maxEgressRate" -}}
  {{- if (hasKey .Values.bandwidth "eric-pm-server") -}}
    {{- (index .Values.bandwidth "eric-pm-server" "maxEgressRate") }}
  {{- else -}}
    {{- if .Values.bandwidth.maxEgressRate -}}
      {{- .Values.bandwidth.maxEgressRate }}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Create topologySpreadConstraints for eric-pm-server
*/}}
{{- define "eric-pm-server.topologySpreadConstraints" -}}
{{- include "eric-pm-server.createTopologySpreadConstraints" (dict "component" "eric-pm-server" "name" (include "eric-pm-server.name" .) "ctx" .) -}}
{{- end -}}


{{/*
Create topologySpreadConstraints
*/}}
{{- define "eric-pm-server.createTopologySpreadConstraints" -}}
{{- $component := .component -}}
{{- $name := .name | quote -}}
{{- $instance := (include "eric-pm-server.instance" .ctx | quote) -}}
  {{- if (kindIs "map" .ctx.Values.topologySpreadConstraints) -}}
    {{- if (hasKey .ctx.Values.topologySpreadConstraints $component) -}}
      {{- include "eric-pm-server.topologySpreadConstraints.iterate" (dict "topologySpreadConstraints" (index .ctx.Values.topologySpreadConstraints $component) "name" $name "instance" $instance )}}
    {{- end -}}
  {{- else -}}
    {{- if .ctx.Values.topologySpreadConstraints -}}
      {{- include "eric-pm-server.topologySpreadConstraints.iterate" (dict "topologySpreadConstraints" .ctx.Values.topologySpreadConstraints "name" $name "instance" $instance )}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Iterate topologySpreadConstraints
*/}}
{{- define "eric-pm-server.topologySpreadConstraints.iterate" -}}
{{- $topologySpreadConstraints := (get . "topologySpreadConstraints") -}}
{{- $name := (get . "name") -}}
{{- $instance := (get . "instance") -}}
{{- if $topologySpreadConstraints -}}
{{- range $_, $constraints := $topologySpreadConstraints }}
- maxSkew: {{ $constraints.maxSkew }}
  topologyKey: {{ $constraints.topologyKey }}
  whenUnsatisfiable: {{ $constraints.whenUnsatisfiable }}
  labelSelector:
    matchLabels:
{{- if $constraints.labelSelector }}
{{- if kindIs "map" $constraints.labelSelector }}
{{- if $constraints.labelSelector.matchLabels }}
{{- toYaml $constraints.labelSelector.matchLabels | nindent 6 }}
{{- end }}
{{- end }}
{{- end }}
      app.kubernetes.io/name: {{ $name }}
      app.kubernetes.io/instance: {{ $instance }}
{{- end }}
{{- end -}}
{{- end -}}

{{- define "eric-pm-server.fsGroup.coordinated" -}}
  {{- $g := fromJson (include "eric-pm-server.global" .) -}}
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
{{- define "eric-pm-server.supplementalGroups" -}}
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
    {{ print "supplementalGroups:" | nindent 8 }}
    {{- toYaml $mergedGroups | nindent 10 }}
  {{- end -}}
{{- end -}}

{{/*
Merged labels for common
*/}}
{{- define "eric-pm-server.labels" -}}
  {{- $g := fromJson (include "eric-pm-server.global" .) -}}
  {{- $selector := include "eric-pm-server.selectorLabels" . | fromYaml -}}
  {{- $name := (include "eric-pm-server.name" . ) }}
  {{- $static := include "eric-pm-server.static-labels" (list . $name) | fromYaml -}}
  {{- $global := $g.labels -}}
  {{- $service := .Values.labels -}}
  {{- $authorizationProxy := fromJson (include "eric-pm-server.authz-proxy-values" .) -}}
  {{- if $authorizationProxy.enabled }}
    {{- $authzProxy := include "eric-pm-server.authz-proxy-labels" . | fromYaml -}}
    {{- include "eric-pm-server.mergeLabels" (dict "location" .Template.Name "sources" (list $authzProxy $selector $static $global $service)) | trim }}
  {{- else }}
    {{- include "eric-pm-server.mergeLabels" (dict "location" .Template.Name "sources" (list $selector $static $global $service)) | trim }}
  {{- end }}
{{- end -}}

{{/*
Logshipper labels
*/}}
{{- define "eric-pm-server.logshipper-labels" }}
{{- include "eric-pm-server.labels" . -}}
{{- end }}

{{/*
Static labels
*/}}
{{- define "eric-pm-server.static-labels" -}}
{{- $top := index . 0 }}
{{- $name := index . 1 }}
app.kubernetes.io/name: {{ $name }}
app.kubernetes.io/version: {{ template "eric-pm-server.version" $top }}
chart: {{ template "eric-pm-server.chart" $top }}
heritage: {{ $top.Release.Service | quote }}
{{- end -}}

{{/*
Selector labels.
*/}}
{{- define "eric-pm-server.selectorLabels" -}}
component: {{ .Values.server.name | quote }}
app: {{ template "eric-pm-server.name" . }}
release: {{ .Release.Name | quote }}
{{- if eq (include "eric-pm-server.needInstanceLabelSelector" .) "true" }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- end -}}
{{- end }}

{{- define "eric-pm-server.needInstanceLabelSelector" }}
    {{- $needInstanceLabelSelector := false -}}
    {{- if .Release.IsInstall }}
        {{- $needInstanceLabelSelector = true -}}
    {{- else if .Release.IsUpgrade }}
        {{- $pmSs := (lookup "apps/v1" "StatefulSet" .Release.Namespace (include "eric-pm-server.name" .)) -}}
        {{- if $pmSs -}}
            {{- if hasKey $pmSs.spec.selector.matchLabels "app.kubernetes.io/instance" -}}
                {{- $needInstanceLabelSelector = true -}}
            {{- end -}}
        {{- else -}}
                {{- $needInstanceLabelSelector = true -}}
        {{- end -}}
    {{- end -}}
    {{- $needInstanceLabelSelector -}}
{{- end }}


{{/*
    DR-D1123-124: Create security policy.
*/}}
{{- define "eric-pm-server.securityPolicy.reference" -}}
  {{- $g := fromJson (include "eric-pm-server.global" .) -}}
  {{- if $g -}}
    {{- if $g.security -}}
      {{- if $g.security.policyReferenceMap -}}
        {{ $mapped := index .Values "global" "security" "policyReferenceMap" "default-restricted-security-policy" }}
        {{- if $mapped -}}
          {{ $mapped }}
        {{- else -}}
          default-restricted-security-policy
        {{- end -}}
      {{- else -}}
        default-restricted-security-policy
      {{- end -}}
    {{- else -}}
      default-restricted-security-policy
    {{- end -}}
  {{- else -}}
    default-restricted-security-policy
  {{- end -}}
{{- end -}}

{{- define "eric-pm-server.securityPolicy.annotations" -}}
# Automatically generated annotations for documentation purposes.
{{- end -}}

{{/*
Define product-info
*/}}
{{- define "eric-pm-server.product-info" }}
  ericsson.com/product-name: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productName | quote }}
  ericsson.com/product-number: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productNumber | quote }}
  ericsson.com/product-revision: {{regexReplaceAll "(.*)[+].*" .Chart.Version "${1}" }}
{{- end }}

{{/*
Define annotations
*/}}
{{- define "eric-pm-server.annotations" -}}
  {{- $g := fromJson (include "eric-pm-server.global" .) -}}
  {{- $productInfo := include "eric-pm-server.product-info" . | fromYaml -}}
  {{- $global := $g.annotations -}}
  {{- $service := .Values.annotations -}}
  {{- include "eric-pm-server.mergeAnnotations" (dict "location" .Template.Name "sources" (list $productInfo $global $service)) | trim }}
{{- end -}}

{{/*
Logshipper annotations
*/}}
{{- define "eric-pm-server.logshipper-annotations" }}
{{- include "eric-pm-server.annotations" . -}}
{{- end }}

{{- define "eric-pm-server.imagePath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $image := (get $productInfo.images .imageName) -}}
    {{- $registryUrl := $image.registry -}}
    {{- $repoPath := $image.repoPath -}}
    {{- $name := $image.name -}}
    {{- $tag := $image.tag -}}
    {{- $g := fromJson (include "eric-pm-server.global" .) -}}
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
  Create eric-pm-server.serviceAccountName
*/}}
{{- define "eric-pm-server.serviceAccountName" -}}
{{- $g := fromJson (include "eric-pm-server.global" .) -}}
{{- if $g }}
  {{- $securityPolicyflags := include "eric-pm-server.securityPolicy" . | fromYaml -}}
  {{- $securityPolicyExists := get $securityPolicyflags "securityPolicyExists" -}}
  {{- $oldPolicyFlag := get $securityPolicyflags "oldPolicyFlag" -}}
  {{- if (eq "true" $securityPolicyExists) }}
    {{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
  {{- else  if .Values.rbac.appMonitoring.enabled }}
    {{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
  {{- else if .Values.server.serviceAccountName }}
    {{- print .Values.server.serviceAccountName }}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
Define eric-pm-server.resources
*/}}
{{- define "eric-pm-server.resources" -}}
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
Define eric-pm-server.appArmorProfileAnnotation
*/}}
{{- define "eric-pm-server.appArmorProfileAnnotation" -}}
{{- $acceptedProfiles := list "unconfined" "runtime/default" "localhost" }}
{{- $commonProfile := dict -}}
{{- if .Values.appArmorProfile.type -}}
  {{- $_ := set $commonProfile "type" .Values.appArmorProfile.type -}}
  {{- if and (eq .Values.appArmorProfile.type "localhost") .Values.appArmorProfile.localhostProfile -}}
    {{- $_ := set $commonProfile "localhostProfile" .Values.appArmorProfile.localhostProfile -}}
  {{- end -}}
{{- end -}}
{{- $profiles := dict -}}
{{- $containers := list "eric-pm-initcontainer" "eric-pm-server" "eric-pm-configmap-reload" "eric-pm-exporter" -}}
{{- if (eq "true" (include "eric-pm-server.logShipperEnabled" .)) }}
    {{- $containers = append $containers "logshipper" -}}
{{- end }}
{{- $g := fromJson (include "eric-pm-server.global" .) -}}
{{- if $g.security.tls.enabled }}
   {{- $containers = append $containers "eric-pm-reverseproxy" -}}
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
PM Server Labels for Network Policies
*/}}
{{- define "eric-pm-server.peer.labels" -}}
{{- if (eq "true" (include "eric-pm-server.logShipperEnabled" .)) }}
{{ .Values.logShipper.output.logTransformer.host }}-access: "true"
{{- end }}
{{- end -}}

{{/*
Define eric-pm-server.podSeccompProfile
*/}}
{{- define "eric-pm-server.podSeccompProfile" -}}
{{- if and .Values.seccompProfile .Values.seccompProfile.type }}
seccompProfile:
  type: {{ .Values.seccompProfile.type }}
  {{- if eq .Values.seccompProfile.type "Localhost" }}
  localhostProfile: {{ .Values.seccompProfile.localhostProfile }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Volume mount name used for Statefulset
*/}}
{{- define "eric-pm-server.persistence.volumeMount.name" -}}
  {{- printf "%s" "storage-volume" -}}
{{- end -}}

{{- define "eric-pm-server.reverseProxyVolume" }}
- name: cert
  secret:
    secretName: {{ template "eric-pm-server.name" . }}-cert
    optional: true
{{- if not .Values.service.endpoints.reverseproxy.tls.certificateAuthorityBackwardCompatibility }}
- name: pmqryca
  secret:
    secretName: {{ template "eric-pm-server.name" . }}-query-ca
    optional: true
{{- end }}
{{- end }}

{{/*
Generic value for updateStrategy
*/}}
{{- define "eric-pm-server.updateStrategy" -}}
type: {{ .type | quote }}
{{- if .rollingupdate }}
{{- if or .rollingUpdate.maxUnavailable .rollingUpdate.maxSurge }}
rollingUpdate:
{{- end }}
{{- if .rollingUpdate.maxUnavailable }}
  maxUnavailable: {{ .rollingUpdate.maxUnavailable }}
{{- end }}
{{- if .rollingUpdate.maxSurge }}
  maxSurge: {{ .rollingUpdate.maxSurge }}
{{- end }}
{{- end }}
{{- end }}


{{/*
Define podPriority check
*/}}
{{- define "eric-pm-server.podPriority" }}
{{- if index . "priorityClassName" }}
priorityClassName: {{ .priorityClassName | quote }}
{{- end }}
{{- end }}

{{/*
Define podAntiAffinity
*/}}
{{- define "eric-pm-server.podAntiAffinity" }}
{{- $top := index . 0 -}}
{{- $name := index . 1 -}}
{{- if eq $top.Values.affinity.podAntiAffinity "hard" -}}
affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
            - key: app
              operator: In
              values:
                - {{ $name }}
        topologyKey: {{ $top.Values.affinity.topologyKey | quote  }}
{{- else if eq $top.Values.affinity.podAntiAffinity  "soft" -}}
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
              - key: app
                operator: In
                values:
                  - {{ $name }}
          topologyKey: {{ $top.Values.affinity.topologyKey | quote }}
{{- end }}
{{- end }}

{{/*
Define pod tolerations
*/}}
{{- define "eric-pm-server.tolerations" }}
{{- if (include "eric-pm-server.merge-tolerations" (dict "root" . "podbasename" "eric-pm-server")) }}
tolerations:
{{- include "eric-pm-server.merge-tolerations" (dict "root" . "podbasename" "eric-pm-server") | nindent 2 }}
{{- end }}
{{- end }}
{{/*
Create imagePullPolicy
*/}}
{{- define "eric-pm-server.imagePullPolicy" -}}
    {{- $imagePullPolicy := .Values.imageCredentials.pullPolicy -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.imagePullPolicy -}}
                {{- $imagePullPolicy = .Values.global.registry.imagePullPolicy -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- print $imagePullPolicy -}}
{{- end -}}

{{/*
Handle prefixURL and baseURL values
*/}}
{{- define "eric-pm-server.prefix" -}}
  {{- $prefix := "" }}
  {{- if .Values.server.prefixURL -}}
    {{- $prefix = .Values.server.prefixURL -}}
  {{- else }}
    {{- if .Values.server.baseURL -}}
      {{- $baseURLDict := urlParse .Values.server.baseURL -}}
      {{- $prefix = get $baseURLDict "path" -}}
    {{- end -}}
  {{- end -}}
  {{- printf "%s" $prefix -}}
{{- end -}}

{{- define "eric-pm-server.securityPolicy.rolekind" -}}
{{- .Values.global.securityPolicy.rolekind -}}
{{- end -}}

{{- define "eric-pm-server.securityPolicy.rolename" -}}
{{- default "eric-pm-server" ( index .Values.securityPolicy "eric-pm-server" "rolename" ) -}}
{{- end -}}

{{/*
Function to check for DR-D1123-134 and DR-D1123-124
*/}}
{{- define "eric-pm-server.securityPolicy" -}}
{{- $securityPolicyExists := "false" -}}
{{- $oldPolicyFlag := "false" -}}
{{- $g := fromJson (include "eric-pm-server.global" .) -}}
{{- if $g -}}
  {{- if $g.securityPolicy -}}
    {{- if $g.securityPolicy.rolekind -}}
      {{- if and (ne .Values.global.securityPolicy.rolekind "Role") (ne .Values.global.securityPolicy.rolekind "ClusterRole") -}}
        {{- printf "For global.securityPolicy.rolekind is not set correctly." | fail -}}
      {{- end -}}
      {{- $securityPolicyExists = "true" -}}
    {{- else -}}
      {{- $securityPolicyExists = "false" -}}
    {{- end -}}
  {{- else if $g.security -}}
    {{- if $g.security.policyBinding -}}
      {{- if $g.security.policyBinding.create -}}
        {{- $securityPolicyExists = "true" -}}
        {{- $oldPolicyFlag = "true" -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- dict "securityPolicyExists" $securityPolicyExists "oldPolicyFlag" $oldPolicyFlag | toJson -}}
{{- end -}}

{{- define "eric-pm-server.securityPolicy.rolebinding.name" -}}
{{- if (eq "true" .oldPolicyFlag) }}
{{- print (include "eric-pm-server.name" .root ) "-security-policy" -}}
{{- else }}
{{- if (eq (include "eric-pm-server.securityPolicy.rolekind" .root) "Role") }}
{{- print (include "eric-pm-server.serviceAccountName" .root ) "-r-" (include "eric-pm-server.securityPolicy.rolename" .root ) "-sp" -}}
{{- else if (eq (include "eric-pm-server.securityPolicy.rolekind" .root) "ClusterRole") }}
{{- print (include "eric-pm-server.serviceAccountName" .root ) "-c-" (include "eric-pm-server.securityPolicy.rolename" .root ) "-sp" -}}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Adjust extraArgs to remove duplicated args
*/}}
{{- define "eric-pm-server.extraArgs" }}
  {{- $extraArgs := .root.Values.server.extraArgs -}}
  {{- $filteredArgs := .filteredArgs -}}
  {{- range $k1, $v1 := $extraArgs }}
    {{- range $k2 := $filteredArgs }}
      {{- if eq $k1 $k2 }}
        {{- $extraArgs = omit $extraArgs $k1 -}}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- $result := dict "dummy_key" $extraArgs }}
  {{- $result | toJson }}
{{- end }}

{{/*
Usage: {{template "eric-pm-server.configJobHeader" (list . "pod" "15s" "15s" "https")}}
*/}}
{{- define "eric-pm-server.configJobHeader" -}}
{{- $root := index . 0 -}}
{{- $role := index . 1 -}}
{{- $interval := index . 2 -}}
{{- $timeout := index . 3 -}}
{{- $scheme := index . 4 -}}
scrape_interval: {{ $interval }}
scrape_timeout: {{ $timeout }}
scheme: {{ $scheme }}
{{- if eq $scheme "https" }}
tls_config:
  ca_file: /run/secrets/cacert/cacertbundle.pem
  cert_file: /run/secrets/clicert/clicert.pem
  key_file: /run/secrets/clicert/cliprivkey.pem
  server_name: certified-scrape-target
  insecure_skip_verify: false
{{- end }}
kubernetes_sd_configs:
  - role: {{ $role }}
    namespaces:
      names:
        - {{ $root.Release.Namespace }}
{{- end }}

{{/*
Usage: {{template "eric-pm-server.ph2ConfigJobs" (list . "pod" "15s" "10s" "2" "https") }}
*/}}
{{- define "eric-pm-server.ph2JobRender" -}}
{{- $root := index . 0 -}}
{{- $role := index . 1 -}}
{{- $interval := index . 2 -}}
{{- $timeout := index . 3 -}}
{{- $pathIndex := index . 4 -}}
{{- $scheme := index . 5 -}}
{{- $kind := $role -}}
{{- if eq $role "endpoints" -}}
{{- $kind = "service" -}}
{{- end -}}
- job_name: k8s-{{ $role }}-{{ $interval }}-{{ $scheme }}{{- if gt $pathIndex 1 }}{{ printf "-%d" $pathIndex }}{{ end }}
{{ include "eric-pm-server.configJobHeader" (list $root $role $interval $timeout $scheme) | indent 2 }}
  relabel_configs:
    - source_labels:
        - __meta_kubernetes_{{ $kind }}_annotation_prometheus_io_scrape_interval{{ if gt $pathIndex 1 }}{{ $pathIndex }}{{ end }}
      action: keep
      regex: '^{{ $interval }}$'
    - source_labels:
        - __meta_kubernetes_{{ $kind }}_annotation_prometheus_io_scrape_role{{ if gt $pathIndex 1 }}{{ $pathIndex }}{{ end }}
      action: keep
      regex: '^{{ $role }}$'
    - source_labels:
        - __meta_kubernetes_{{ $kind }}_annotation_prometheus_io_path{{ if gt $pathIndex 1 }}{{ $pathIndex }}{{ end }}
      action: replace
      regex: (.+)
      target_label: __metrics_path__
    - source_labels:
  {{- if eq $role "pod" }}
        - __meta_kubernetes_pod_container_port_name
  {{- else if eq $role "service" }}
        - __meta_kubernetes_service_port_name
  {{- else }}
        - __meta_kubernetes_endpoint_port_name
  {{- end }}
        - __meta_kubernetes_{{ $kind }}_annotation_prometheus_io_scheme{{ if gt $pathIndex 1 }}{{ $pathIndex }}{{ end }}
      action: keep
      regex: ^(({{ $scheme }}-.*metrics.*;{{ $scheme }})|({{ $scheme }}-.*metrics.*;)|(.*;{{ $scheme }}))$
    - source_labels:
        - __address__
        - __meta_kubernetes_{{ $kind }}_annotation_prometheus_io_port{{ if ne $pathIndex 1 }}{{ $pathIndex }}{{ end }}
      action: replace
      regex: ((?:\[.+\])|(?:.+))(?::\d+);(\d+)
      replacement: $1:$2
      target_label: __address__
    - source_labels:
        - __meta_kubernetes_namespace
      action: replace
      target_label: namespace
    - source_labels:
      {{- if eq $role "pod" }}
        - __meta_kubernetes_pod_label_app_kubernetes_io_name
      {{- else }}
        - __meta_kubernetes_service_name
      {{- end }}
      action: replace
      target_label: service_name
{{- if ne $role "service" }}
    - source_labels:
        - __meta_kubernetes_pod_name
      action: replace
      target_label: pod_name
    - source_labels:
        - __meta_kubernetes_pod_phase
      regex: Pending|Succeeded|Failed|Completed
      action: drop
    - source_labels:
    {{- if eq $role "pod"}}
        - __meta_kubernetes_pod_annotation_prometheus_io_node_label
    {{- else }}
        - __meta_kubernetes_service_annotation_prometheus_io_node_label
    {{- end }}
        - __meta_kubernetes_pod_node_name
      regex: "true;(.*)"
      replacement: $1
      target_label: node_name
{{- end }}
{{- if $root.Values.scrapeConfig.jobs.deprecatedLabels.enabled }}
    - source_labels:
        - __meta_kubernetes_namespace
      action: replace
      target_label: kubernetes_namespace
  {{- if eq $role "pod"}}
    - source_labels:
        - __meta_kubernetes_pod_name
      action: replace
      target_label: kubernetes_pod_name
  {{- else }}
    - source_labels:
        - __meta_kubernetes_service_name
      action: replace
      target_label: kubernetes_name
  {{- end }}
{{- end }}
{{- end }}

{{/*
Usage: {{template "eric-pm-server.ph2ConfigJobs" (list . "pod" "15s" "10s" "2") }}
*/}}
{{- define "eric-pm-server.ph2ConfigJobs" -}}
{{- $root := index . 0 -}}
{{- $role := index . 1 -}}
{{- $interval := index . 2 -}}
{{- $timeout := index . 3 -}}
{{- $pathIndex := index . 4 -}}
{{- $kind := $role -}}
{{- if eq $role "endpoints" -}}
{{- $kind = "service" -}}
{{- end -}}
{{- $scheme := "http" -}}
{{- $g := fromJson (include "eric-pm-server.global" $root) -}}
{{- if $g.security.tls.enabled -}}
{{ include "eric-pm-server.ph2JobRender" (list $root $role $interval $timeout $pathIndex "https") }}
{{- end -}}
{{- if or (not $g.security.tls.enabled) ( and $g.security.tls.enabled ( eq $root.Values.service.endpoints.scrapeTargets.tls.enforced "optional")) }}
{{ include "eric-pm-server.ph2JobRender" (list $root $role $interval $timeout $pathIndex "http") }}
{{- end }}
{{- end }}

{{- define "eric-pm-server.prometheusAnnotations" }}
{{- $g := fromJson (include "eric-pm-server.global" .) -}}
{{- $portList := list 9090 9085 9087 }}
{{- if $g.security.tls.enabled }}
  {{- $portList = list 9090 9085 9087 9088 }}
{{- end }}
{{- $path := printf "%s/metrics" (include "eric-pm-server.prefix" . ) }}
{{- $id := "" }}
{{- range $index, $port := $portList }}
  {{- $at := $index | add 1 }}
  {{- if gt $at 1 }}
    {{- $id = $at }}
    {{- $path = "/metrics"}}
  {{- end }}
  prometheus.io/port{{ $id }}: {{ $port | quote }}
  prometheus.io/path{{ $id }}: {{ $path | quote }}
  prometheus.io/scrape-interval{{ $id }}: "15s"
  prometheus.io/scheme{{ $id }}: "http"
  prometheus.io/node-label{{ $id }}: "false"
{{- end }}
{{- end }}


{{- define "eric-pm-server.staticJobs" -}}
{{- $g := fromJson (include "eric-pm-server.global" .) -}}
- job_name: prometheus
  metrics_path: {{ template "eric-pm-server.prefix" . }}/metrics
  static_configs:
    - targets:
      - localhost:9090
- job_name: pm-configmap-reload
  static_configs:
    - targets:
      - localhost:9085
- job_name: pm-exporter
  static_configs:
    - targets:
      - localhost:9087
{{- if $g.security.tls.enabled }}
- job_name: pm-reverseproxy
  static_configs:
    - targets:
      - localhost:9088
{{- end }}
{{- end }}

{{- define "eric-pm-server.selfMonitoringJobs" -}}
{{- $g := fromJson (include "eric-pm-server.global" .) -}}
{{- if .Values.scrapeConfig.deprecatedJobs.selfMonitoring.enabled -}}
{{- template "eric-pm-server.staticJobs" . }}
{{- else -}}
- job_name: eric-pm-server
  scrape_interval: 15s
  scrape_timeout: 10s
  kubernetes_sd_configs:
    - role: pod
      namespaces:
        names:
          - {{ .Release.Namespace }}
  relabel_configs:
    - source_labels: [__meta_kubernetes_pod_label_app_kubernetes_io_name]
      regex: {{ template "eric-pm-server.name" .}}
      action: keep
    - source_labels: [__address__]
      regex: ".*:\\d+"
      action: keep
    - source_labels: [__meta_kubernetes_pod_container_port_name]
      regex: "http-metrics.*"
      action: keep
    - source_labels: [__meta_kubernetes_namespace]
      action: replace
      target_label: namespace
    - source_labels: [__meta_kubernetes_pod_label_app_kubernetes_io_name]
      action: replace
      target_label: service_name
    - source_labels: [__meta_kubernetes_pod_name]
      action: replace
      target_label: pod_name
    - source_labels: [__meta_kubernetes_pod_phase]
      regex: Pending|Succeeded|Failed|Completed
      action: drop
    - source_labels:
        - __meta_kubernetes_pod_annotation_prometheus_io_node_label
        - __meta_kubernetes_pod_node_name
      regex: "true;(.*)"
      replacement: $1
      target_label: node_name
{{- end }}
{{- if .Values.server.ha.enabled }}
- job_name: pm-promxy
  {{- if $g.security.tls.enabled }}
  scheme: https
  tls_config:
    ca_file: /run/secrets/cacert/cacertbundle.pem
    cert_file: /run/secrets/clicert/clicert.pem
    key_file: /run/secrets/clicert/cliprivkey.pem
    server_name: certified-scrape-target
  {{- end }}
  kubernetes_sd_configs:
    - role: pod
      namespaces:
        names:
          - {{ .Release.Namespace }}
  relabel_configs:
    - source_labels: [__meta_kubernetes_pod_label_app]
      action: keep
      regex: {{ template "eric-pm-server.promxyName" .}}
    - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
      action: keep
      regex: true
    - source_labels: [__meta_kubernetes_pod_container_port_name]
      action: keep
      regex: (.*-tls)
    - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path2]
      action: replace
      target_label: __metrics_path__
      regex: (.+)
    - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
      action: replace
      regex: ((?:\[.+\])|(?:.+))(?::\d+);(\d+)
      replacement: $1:$2
      target_label: __address__
    - action: labelmap
      regex: __meta_kubernetes_pod_label_(.+)
    - source_labels: [__meta_kubernetes_namespace]
      action: replace
      target_label: kubernetes_namespace
    - source_labels: [__meta_kubernetes_pod_name]
      action: replace
      target_label: kubernetes_pod_name
{{- end }}
{{- end }}

{{/*
List of legacy jobs (ph1)
*/}}
{{- define "eric-pm-server.legacyJobs" -}}
{{- $g := fromJson (include "eric-pm-server.global" .) -}}
{{- if $g.security.tls.enabled -}}
- job_name: tls-targets
  scheme: https
  tls_config:
    ca_file: /run/secrets/cacert/cacertbundle.pem
    cert_file: /run/secrets/clicert/clicert.pem
    key_file: /run/secrets/clicert/cliprivkey.pem
    server_name: certified-scrape-target
  kubernetes_sd_configs:
    - role: endpoints
      namespaces:
        names:
          - {{ .Release.Namespace }}
  relabel_configs:
    - source_labels: [__meta_kubernetes_service_name]
      action: replace
      target_label: job
    - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
      action: keep
      regex: true
    - source_labels: [__meta_kubernetes_endpoint_port_name]
      action: keep
      regex: (.*-tls)
    - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scheme]
      action: replace
      target_label: __scheme__
      regex: (https?)
    - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
      action: replace
      target_label: __metrics_path__
      regex: (.+)
    - source_labels: [__address__, __meta_kubernetes_service_annotation_prometheus_io_port]
      action: replace
      target_label: __address__
      regex: ((?:\[.+\])|(?:.+))(?::\d+);(\d+)
      replacement: $1:$2
    - action: labelmap
      regex: __meta_kubernetes_service_label_(.+)
    - source_labels: [__meta_kubernetes_namespace]
      action: replace
      target_label: kubernetes_namespace
    - source_labels: [__meta_kubernetes_service_name]
      action: replace
      target_label: kubernetes_name
- job_name: 'tls-pod-targets'
  scheme: https
  tls_config:
    ca_file: /run/secrets/cacert/cacertbundle.pem
    cert_file: /run/secrets/clicert/clicert.pem
    key_file: /run/secrets/clicert/cliprivkey.pem
    server_name: certified-scrape-target
  kubernetes_sd_configs:
    - role: pod
      namespaces:
        names:
          - {{ .Release.Namespace }}
  relabel_configs:
    - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
      action: keep
      regex: true
    - source_labels: [__meta_kubernetes_pod_container_port_name]
      action: keep
      regex: (.*-tls)
    - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
      action: replace
      target_label: __metrics_path__
      regex: (.+)
    - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
      action: replace
      regex: ((?:\[.+\])|(?:.+))(?::\d+);(\d+)
      replacement: $1:$2
      target_label: __address__
    - action: labelmap
      regex: __meta_kubernetes_pod_label_(.+)
    - source_labels: [__meta_kubernetes_namespace]
      action: replace
      target_label: kubernetes_namespace
    - source_labels: [__meta_kubernetes_pod_name]
      action: replace
      target_label: kubernetes_pod_name
    - source_labels: [__meta_kubernetes_pod_phase]
      action: drop
      regex: Pending|Succeeded|Failed
{{- end }}
{{- if or (not $g.security.tls.enabled) ( and $g.security.tls.enabled ( eq .Values.service.endpoints.scrapeTargets.tls.enforced "optional")) }}
- job_name: 'kubernetes-service-endpoints'
  kubernetes_sd_configs:
    - role: endpoints
      namespaces:
        names:
          - {{ .Release.Namespace }}
  relabel_configs:
    - source_labels: [__meta_kubernetes_service_name]
      action: replace
      target_label: job
    - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
      action: keep
      regex: true
    - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scheme]
      action: drop
      regex: https
    - source_labels: [__meta_kubernetes_endpoint_port_name]
      action: drop
      regex: (.*-tls)|(http-.*metrics.*)|(https-.*metrics.*)
    - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
      action: replace
      target_label: __metrics_path__
      regex: (.+)
    - source_labels: [__address__, __meta_kubernetes_service_annotation_prometheus_io_port]
      action: replace
      target_label: __address__
      regex: ((?:\[.+\])|(?:.+))(?::\d+);(\d+)
      replacement: $1:$2
    - action: labelmap
      regex: __meta_kubernetes_service_label_(.+)
    - source_labels: [__meta_kubernetes_namespace]
      action: replace
      target_label: kubernetes_namespace
    - source_labels: [__meta_kubernetes_service_name]
      action: replace
      target_label: kubernetes_name
- job_name: 'kubernetes-pods'
  kubernetes_sd_configs:
    - role: pod
      namespaces:
        names:
          - {{ .Release.Namespace }}
  relabel_configs:
    - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
      action: keep
      regex: true
    - source_labels: [__meta_kubernetes_pod_container_init]
      action: drop
      regex: true
    - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scheme]
      action: drop
      regex: https
    - source_labels: [__meta_kubernetes_endpoint_port_name]
      action: drop
      regex: (.*-tls)|(http-.*metrics.*)|(https-.*metrics.*)
    - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
      action: replace
      target_label: __metrics_path__
      regex: (.+)
    - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
      action: replace
      regex: ((?:\[.+\])|(?:.+))(?::\d+);(\d+)
      replacement: $1:$2
      target_label: __address__
    - action: labelmap
      regex: __meta_kubernetes_pod_label_(.+)
    - source_labels: [__meta_kubernetes_namespace]
      action: replace
      target_label: kubernetes_namespace
    - source_labels: [__meta_kubernetes_pod_name]
      action: replace
      target_label: kubernetes_pod_name
    - source_labels: [__meta_kubernetes_pod_phase]
      action: drop
      regex: Pending|Succeeded|Failed
{{- end }}
{{- end }}
