{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "eric-data-document-database-pg.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/* If .CapabilitiesKubeVersion.Version is smaller then 1.4.0, what should we do is TBD */}}
{{/*
Return the appropriate apiVersion for networkpolicy.
*/}}
{{- define "eric-data-document-database-pg.networkPolicy.apiVersion" -}}
{{- if and (semverCompare ">=1.4.0-0" .Capabilities.KubeVersion.Version) (semverCompare "<1.7.0-0" .Capabilities.KubeVersion.Version) -}}
"extensions/v1beta1"
{{- else if (semverCompare ">=1.7.0-0" .Capabilities.KubeVersion.Version) -}}
"networking.k8s.io/v1"
{{- end -}}
{{- end -}}


{{ define "eric-data-document-database-pg.global" }}
  {{- $globalDefaults := dict "registry" (dict "url" "armdocker.rnd.ericsson.se") -}}
  {{- $globalDefaults := merge $globalDefaults (dict "pullSecret") -}}
  {{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "url")) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "repoPath")) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "imagePullPolicy")) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "adpBR" (dict "broServiceName" "eric-ctrl-bro")) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "adpBR" (dict "broGrpcServicePort" "3000")) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "adpBR" (dict "brLabelKey" "adpbrlabelkey")) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "timezone" "UTC") -}}
  {{- $globalDefaults := merge $globalDefaults (dict "security" (dict "tls" (dict "enabled" true))) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "security" (dict "policyBinding" (dict "create" true))) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "security" (dict "policyReferenceMap")) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "securityPolicy" (dict "rolekind" "")) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "internalIPFamily") -}}
  {{- $globalDefaults := merge $globalDefaults (dict "fsGroup" (dict "manual")) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "fsGroup" (dict "namespace")) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "nodeSelector" (dict)) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "networkPolicy" (dict "enabled" false)) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "hooklauncher" (dict "executor" "service")) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "log" (dict "streamingMethod" "")) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "logShipper" (dict "deployment" (dict "model" ""))) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "logShipper" (dict "config" (dict "image" (dict "registry" "armdocker.rnd.ericsson.se")))) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "logShipper" (dict "config" (dict "image" (dict "repoPath" "proj-adp-log-released")))) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "imageCredentials" (dict "logshipper" (dict "registry" (dict "url" "")))) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "imageCredentials" (dict "logshipper" (dict "repoPath" ""))) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "documentDatabasePG" (dict "operator" (dict "enabled" false))) -}}
  {{ if .Values.global }}
    {{- mergeOverwrite $globalDefaults .Values.global | toJson -}}
  {{ else }}
    {{- $globalDefaults | toJson -}}
  {{ end }}
{{ end }}

{{- define "eric-data-document-database-pg.logRedirect" -}}
{{- $g := fromJson (include "eric-data-document-database-pg.global" .) -}}
{{- if .Values.log.streamingMethod -}}
    {{- if (eq "dual" (.Values.log.streamingMethod | toString))  }}
        {{- "all" -}}
    {{- else if (eq "direct" (.Values.log.streamingMethod | toString))  }}
        {{- "file" -}}
    {{- else -}}
        {{- "stdout" -}}
    {{- end -}}
{{- else if ($g.log.streamingMethod) -}}
    {{- if (eq "dual" ($g.log.streamingMethod | toString))  }}
        {{- "all" -}}
    {{- else if (eq "direct" ($g.log.streamingMethod | toString))  }}
        {{- "file" -}}
    {{- else -}}
        {{- "stdout" -}}
    {{- end -}}
{{- else if and (has "stream" .Values.log.outputs) (has "stdout" .Values.log.outputs) -}}
    {{- "all" -}}
{{- else if (has "stream" .Values.log.outputs) -}}
    {{- "file" -}}
{{- else -}}
    {{- "stdout" -}}
{{- end -}}
{{- end -}}

{{- define "eric-data-document-database-pg.stdRedirectCMD" -}}
{{ "/usr/local/bin/pipe_fifo.sh "  }}
{{- end -}}


{{/*
Return the mountpath using in the container's volume.
*/}}
{{- define "eric-data-document-database-pg.mountPath" -}}
{{- "/var/lib/postgresql/data" -}}
{{- end -}}

{{/*
Return the mountpath for postgres config dir.
*/}}
{{- define "eric-data-document-database-pg.configPath" -}}
{{- "/var/lib/postgresql/config" -}}
{{- end -}}

{{/*
Return the mountpath for postgres script dir.
*/}}
{{- define "eric-data-document-database-pg.scriptPath" -}}
{{- "/var/lib/postgresql/scripts" -}}
{{- end -}}

{{/*
Return the mountpath for hook script dir.
*/}}
{{- define "eric-data-document-database-pg.hook.scriptPath" -}}
{{- "/var/lib/scripts" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "eric-data-document-database-pg.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create image registry url
*/}}
{{- define "eric-data-document-database-pg.registryUrl" -}}
{{- $g := fromJson (include "eric-data-document-database-pg.global" .) -}}
{{- if .Values.imageCredentials.registry.url -}}
{{- print .Values.imageCredentials.registry.url -}}
{{- else -}}
{{- print $g.registry.url -}}
{{- end -}}
{{- end -}}

{{/*
Create log streamingMethod
*/}}
{{- define "eric-data-document-database-pg.log.streamingMethod" -}}
{{- $logRedirect := (include "eric-data-document-database-pg.logRedirect" .) -}}
{{- if or (eq $logRedirect "all") (eq $logRedirect "file") }}
    {{- "true" -}}
{{- else -}}
    {{- "false" -}}
{{- end }}
{{- end -}}

{{/*
The pg13Image path
*/}}
{{- define "eric-data-document-database-pg.pg13ImagePath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := $productInfo.images.pg13.registry -}}
    {{- $repoPath := $productInfo.images.pg13.repoPath -}}
    {{- $name := $productInfo.images.pg13.name -}}
    {{- $tag := $productInfo.images.pg13.tag -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.url -}}
                {{- $registryUrl = .Values.global.registry.url -}}
            {{- end -}}
            {{- if not (kindIs "invalid" .Values.global.registry.repoPath) -}}
                {{- $repoPath = .Values.global.registry.repoPath -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
        {{- if .Values.imageCredentials.registry -}}
            {{- if .Values.imageCredentials.registry.url -}}
                {{- $registryUrl = .Values.imageCredentials.registry.url -}}
            {{- end -}}
        {{- end -}}
        {{- if not (kindIs "invalid" .Values.imageCredentials.repoPath) -}}
            {{- $repoPath = .Values.imageCredentials.repoPath -}}
        {{- end -}}
        {{- if .Values.imageCredentials.pg13 -}}
            {{- if not (kindIs "invalid" .Values.imageCredentials.pg13.repoPath) -}}
                {{- $repoPath = .Values.imageCredentials.pg13.repoPath -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.images -}}
        {{- if .Values.images.postgres -}}
            {{- if .Values.images.postgres.name -}}
                {{- $name = .Values.images.postgres.name -}}
            {{- end -}}
            {{- if .Values.images.postgres.tag -}}
                {{- $tag = .Values.images.postgres.tag -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if $repoPath -}}
        {{- $repoPath = printf "%s/" $repoPath -}}
    {{- end -}}
    {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}

{{/*
The metricsImage path
*/}}
{{- define "eric-data-document-database-pg.metricsImagePath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := $productInfo.images.metrics.registry -}}
    {{- $repoPath := $productInfo.images.metrics.repoPath -}}
    {{- $name := $productInfo.images.metrics.name -}}
    {{- $tag := $productInfo.images.metrics.tag -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.url -}}
                {{- $registryUrl = .Values.global.registry.url -}}
            {{- end -}}
            {{- if not (kindIs "invalid" .Values.global.registry.repoPath) -}}
                {{- $repoPath = .Values.global.registry.repoPath -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
        {{- if .Values.imageCredentials.registry -}}
            {{- if .Values.imageCredentials.registry.url -}}
                {{- $registryUrl = .Values.imageCredentials.registry.url -}}
            {{- end -}}
        {{- end -}}
        {{- if not (kindIs "invalid" .Values.imageCredentials.repoPath) -}}
            {{- $repoPath = .Values.imageCredentials.repoPath -}}
        {{- end -}}
        {{- if .Values.imageCredentials.metrics -}}
            {{- if not (kindIs "invalid" .Values.imageCredentials.metrics.repoPath) -}}
                {{- $repoPath = .Values.imageCredentials.metrics.repoPath -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.images -}}
        {{- if .Values.images.metrics -}}
            {{- if .Values.images.metrics.name -}}
                {{- $name = .Values.images.metrics.name -}}
            {{- end -}}
            {{- if .Values.images.metrics.tag -}}
                {{- $tag = .Values.images.metrics.tag -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if $repoPath -}}
        {{- $repoPath = printf "%s/" $repoPath -}}
    {{- end -}}
    {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}

{{/*
The kubeclientImage path
*/}}
{{- define "eric-data-document-database-pg.kubeclientImagePath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := $productInfo.images.kubeclient.registry -}}
    {{- $repoPath := $productInfo.images.kubeclient.repoPath -}}
    {{- $name := $productInfo.images.kubeclient.name -}}
    {{- $tag := $productInfo.images.kubeclient.tag -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.url -}}
                {{- $registryUrl = .Values.global.registry.url -}}
            {{- end -}}
            {{- if not (kindIs "invalid" .Values.global.registry.repoPath) -}}
                {{- $repoPath = .Values.global.registry.repoPath -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
        {{- if .Values.imageCredentials.registry -}}
            {{- if .Values.imageCredentials.registry.url -}}
                {{- $registryUrl = .Values.imageCredentials.registry.url -}}
            {{- end -}}
        {{- end -}}
        {{- if not (kindIs "invalid" .Values.imageCredentials.repoPath) -}}
            {{- $repoPath = .Values.imageCredentials.repoPath -}}
        {{- end -}}
        {{- if .Values.imageCredentials.kubeclient -}}
            {{- if not (kindIs "invalid" .Values.imageCredentials.kubeclient.repoPath) -}}
                {{- $repoPath = .Values.imageCredentials.kubeclient.repoPath -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.images -}}
        {{- if (index .Values "images" "kube-client") -}}
            {{- if (index .Values "images" "kube-client" "name") -}}
                {{- $name = index .Values "images" "kube-client" "name" -}}
            {{- end -}}
            {{- if (index .Values "images" "kube-client" "tag") -}}
                {{- $tag = index .Values "images" "kube-client" "tag" -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if $repoPath -}}
        {{- $repoPath = printf "%s/" $repoPath -}}
    {{- end -}}
    {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}

{{/*
The braImage path
*/}}
{{- define "eric-data-document-database-pg.braImagePath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := $productInfo.images.bra.registry -}}
    {{- $repoPath := $productInfo.images.bra.repoPath -}}
    {{- $name := $productInfo.images.bra.name -}}
    {{- $tag := $productInfo.images.bra.tag -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.url -}}
                {{- $registryUrl = .Values.global.registry.url -}}
            {{- end -}}
            {{- if not (kindIs "invalid" .Values.global.registry.repoPath) -}}
                {{- $repoPath = .Values.global.registry.repoPath -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
        {{- if .Values.imageCredentials.registry -}}
            {{- if .Values.imageCredentials.registry.url -}}
                {{- $registryUrl = .Values.imageCredentials.registry.url -}}
            {{- end -}}
        {{- end -}}
        {{- if not (kindIs "invalid" .Values.imageCredentials.repoPath) -}}
            {{- $repoPath = .Values.imageCredentials.repoPath -}}
        {{- end -}}
        {{- if .Values.imageCredentials.bra -}}
            {{- if not (kindIs "invalid" .Values.imageCredentials.bra.repoPath) -}}
                {{- $repoPath = .Values.imageCredentials.bra.repoPath -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.images -}}
        {{- if .Values.images.bra -}}
            {{- if .Values.images.bra.name -}}
                {{- $name = .Values.images.bra.name -}}
            {{- end -}}
            {{- if .Values.images.bra.tag -}}
                {{- $tag = .Values.images.bra.tag -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if $repoPath -}}
        {{- $repoPath = printf "%s/" $repoPath -}}
    {{- end -}}
    {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}

{{/*
The brmImage path
*/}}
{{- define "eric-data-document-database-pg.brmImagePath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := $productInfo.images.brm.registry -}}
    {{- $repoPath := $productInfo.images.brm.repoPath -}}
    {{- $name := $productInfo.images.brm.name -}}
    {{- $tag := $productInfo.images.brm.tag -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.url -}}
                {{- $registryUrl = .Values.global.registry.url -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
        {{- if .Values.imageCredentials.registry -}}
            {{- if .Values.imageCredentials.registry.url -}}
                {{- $registryUrl = .Values.imageCredentials.registry.url -}}
            {{- end -}}
        {{- end -}}
        {{- if not (kindIs "invalid" .Values.imageCredentials.repoPath) -}}
            {{- $repoPath = .Values.imageCredentials.repoPath -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.images -}}
        {{- if .Values.images.brm -}}
            {{- if .Values.images.brm.name -}}
                {{- $name = .Values.images.brm.name -}}
            {{- end -}}
            {{- if .Values.images.brm.tag -}}
                {{- $tag = .Values.images.brm.tag -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if $repoPath -}}
        {{- $repoPath = printf "%s/" $repoPath -}}
    {{- end -}}
    {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}

{{/*
The brm13Image path
*/}}
{{- define "eric-data-document-database-pg.brm13ImagePath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := $productInfo.images.brm13.registry -}}
    {{- $repoPath := $productInfo.images.brm13.repoPath -}}
    {{- $name := $productInfo.images.brm13.name -}}
    {{- $tag := $productInfo.images.brm13.tag -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.url -}}
                {{- $registryUrl = .Values.global.registry.url -}}
            {{- end -}}
            {{- if not (kindIs "invalid" .Values.global.registry.repoPath) -}}
                {{- $repoPath = .Values.global.registry.repoPath -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
        {{- if .Values.imageCredentials.registry -}}
            {{- if .Values.imageCredentials.registry.url -}}
                {{- $registryUrl = .Values.imageCredentials.registry.url -}}
            {{- end -}}
        {{- end -}}
        {{- if not (kindIs "invalid" .Values.imageCredentials.repoPath) -}}
            {{- $repoPath = .Values.imageCredentials.repoPath -}}
        {{- end -}}
        {{- if .Values.imageCredentials.brm13 -}}
            {{- if not (kindIs "invalid" .Values.imageCredentials.brm13.repoPath) -}}
                {{- $repoPath = .Values.imageCredentials.brm13.repoPath -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.images -}}
        {{- if .Values.images.brm -}}
            {{- if .Values.images.brm.name -}}
                {{- $name = .Values.images.brm.name -}}
            {{- end -}}
            {{- if .Values.images.brm.tag -}}
                {{- $tag = .Values.images.brm.tag -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if $repoPath -}}
        {{- $repoPath = printf "%s/" $repoPath -}}
    {{- end -}}
    {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}

{{/*
The fe operator Image path
*/}}
{{- define "eric-data-document-database-pg.feImagePath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := $productInfo.images.feoperator.registry -}}
    {{- $repoPath := $productInfo.images.feoperator.repoPath -}}
    {{- $name := $productInfo.images.feoperator.name -}}
    {{- $tag := $productInfo.images.feoperator.tag -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.url -}}
                {{- $registryUrl = .Values.global.registry.url -}}
            {{- end -}}
            {{- if not (kindIs "invalid" .Values.global.registry.repoPath) -}}
                {{- $repoPath = .Values.global.registry.repoPath -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
        {{- if .Values.imageCredentials.registry -}}
            {{- if .Values.imageCredentials.registry.url -}}
                {{- $registryUrl = .Values.imageCredentials.registry.url -}}
            {{- end -}}
        {{- end -}}
        {{- if not (kindIs "invalid" .Values.imageCredentials.repoPath) -}}
            {{- $repoPath = .Values.imageCredentials.repoPath -}}
        {{- end -}}
        {{- if .Values.imageCredentials.feoperator -}}
            {{- if not (kindIs "invalid" .Values.imageCredentials.feoperator.repoPath) -}}
                {{- $repoPath = .Values.imageCredentials.feoperator.repoPath -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.images -}}
        {{- if .Values.images.feoperator -}}
            {{- if .Values.images.feoperator.name -}}
                {{- $name = .Values.images.feoperator.name -}}
            {{- end -}}
            {{- if .Values.images.feoperator.tag -}}
                {{- $tag = .Values.images.feoperator.tag -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if $repoPath -}}
        {{- $repoPath = printf "%s/" $repoPath -}}
    {{- end -}}
    {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}


{{/*
The be operator Image path
*/}}
{{- define "eric-data-document-database-pg.beImagePath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := $productInfo.images.beoperator.registry -}}
    {{- $repoPath := $productInfo.images.beoperator.repoPath -}}
    {{- $name := $productInfo.images.beoperator.name -}}
    {{- $tag := $productInfo.images.beoperator.tag -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.url -}}
                {{- $registryUrl = .Values.global.registry.url -}}
            {{- end -}}
            {{- if not (kindIs "invalid" .Values.global.registry.repoPath) -}}
                {{- $repoPath = .Values.global.registry.repoPath -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
        {{- if .Values.imageCredentials.registry -}}
            {{- if .Values.imageCredentials.registry.url -}}
                {{- $registryUrl = .Values.imageCredentials.registry.url -}}
            {{- end -}}
        {{- end -}}
        {{- if not (kindIs "invalid" .Values.imageCredentials.repoPath) -}}
            {{- $repoPath = .Values.imageCredentials.repoPath -}}
        {{- end -}}
        {{- if .Values.imageCredentials.beoperator -}}
            {{- if not (kindIs "invalid" .Values.imageCredentials.beoperator.repoPath) -}}
                {{- $repoPath = .Values.imageCredentials.beoperator.repoPath -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.images -}}
        {{- if .Values.images.beoperator -}}
            {{- if .Values.images.beoperator.name -}}
                {{- $name = .Values.images.beoperator.name -}}
            {{- end -}}
            {{- if .Values.images.beoperator.tag -}}
                {{- $tag = .Values.images.beoperator.tag -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if $repoPath -}}
        {{- $repoPath = printf "%s/" $repoPath -}}
    {{- end -}}
    {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}


{{/*
Create image repoPath
*/}}
{{- define "eric-data-document-database-pg.repoPath" -}}
{{- if .Values.imageCredentials.repoPath -}}
{{- print "/" .Values.imageCredentials.repoPath "/" -}}
{{- else -}}
{{- print "/" -}}
{{- end -}}
{{- end -}}

{{/*
Create image pull secrets
*/}}
{{- define "eric-data-document-database-pg.pullSecrets" -}}
{{- $g := fromJson (include "eric-data-document-database-pg.global" .) -}}
{{- if .Values.imageCredentials.pullSecret -}}
{{- print .Values.imageCredentials.pullSecret -}}
{{- else if $g.pullSecret -}}
{{- print $g.pullSecret -}}
{{- end -}}
{{- end -}}

{{/*
Create image pull policy
*/}}
{{- define "eric-data-document-database-pg.imagePullPolicy" -}}
{{- $g := fromJson (include "eric-data-document-database-pg.global" .) -}}
{{- if .Values.imageCredentials.registry.imagePullPolicy -}}
{{- print .Values.imageCredentials.registry.imagePullPolicy -}}
{{- else if $g.registry.imagePullPolicy -}}
{{- print $g.registry.imagePullPolicy -}}
{{- else -}}
{{- print "IfNotPresent" -}}
{{- end -}}
{{- end -}}

{{/*
Transit pvc mount path
*/}}
{{- define "eric-data-document-database-pg.transit.mountpath" -}}
{{- "/shipment_data" -}}
{{- end -}}

{{/*
Expand the component of transit pvc.
*/}}
{{- define "eric-data-document-database-pg.transit.component" -}}
{{- "eric-data-document-database-pg-transit" -}}
{{- end -}}

{{/*
Define the default storage class name.
*/}}
{{- define "eric-data-document-database-pg.persistentVolumeClaim.defaultStorageClassName" -}}
{{- if .Values.persistentVolumeClaim.storageClassName}}
{{- print .Values.persistentVolumeClaim.storageClassName -}}
{{- else }}
{{- "" -}}
{{- end }}
{{- end -}}

{{/*
Define the default backup storage class name.
*/}}
{{- define "eric-data-document-database-pg.backup.defaultStorageClassName" -}}
{{- if .Values.persistence.backup.storageClassName }}
{{- if (eq "-" .Values.persistence.backup.storageClassName) }}
{{- "" -}}
{{- else }}
{{- print .Values.persistence.backup.storageClassName -}}
{{- end }}
{{- else }}
{{- "erikube-rbd" -}}
{{- end }}
{{- end -}}

{{/*
Define the persistentVolumeClaim size
*/}}
{{- define "eric-data-document-database-pg.persistentVolumeClaim.size" -}}
{{- if .Values.persistentVolumeClaim.size}}
{{- print .Values.persistentVolumeClaim.size }}
{{- end }}
{{- end -}}

{{/*
Create Ericsson product specific annotations
*/}}
{{- define "eric-data-document-database-pg.helm-annotations_product_name" -}}
{{- $productname := (fromYaml (.Files.Get "eric-product-info.yaml")).productName -}}
{{- print $productname | quote }}
{{- end -}}
{{- define "eric-data-document-database-pg.helm-annotations_product_number" -}}
{{- $productNumber := (fromYaml (.Files.Get "eric-product-info.yaml")).productNumber -}}
{{- print $productNumber | quote }}
{{- end -}}
{{- define "eric-data-document-database-pg.helm-annotations_product_revision" -}}
{{- $ddbMajorVersion := mustRegexFind "^([0-9]+)\\.([0-9]+)\\.([0-9]+)((-|\\+)EP[0-9]+)*((-|\\+)[0-9]+)*" .Chart.Version -}}
{{- print $ddbMajorVersion | quote }}
{{- end -}}

{/*
DR-D1123-128 seccomp profile
*/}}
{{- define "eric-data-document-database-pg.seccompProfile" -}}
{{- $containers := list "postgres" "hook-cleanup" "hook-cleanjob" "bra" "brm" "backup-pgdata" "restore-pgdata" "metrics" "feoperator" "beoperator" "op-patch-hook" "shh-hook" "preup-cmupdate" "prero-cmupdate" "postdel-cleanup" -}}
{{- if .Values.seccompProfile -}}
{{- if eq .Scope "Pod" -}}
{{- if .Values.seccompProfile.type -}}
seccompProfile:
  type: {{ .Values.seccompProfile.type }}
  {{- if eq .Values.seccompProfile.type "Localhost" }}
  {{- if not .Values.seccompProfile.localhostProfile }}
  {{- fail "localhostProfile for seccompProfile must be spcified" }}
  {{- end }}
  localhostProfile: {{ .Values.seccompProfile.localhostProfile }}
  {{- end -}}
{{- end -}}
{{- else if and (has .Scope $containers) (hasKey .Values.seccompProfile .Scope) -}}
{{- $container_setting := (get .Values.seccompProfile .Scope) -}}
{{- if $container_setting.type -}}
seccompProfile:
  type: {{ $container_setting.type }}
  {{- if eq $container_setting.type "Localhost" }}
  {{- if not $container_setting.localhostProfile }}
  {{- fail "localhostProfile for seccompProfile must be spcified" }}
  {{- end }}
  localhostProfile: {{ $container_setting.localhostProfile }}
  {{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart version as used by the chart label.
*/}}
{{- define "eric-data-document-database-pg.version" -}}
{{- printf "%s" .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
DR-D1123-127 appArmor profile
*/}}
{{- define "eric-data-document-database-pg.appArmorProfile" -}}
{{- $containers := .containerList -}}
{{- $rawNameContainers := list "hook-cleanup" "hook-cleanjob" "backup-pgdata" "restore-pgdata" "logshipper" "op-patch-hook" "shh-hook" "preup-cmupdate" "prero-cmupdate" "postdel-cleanup" -}}

{{- if eq .Scope "BRAgent" -}}
{{- if (eq (include "eric-data-document-database-pg.log.streamingMethod" $.root) "true") }}
{{ $containers = append $containers "logshipper" }}
{{- end -}}
{{- end -}}

{{- if eq .Scope "STS" -}}
{{- if $.root.Values.metrics.enabled }}
{{ $containers = append $containers "metrics" }}
{{- end -}}
{{- if (eq (include "eric-data-document-database-pg.log.streamingMethod" $.root) "true") }}
{{ $containers = append $containers "logshipper" }}
{{- end -}}
{{- end -}}

{{- if eq .Scope "Hook" -}}
{{- if (eq (include "eric-data-document-database-pg.log.streamingMethod" $.root) "true") }}
{{- if not (eq ((((($.root.Values).global).logShipper).config).hookEnabled | toString) "false") -}}
{{ $containers = append $containers "logshipper" }}
{{- end -}}
{{- end -}}
{{- end -}}

{{- if eq .Scope "CleanupHook" -}}
{{- if ($.root.Release.IsUpgrade) }}
{{- if (eq (include "eric-data-document-database-pg.log.streamingMethod" $.root) "true") }}
{{- if not (eq ((((($.root.Values).global).logShipper).config).hookEnabled | toString) "false") -}}
{{ $containers = append $containers "logshipper" }}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- if eq .Scope "FeOperator" -}}
{{- if (eq (include "eric-data-document-database-pg.log.streamingMethod" $.root) "true") }}
{{ $containers = append $containers "logshipper" }}
{{- end -}}
{{- end -}}

{{- if eq .Scope "BeOperator" -}}
{{- if (eq (include "eric-data-document-database-pg.log.streamingMethod" $.root) "true") }}
{{ $containers = append $containers "logshipper" }}
{{- end -}}
{{- end -}}


{{- range $name := $containers -}}
{{- if $.root.Values.appArmorProfile -}}
    {{- if $.root.Values.appArmorProfile.type -}}
        {{- if and (eq $.root.Values.appArmorProfile.type "localhost") (not $.root.Values.appArmorProfile.localhostProfile) }}
        {{- fail "localhostProfile for appArmorProfile must be spcified" }}
        {{- end }}
{{- if eq $name "postgres" }}
{{- if (eq (include "eric-data-document-database-pg.operator-enabled" $.root) "true") }}
container.apparmor.security.beta.kubernetes.io/postgres: {{ if eq $.root.Values.appArmorProfile.type "localhost" }} localhost/{{ $.root.Values.appArmorProfile.localhostProfile }} {{ else }} {{ $.root.Values.appArmorProfile.type }} {{ end }}
{{- else }}
container.apparmor.security.beta.kubernetes.io/{{ template "eric-data-document-database-pg.name" $.root }}: {{ if eq $.root.Values.appArmorProfile.type "localhost" }} localhost/{{ $.root.Values.appArmorProfile.localhostProfile }} {{ else }} {{ $.root.Values.appArmorProfile.type }} {{ end }}
{{- end -}}
{{- else if has $name $rawNameContainers }}
container.apparmor.security.beta.kubernetes.io/{{ $name }}: {{ if eq $.root.Values.appArmorProfile.type "localhost" }} localhost/{{ $.root.Values.appArmorProfile.localhostProfile }} {{ else }} {{ $.root.Values.appArmorProfile.type }} {{ end }}
{{- else }}
container.apparmor.security.beta.kubernetes.io/{{ template "eric-data-document-database-pg.name" $.root }}-{{ $name }}: {{ if eq $.root.Values.appArmorProfile.type "localhost" }} localhost/{{ $.root.Values.appArmorProfile.localhostProfile }} {{ else }} {{ $.root.Values.appArmorProfile.type }} {{ end }}
{{- end }}
{{ $containers = without $containers $name }}
    {{- end -}}
{{- end -}}
{{- end -}}

{{- range $name := $containers -}}
{{- if $.root.Values.appArmorProfile -}}
    {{- if hasKey $.root.Values.appArmorProfile $name -}}
        {{- $container_setting := (get $.root.Values.appArmorProfile $name) -}}
        {{- if $container_setting.type -}}
            {{- if and (eq $container_setting.type "localhost") (not $container_setting.localhostProfile) }}
            {{- fail "localhostProfile for appArmorProfile must be spcified" }}
            {{- end }}
{{- if eq $name "postgres" }}
{{- if (eq (include "eric-data-document-database-pg.operator-enabled" $.root) "true") }}
container.apparmor.security.beta.kubernetes.io/postgres: {{ if eq $container_setting.type "localhost" }} localhost/{{ $container_setting.localhostProfile }} {{ else }} {{ $container_setting.type }} {{ end }}
{{- else }}
container.apparmor.security.beta.kubernetes.io/{{ template "eric-data-document-database-pg.name" $.root }}: {{ if eq $container_setting.type "localhost" }} localhost/{{ $container_setting.localhostProfile }} {{ else }} {{ $container_setting.type }} {{ end }}
{{- end -}}
{{- else if has $name $rawNameContainers }}
container.apparmor.security.beta.kubernetes.io/{{ $name }}: {{ if eq $container_setting.type "localhost" }} localhost/{{ $container_setting.localhostProfile }} {{ else }} {{ $container_setting.type }} {{ end }}
{{- else }}
container.apparmor.security.beta.kubernetes.io/{{ template "eric-data-document-database-pg.name" $.root }}-{{ $name }}: {{ if eq $container_setting.type "localhost" }} localhost/{{ $container_setting.localhostProfile }} {{ else }} {{ $container_setting.type }} {{ end }}
{{- end }}
    {{- end -}}
    {{- end -}}
{{- end -}}
{{- end -}}


{{- end -}}


{/*
DR-D1126-010 JVM heap size 
*/}}
{{- define "eric-data-document-database-pg.JVMHeapSize" -}}
    {{- $maxRAM := "" -}}
    {{- $minRAM := "" -}}
    {{- $initRAM := "" -}}
    {{- if not .Values.resources.bra.limits.memory -}}
    {{- fail "memory limit for bra is not specified" -}}
    {{- end -}}
    {{- if .Values.resources.bra.jvm -}}
        {{- if .Values.resources.bra.jvm.initialMemoryAllocationPercentage -}}
            {{- $initRAM = .Values.resources.bra.jvm.initialMemoryAllocationPercentage | toString | replace "%" "" | float64 -}}
            {{- $initRAM = printf "-XX:InitialRAMPercentage=%f" $initRAM -}}
        {{- end -}}
        {{- if .Values.resources.bra.jvm.smallMemoryAllocationMaxPercentage -}}
            {{- $minRAM = .Values.resources.bra.jvm.smallMemoryAllocationMaxPercentage | toString | replace "%" "" | float64 -}}
            {{- $minRAM = printf "-XX:MinRAMPercentage=%f" $minRAM -}}
        {{- end -}}
        {{- if .Values.resources.bra.jvm.largeMemoryAllocationMaxPercentage -}}
            {{- $maxRAM = .Values.resources.bra.jvm.largeMemoryAllocationMaxPercentage | toString | replace "%" "" | float64 -}}
            {{- $maxRAM = printf "-XX:MaxRAMPercentage=%f" $maxRAM -}}
        {{- end -}}
    {{- end -}}
{{- printf "%s %s %s" $initRAM $minRAM $maxRAM -}}
{{- end -}}


{{/*
Define the secret that sip-tls produced
*/}}
{{- define "eric-data-document-database-pg.secretBaseName" -}}
{{- if .Values.nameOverride }}
{{- printf "%s" .Values.nameOverride -}}
{{- else }}
{{- printf "%s" .Chart.Name -}}
{{- end }}
{{- end -}}
{{/*
Define the mount path of brm-config 
*/}}
{{- define "eric-data-document-database-pg.br-configmap-path" -}}
{{- if .Values.brAgent.brmConfigmapPath -}}
{{- print .Values.brAgent.brmConfigmapPath -}}
{{- else }}
{{- print "/opt/brm_backup" -}}
{{- end }}
{{- end -}}

{{/*
Define the backupType based on backupTypeList.
*/}}
{{- define "eric-data-document-database-pg.br-backuptypes" }}
{{- .Values.brAgent.backupTypeList | join ";" -}}
{{- end -}}

{{/*
Label for deployment-bragent.
*/}}
{{- define "eric-data-document-database-pg.br-labelkey" -}}
{{- $globalValue := fromJson (include "eric-data-document-database-pg.global" .) -}}
{{ if .Values.brAgent }}
  {{ if eq .Values.brAgent.enabled true }}
    {{ if $globalValue.adpBR.brLabelKey }}
      {{ $globalValue.adpBR.brLabelKey }}: {{ .Values.brAgent.brLabelValue | default .Chart.Name | quote }}
    {{ end }}
  {{ end }}
{{ end }}
{{- end -}}

{{/*
check global.security.tls.enabled since it is removed from values.yaml 
*/}}
{{- define "eric-data-document-database-pg.global-security-tls-enabled" -}}
  {{- $g := fromJson (include "eric-data-document-database-pg.global" .) -}}
  {{- if $g.security.tls -}}
    {{- $g.security.tls.enabled | toString -}}
  {{- else -}}
    {{- "true" -}}
  {{- end -}}
{{- end -}}

{{/*
check if postgresConfig.huge_pages is configured for ADPPRG-32783
*/}}
{{- define "eric-data-document-database-pg.hugepage-configured" -}}
{{- if  .Values.postgresConfig -}}
  {{- if  .Values.postgresConfig.huge_pages -}}
       {{- "true" -}}
  {{- else -}}
       {{- "false" -}}
  {{- end -}}
{{- else -}}
{{- "false" -}}
{{- end -}}
{{- end -}}

{{/*
Return the topologyKey
*/}}
{{- define "eric-data-document-database-pg.topologyKey" -}}
{{- if or (not .Values.affinity.topologyKey) (eq "" (.Values.affinity.topologyKey | toString)) }}
    {{- "kubernetes.io/hostname" -}}
{{- else }}
    {{- .Values.affinity.topologyKey -}}
{{- end }}
{{- end -}}

{{/*
Define affinity property in ddb
*/}}
{{- define "eric-data-document-database-pg.affinity" -}}
{{- if eq .Values.affinity.podAntiAffinity "hard" -}}
podAntiAffinity:
  requiredDuringSchedulingIgnoredDuringExecution:
  - labelSelector:
      matchExpressions:
      - key: app
        operator: In
        values:
        - {{ template "eric-data-document-database-pg.name" . }}
    topologyKey: {{ template "eric-data-document-database-pg.topologyKey" . }}
{{- else if eq .Values.affinity.podAntiAffinity "soft" -}}
podAntiAffinity:
  preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 100
    podAffinityTerm:
      labelSelector:
        matchExpressions:
        - key: app
          operator: In
          values:
          - {{ template "eric-data-document-database-pg.name" . }}
      topologyKey: {{ template "eric-data-document-database-pg.topologyKey" . }}
{{- end -}}
{{- end -}}

{{/*
To support Dual stack.
*/}}
{{- define "eric-data-document-database-pg.internalIPFamily" -}}
  {{- $g := fromJson (include "eric-data-document-database-pg.global" .) -}}
  {{- if $g.internalIPFamily -}}
    {{- .Values.global.internalIPFamily | toString -}}
  {{- else -}}
    {{- "none" -}}
  {{- end -}}
{{- end -}}

{{- define "eric-data-document-database-pg.global.nodeSelector" -}}
  {{- $g := fromJson (include "eric-data-document-database-pg.global" .) -}}
  {{- $globalNodeSelector := dict -}}
  {{- if not (empty $g.nodeSelector) -}}
    {{- mergeOverwrite $globalNodeSelector $g.nodeSelector | toJson -}}
  {{- else -}}
    {{- $globalNodeSelector | toJson -}}
  {{- end -}}
{{- end -}}

{{- define "eric-data-document-database-pg.nodeSelector.postgres" -}}
  {{- $g := fromJson (include "eric-data-document-database-pg.global.nodeSelector" .) -}}
  {{- if not (empty .Values.nodeSelector.postgres) -}}
    {{- range $localkey, $localValue := .Values.nodeSelector.postgres -}}
      {{- if hasKey $g $localkey -}}
        {{- $globalValue := index $g $localkey -}}
        {{- if ne $localValue $globalValue -}}
          {{- printf "nodeSelector \"%s\" is specified in both global (%s: %s) and service level (%s: %s) with differing values which is not allowed." $localkey $localkey $globalValue $localkey $localValue  | fail -}}
        {{- end }}
      {{- end }}
    {{- end }}
    {{- toYaml (merge $g .Values.nodeSelector.postgres) | trim -}}
  {{- else -}}
    {{- toYaml $g | trim -}}
  {{- end -}}
{{- end -}}

{{- define "eric-data-document-database-pg.nodeSelector.brAgent" -}}
  {{- $g := fromJson (include "eric-data-document-database-pg.global.nodeSelector" .) -}}
  {{- if not (empty .Values.nodeSelector.brAgent) -}}
    {{- range $localkey, $localValue := .Values.nodeSelector.brAgent -}}
      {{- if hasKey $g $localkey -}}
        {{- $globalValue := index $g $localkey -}}
        {{- if ne $localValue $globalValue -}}
          {{- printf "nodeSelector \"%s\" is specified in both global (%s: %s) and service level (%s: %s) with differing values which is not allowed." $localkey $localkey $globalValue $localkey $localValue  | fail -}}
        {{- end }}
      {{- end }}
    {{- end }}
    {{- toYaml (merge $g .Values.nodeSelector.brAgent) | trim -}}
  {{- else -}}
    {{- toYaml $g | trim -}}
  {{- end -}}
{{- end -}}

{{- define "eric-data-document-database-pg.nodeSelector.cleanuphook" -}}
  {{- $g := fromJson (include "eric-data-document-database-pg.global.nodeSelector" .) -}}
  {{- if not (empty .Values.nodeSelector.cleanuphook) -}}
    {{- range $localkey, $localValue := .Values.nodeSelector.cleanuphook -}}
      {{- if hasKey $g $localkey -}}
        {{- $globalValue := index $g $localkey -}}
        {{- if ne $localValue $globalValue -}}
          {{- printf "nodeSelector \"%s\" is specified in both global (%s: %s) and service level (%s: %s) with differing values which is not allowed." $localkey $localkey $globalValue $localkey $localValue  | fail -}}
        {{- end }}
      {{- end }}
    {{- end }}
    {{- toYaml (merge $g .Values.nodeSelector.cleanuphook) | trim -}}
  {{- else -}}
    {{- toYaml $g | trim -}}
  {{- end -}}
{{- end -}}

{{- define "eric-data-document-database-pg.nodeSelector.feoperator" -}}
  {{- $g := fromJson (include "eric-data-document-database-pg.global.nodeSelector" .) -}}
  {{- if not (empty .Values.nodeSelector.feoperator) -}}
    {{- range $localkey, $localValue := .Values.nodeSelector.feoperator -}}
      {{- if hasKey $g $localkey -}}
        {{- $globalValue := index $g $localkey -}}
        {{- if ne $localValue $globalValue -}}
          {{- printf "nodeSelector \"%s\" is specified in both global (%s: %s) and service level (%s: %s) with differing values which is not allowed." $localkey $localkey $globalValue $localkey $localValue  | fail -}}
        {{- end }}
      {{- end }}
    {{- end }}
    {{- toYaml (merge $g .Values.nodeSelector.feoperator) | trim -}}
  {{- else -}}
    {{- toYaml $g | trim -}}
  {{- end -}}
{{- end -}}

{{- define "eric-data-document-database-pg.nodeSelector.oppatchhook" -}}
  {{- $g := fromJson (include "eric-data-document-database-pg.global.nodeSelector" .) -}}
  {{- if not (empty .Values.nodeSelector.oppatchhook) -}}
    {{- range $localkey, $localValue := .Values.nodeSelector.oppatchhook -}}
      {{- if hasKey $g $localkey -}}
        {{- $globalValue := index $g $localkey -}}
        {{- if ne $localValue $globalValue -}}
          {{- printf "nodeSelector \"%s\" is specified in both global (%s: %s) and service level (%s: %s) with differing values which is not allowed." $localkey $localkey $globalValue $localkey $localValue  | fail -}}
        {{- end }}
      {{- end }}
    {{- end }}
    {{- toYaml (merge $g .Values.nodeSelector.oppatchhook) | trim -}}
  {{- else -}}
    {{- toYaml $g | trim -}}
  {{- end -}}
{{- end -}}

{{- define "eric-data-document-database-pg.nodeSelector.beoperator" -}}
  {{- $g := fromJson (include "eric-data-document-database-pg.global.nodeSelector" .) -}}
  {{- if not (empty .Values.nodeSelector.beoperator) -}}
    {{- range $localkey, $localValue := .Values.nodeSelector.beoperator -}}
      {{- if hasKey $g $localkey -}}
        {{- $globalValue := index $g $localkey -}}
        {{- if ne $localValue $globalValue -}}
          {{- printf "nodeSelector \"%s\" is specified in both global (%s: %s) and service level (%s: %s) with differing values which is not allowed." $localkey $localkey $globalValue $localkey $localValue  | fail -}}
        {{- end }}
      {{- end }}
    {{- end }}
    {{- toYaml (merge $g .Values.nodeSelector.beoperator) | trim -}}
  {{- else -}}
    {{- toYaml $g | trim -}}
  {{- end -}}
{{- end -}}



{{- define "eric-data-document-database-pg.logSchema" -}}
    {{- if (eq "adp" (.Values.log.schema | toString))  }}
        {{- "json" -}}
    {{- else -}}
        {{- "none" -}}
    {{- end -}}
{{- end -}}

{{/*
fsGroup value follow up DR-1123-136
 */}}
{{- define "eric-data-document-database-pg.fsGroup.coordinated" -}}
  {{- $g := fromJson (include "eric-data-document-database-pg.global" .) -}}
  {{- $fsGroup := "" -}}
  {{- if or (eq "0" (toString $g.fsGroup.manual)) $g.fsGroup.manual -}}
    {{- $fsGroup = $g.fsGroup.manual | int -}}
    {{- printf "%d" $fsGroup -}}
  {{- else if (($g).fsGroup).namespace -}}
    {{/* The 'default' defined in the Security Policy will be used. */}}
    {{- printf "" -}}
  {{- else -}}
    {{- printf "%d" 10000 -}}
  {{- end -}}
{{- end -}}


{{- define "eric-data-document-database-pg.trustedInternalRootCa" -}}
  {{- $g := fromJson (include "eric-data-document-database-pg.global" .) -}}
  {{- if ((($g.security).tls).trustedInternalRootCa).secret -}}
    {{ $g.security.tls.trustedInternalRootCa.secret }}
  {{- else -}}
    eric-sec-sip-tls-trusted-root-cert
  {{- end -}}
{{- end -}}


{{/*
Apply when allowPrivilegeEscalation is true.
*/}}
{{- define "eric-data-document-database-pg.securityPolicy.reference" -}}
  {{- $g := fromJson (include "eric-data-document-database-pg.global" .) -}}
  {{- if $g.security.policyReferenceMap -}}
    {{ $mapped := index .Values "global" "security" "policyReferenceMap" "plc-59d0cf1dcc793a78b6ce30bfbe6553" }}
    {{- if $mapped -}}
      {{ $mapped }}
    {{- else -}}
      plc-59d0cf1dcc793a78b6ce30bfbe6553
    {{- end -}}
  {{- else -}}
    plc-59d0cf1dcc793a78b6ce30bfbe6553
  {{- end -}}
{{- end -}}

{{/*
Apply when allowPrivilegeEscalation is false.
*/}}
{{- define "eric-data-document-database-pg.securityPolicy.reference-default" -}}
  {{- $g := fromJson (include "eric-data-document-database-pg.global" .) -}}
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
{{- end -}}


{{- define "eric-data-document-database-pg.securityPolicy.rolekind" -}}
  {{- if eq "ClusterRole" (((.Values.global).securityPolicy).rolekind | toString) -}}
ClusterRole
  {{- else if eq "Role" (((.Values.global).securityPolicy).rolekind | toString) -}}
Role
  {{- end -}}
{{- end -}}


{{- define "eric-data-document-database-pg.securityPolicy.rolename" -}}
  {{- if (hasKey .Values.securityPolicy .PodName) -}}
    {{- $podRolename := (get .Values.securityPolicy .PodName) -}}
    {{- if $podRolename.rolename -}}
{{ $podRolename.rolename }}
    {{- end -}}
  {{- else -}}
    {{- fail "Pod name not found in Values" }}
  {{- end -}}
{{- end -}}

{{- define "eric-data-document-database-pg.HugePage.Volumes" }}
  {{- if and (index .Values "resources" "postgres" "limits" "hugepages-2Mi") (index .Values "resources" "postgres" "limits" "hugepages-1Gi") }}
    {{- if semverCompare "<1.19.0-0" .Capabilities.KubeVersion.Version }}
      {{- fail "Multisize hugepage is only supported on Kuberentes 1.19 and later" }}
    {{- else }}
- name: hugepage-2mi
  emptyDir:
    medium: HugePages-2Mi
- name: hugepage-1gi
  emptyDir:
    medium: HugePages-1Gi
    {{- end }}
  {{- else if or (index .Values "resources" "postgres" "limits" "hugepages-2Mi") (index .Values "resources" "postgres" "limits" "hugepages-1Gi") }}
- name: hugepage
  emptyDir:
    medium: HugePages
  {{- end }}
{{- end }}


{{ define "eric-data-document-database-pg.HugePage.VolumeMounts" }}
  {{- if and (index .Values "resources" "postgres" "limits" "hugepages-2Mi") (index .Values "resources" "postgres" "limits" "hugepages-1Gi") }}
    {{- if semverCompare "<1.19.0-0" .Capabilities.KubeVersion.Version }}
      {{- fail "Multisize hugepage is only supported on Kuberentes 1.19 and later" }}
    {{- else }}
- mountPath: /hugepages-2Mi
  name: hugepage-2mi
- mountPath: /hugepages-1Gi
  name: hugepage-1gi
    {{- end }}
  {{- else if or (index .Values "resources" "postgres" "limits" "hugepages-2Mi") (index .Values "resources" "postgres" "limits" "hugepages-1Gi") }}
- mountPath: /hugepages
  name: hugepage
  {{- end }}
{{- end }}

{{/*
Volume mount name used for Statefulset
*/}}
{{- define "eric-data-document-database-pg.persistence.volumeMount.name" -}}
  {{- printf "%s" "pg-data" -}}
{{- end -}}

{{/*
Kubernetes labels
*/}}
{{- define "eric-data-document-database-pg.kubernetes-labels" -}}
app.kubernetes.io/name: {{ include "eric-data-document-database-pg.name" . }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/version: {{ include "eric-data-document-database-pg.version" . }}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "eric-data-document-database-pg.labels" -}}
  {{- $kubernetesLabels := include "eric-data-document-database-pg.kubernetes-labels" . | fromYaml -}}
  {{- $globalLabels := (.Values.global).labels -}}
  {{- $serviceLabels := .Values.labels -}}
  {{- include "eric-data-document-database-pg.mergeLabels" (dict "location" .Template.Name "sources" (list $kubernetesLabels $globalLabels $serviceLabels)) }}
{{- end -}}

{{/*
Define networkpolicy P2 labels for LT & BRO service
Optional:
  - broLabel
*/}}
{{- define "eric-data-document-database-pg.networkpolicyp2.labels" -}}
  {{- $g := fromJson (include "eric-data-document-database-pg.global" .) -}}
  {{- $nwpBroLabel := default "false" .broLabel -}}
  {{- if .Values.networkPolicy -}}
  {{- if and $g.networkPolicy.enabled .Values.networkPolicy.enabled -}}
    {{- $nwpLabels := dict -}}
    {{- $_ := set $nwpLabels (printf "%s-access" .Values.logShipper.output.logTransformer.host) "true" }}
    {{- if and .Values.brAgent.enabled (eq $nwpBroLabel "true")  -}}
      {{- $_ := set $nwpLabels (printf "%s-access" $g.adpBR.broServiceName) "true" -}}
    {{- end -}}
    {{- include "eric-data-document-database-pg.mergeLabels" (dict "location" .Template.Name "sources" (list $nwpLabels)) }}
  {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Merged labels for extended defaults
*/}}
{{- define "eric-data-document-database-pg.labels.extended-defaults" -}}
  {{- $extendedLabels := dict -}}
  {{- $_ := set $extendedLabels "app" (include "eric-data-document-database-pg.name" .) -}}
  {{- $_ := set $extendedLabels "chart" (include "eric-data-document-database-pg.chart" .) -}}
  {{- $_ := set $extendedLabels "release" (.Release.Name) -}}
  {{- $_ := set $extendedLabels "heritage" (.Release.Service) -}}
  {{- $commonLabels := include "eric-data-document-database-pg.labels" . | fromYaml -}}
  {{- include "eric-data-document-database-pg.mergeLabels" (dict "location" .Template.Name "sources" (list $commonLabels $extendedLabels)) | trim }}
{{- end -}}

{{/*
Create a dict of annotations for the product information (DR-D1121-064, DR-D1121-067).
*/}}
{{- define "eric-data-document-database-pg.product-info" }}
ericsson.com/product-name: {{ template "eric-data-document-database-pg.helm-annotations_product_name" . }}
ericsson.com/product-number: {{ template "eric-data-document-database-pg.helm-annotations_product_number" . }}
ericsson.com/product-revision: {{ template "eric-data-document-database-pg.helm-annotations_product_revision" . }}
{{- end }}

{{/*
Common annotations
*/}}
{{- define "eric-data-document-database-pg.annotations" -}}
  {{- $productInfo := include "eric-data-document-database-pg.product-info" . | fromYaml -}}
  {{- $globalAnn := (.Values.global).annotations -}}
  {{- $serviceAnn := .Values.annotations -}}
  {{- include "eric-data-document-database-pg.mergeAnnotations" (dict "location" .Template.Name "sources" (list $productInfo $globalAnn $serviceAnn)) | trim }}
{{- end -}}

{{/*
Align to DR-D1120-056
*/}}
{{- define "eric-data-document-database-pg.podDisruptionBudget" -}}
{{- if or (eq "0" (.Values.podDisruptionBudget.minAvailable | toString )) (not (empty .Values.podDisruptionBudget.minAvailable )) }}
minAvailable: {{ .Values.podDisruptionBudget.minAvailable }}
{{- else if or (eq "0" (.Values.podDisruptionBudget.maxUnavailable | toString )) (not (empty .Values.podDisruptionBudget.maxUnavailable )) }}
maxUnavailable: {{ .Values.podDisruptionBudget.maxUnavailable }}
{{- else }}
minAvailable: 50%
{{- end }}
{{- end -}}

{{- define "eric-data-document-database-pg.preUpgradeHookBackup" }}
{{- if or .Release.IsUpgrade .Release.IsInstall }}
{{- $globalValue := fromJson (include "eric-data-document-database-pg.global" .) -}}
{{- $logshipperValues := fromJson (include "eric-data-document-database-pg.ls-values" .) -}}
{{- $logshipperCopied := deepCopy . -}}
{{- $logshipperMerged := (mergeOverwrite $logshipperCopied $logshipperValues) -}}
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ template "eric-data-document-database-pg.name" . }}-backup-pgdata
  labels: {{- include "eric-data-document-database-pg.labels.extended-defaults" . | nindent 4 }}
  annotations:
    {{- $helmHooks := dict -}}
    {{- $_ := set $helmHooks "helm.sh/hook" "pre-upgrade" -}}
    {{- $_ := set $helmHooks "helm.sh/hook-delete-policy" "hook-succeeded,before-hook-creation" -}}
    {{- $_ := set $helmHooks "helm.sh/hook-weight" "-2" -}}
    {{- $commonAnn := fromYaml (include "eric-data-document-database-pg.annotations" .) -}}
    {{- include "eric-data-document-database-pg.mergeAnnotations" (dict "location" .Template.Name "sources" (list $helmHooks $commonAnn)) | nindent 4 }}
spec:
  backoffLimit: 0
  template:
    metadata:
      labels:
        {{- $podTemplateLabels := dict -}}
        {{- $_ := set $podTemplateLabels "sidecar.istio.io/inject" "false" -}}
        {{- $_ := set $podTemplateLabels "app" (printf "%s-%s" (include "eric-data-document-database-pg.name" .) "backup-pgdata") -}}
        {{- $commonLabels := fromYaml (include "eric-data-document-database-pg.labels" .) -}}
        {{- $networkpllabels := fromYaml (include "eric-data-document-database-pg.networkpolicyp2.labels" .) -}}
        {{- include "eric-data-document-database-pg.mergeLabels" (dict "location" .Template.Name "sources" (list $podTemplateLabels $commonLabels $networkpllabels)) | trim | nindent 8 }}
      annotations:
        {{- $podTempAnn := dict -}}
        {{- if .Values.bandwidth.cleanuphook.maxEgressRate }}
          {{- $_ := set $podTempAnn "kubernetes.io/egress-bandwidth" (.Values.bandwidth.cleanuphook.maxEgressRate | toString) -}}
        {{- end }}
        {{- $commonAnn := fromYaml (include "eric-data-document-database-pg.annotations" .) -}}
        {{- $appArmorAnn := include "eric-data-document-database-pg.appArmorProfile" (dict "root" . "Scope" "Hook" "containerList" (list "backup-pgdata")) | fromYaml -}}
        {{- include "eric-data-document-database-pg.mergeAnnotations" (dict "location" .Template.Name "sources" (list $podTempAnn $appArmorAnn $commonAnn)) | trim | nindent 8 }}
    spec:
      restartPolicy: Never
      serviceAccountName: {{ template "eric-data-document-database-pg.name" . }}-pgdata-hook
      {{- if include "eric-data-document-database-pg.pullSecrets" . }}
      imagePullSecrets:
        - name: {{ template "eric-data-document-database-pg.pullSecrets" . }}
      {{- end }}
      securityContext:
        fsGroup: {{ template "eric-data-document-database-pg.fsGroup.coordinated" . }}
          {{- if semverCompare ">=1.23.0-0" .Capabilities.KubeVersion.Version }}
        fsGroupChangePolicy: "OnRootMismatch"
          {{- end }}
        {{- if include "eric-data-document-database-pg.podSecurityContext.supplementalGroups" . -}}
{{- include "eric-data-document-database-pg.podSecurityContext.supplementalGroups" . | nindent 8 }}
        {{- end }}
{{- include "eric-data-document-database-pg.seccompProfile" (dict "Values" .Values "Scope" "Pod") | nindent 8 }}
      {{- if or (not (empty .Values.nodeSelector.cleanuphook)) (not (eq "{}" (include "eric-data-document-database-pg.global.nodeSelector" .))) }}
      nodeSelector:
{{- include "eric-data-document-database-pg.nodeSelector.cleanuphook" . | nindent 8 }}
      {{- end }}
      tolerations:
{{ include "eric-data-document-database-pg.merge-tolerations" (dict "root" . "podbasename" "cleanuphook") | nindent 8}}
      {{- if .Values.podPriority.cleanuphook.priorityClassName }}
      priorityClassName: {{ .Values.podPriority.cleanuphook.priorityClassName | quote }}
      {{- end }}
      containers:
        - name: backup-pgdata
          image: {{ template "eric-data-document-database-pg.kubeclientImagePath" . }}
          imagePullPolicy: {{ include "eric-data-document-database-pg.imagePullPolicy" . | quote }}
          env:
          - name: STATEFULSET_NAME
            value: {{ template "eric-data-document-database-pg.name" . }}
          - name: REPLICA_COUNT
            value: {{ .Values.highAvailability.replicaCount | quote }}
          - name: CLUSTER_NAME
            value: {{ template "eric-data-document-database-pg.name" . }}
          - name: RELEASE_NAME
            value: {{ .Release.Name | quote }}
          - name: KUBERNETES_NAMESPACE
            valueFrom: { fieldRef: { fieldPath: metadata.namespace } }
          - name: TRANSIT_COMPONENT
            value: {{ template "eric-data-document-database-pg.name" . }}-transit-pvc
          - name: TARGET_PG_VERSION
            value: "13"
          - name: LOG_SCHEMA
            value: {{ template "eric-data-document-database-pg.logSchema" . }}
          - name: PHASE
            value: "upgrading"
          - name: TZ
            value: {{ $globalValue.timezone | quote }}
          - name: BR_LOG_LEVEL
            value: {{ .Values.brAgent.logLevel }}
          - name: MONITOR_LOG_LEVEL
            value: {{ .Values.patroni.logLevel }}
          {{- if (eq (include "eric-data-document-database-pg.global-security-tls-enabled" .) "false") }}
          - name: PGPASSWORD
            valueFrom:
              secretKeyRef:
                name: {{ required "Require .Values.credentials.kubernetesSecretName " .Values.credentials.kubernetesSecretName | quote }}
                key: {{ .Values.credentials.keyForSuperPw | quote }}
          {{- else if eq .Values.service.endpoints.postgres.tls.enforced "optional" }}
          - name: PGPASSWORD
            valueFrom:
              secretKeyRef:
                name: {{ required "Require .Values.credentials.kubernetesSecretName " .Values.credentials.kubernetesSecretName | quote }}
                key: {{ .Values.credentials.keyForSuperPw | quote }}
          {{- else }}
          - name: PGPASSWORD
            value: "fakepgpass"
          {{- end }}
          - name: ENABLE_SIPTLS
            {{- if (not (eq (include "eric-data-document-database-pg.global-security-tls-enabled" .) "false")) }}
            value: "true"
            {{- else }}
            value: "false"
            {{- end }}
          - name: PG_CLIENT_TLS_CERT_PATH
            value: /run/secrets/{{ template "eric-data-document-database-pg.secretBaseName" . }}-postgres-cert
          - name: CONTAINER_NAME
            value: {{ template "eric-data-document-database-pg.name" . }}-hook
          - name: LOG_REDIRECT
            value: {{ template "eric-data-document-database-pg.logRedirect" . }}
          command:
            - /bin/bash
            - -c
          args:
            - "
              /usr/bin/catatonit -- 
              {{ template "eric-data-document-database-pg.stdRedirectCMD" .  }}
              /backup_pgdata_entrypoint.sh {{ template "eric-data-document-database-pg.hook.scriptPath" . }}; RES=$?; sleep 3; exit ${RES}"
          securityContext:
            {{- include "eric-data-document-database-pg.seccompProfile" (dict "Values" .Values "Scope" "backup-pgdata") | nindent 12 }}
            allowPrivilegeEscalation: false
            privileged: false
            readOnlyRootFilesystem: true
            runAsNonRoot: true
            capabilities:
              drop:
                - ALL
          volumeMounts:
          {{- include "eric-data-document-database-pg.log.mounts-hooks" $logshipperMerged | indent 12 }}
            - name: tmp
              mountPath: /tmp
            - name: pgdata-volume
              mountPath: "/var/pgdata"
          {{- if  (not (eq (include "eric-data-document-database-pg.global-security-tls-enabled" .) "false")) }}
            - name: postgres-client-certificates
              mountPath: /run/secrets/{{ template "eric-data-document-database-pg.secretBaseName" . }}-postgres-cert/
          {{- end }}
          resources:
            requests:
            {{- if .Values.resources.kube_client.requests.cpu }}
              cpu: {{ .Values.resources.kube_client.requests.cpu  | quote }}
            {{- end }}
            {{- if .Values.resources.kube_client.requests.memory }}
              memory: {{ .Values.resources.kube_client.requests.memory  | quote }}
            {{- end }}
            {{- if index .Values.resources.kube_client.requests "ephemeral-storage" }}
              ephemeral-storage: {{ index .Values.resources.kube_client.requests "ephemeral-storage" | quote }}
            {{- end }}
            limits:
            {{- if .Values.resources.kube_client.limits.cpu }}
              cpu: {{ .Values.resources.kube_client.limits.cpu  | quote }}
            {{- end }}
            {{- if .Values.resources.kube_client.limits.memory }}
              memory: {{ .Values.resources.kube_client.limits.memory  | quote }}
            {{- end }}
            {{- if index .Values.resources.kube_client.limits "ephemeral-storage" }}
              ephemeral-storage: {{ index .Values.resources.kube_client.limits "ephemeral-storage" | quote }}
            {{- end }}
      {{- include "eric-data-document-database-pg.log.containers-hooks" $logshipperMerged | indent 8 }}
      volumes:
      {{- include "eric-data-document-database-pg.log.volumes-hooks" $logshipperMerged | indent 6 }}
      - name: tmp
        emptyDir: {}
      - name: pgdata-volume
        persistentVolumeClaim:
          claimName: {{ template "eric-data-document-database-pg.name" . }}-backup-pgdata
      {{- if  (not (eq (include "eric-data-document-database-pg.global-security-tls-enabled" .) "false")) }}
      - name: postgres-client-certificates
        secret:
          secretName: {{ template "eric-data-document-database-pg.secretBaseName" . }}-postgres-cert
          defaultMode: 0640
          optional: true
      {{- end }}
{{- end -}}
{{- end }}


{{- define "eric-data-document-database-pg.restorePGDataJob" }}
{{- if or .Release.IsUpgrade .Release.IsInstall }}
{{- $globalValue := fromJson (include "eric-data-document-database-pg.global" .) -}}
{{- $logshipperValues := fromJson (include "eric-data-document-database-pg.ls-values" .) -}}
{{- $logshipperCopied := deepCopy . -}}
{{- $logshipperMerged := (mergeOverwrite $logshipperCopied $logshipperValues) -}}
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ template "eric-data-document-database-pg.name" . }}-restore-pgdatau
  labels: {{- include "eric-data-document-database-pg.labels.extended-defaults" . | nindent 4 }}
  annotations: {{- include "eric-data-document-database-pg.annotations" . | nindent 4 }}
spec:
  backoffLimit: 0
  template:
    metadata:
      labels:
        {{- $podTemplateLabels := dict -}}
        {{- $_ := set $podTemplateLabels "sidecar.istio.io/inject" "false" -}}
        {{- $_ := set $podTemplateLabels "app" (printf "%s-%s" (include "eric-data-document-database-pg.name" .) "restore-pgdata") -}}
        {{- $commonLabels := fromYaml (include "eric-data-document-database-pg.labels" .) -}}
        {{- $networkpllabels := fromYaml (include "eric-data-document-database-pg.networkpolicyp2.labels" .) -}}
        {{- include "eric-data-document-database-pg.mergeLabels" (dict "location" .Template.Name "sources" (list $commonLabels $podTemplateLabels $networkpllabels)) | nindent 8 }}
      annotations:
        {{- $podTempAnn := dict -}}
        {{- if .Values.bandwidth.cleanuphook.maxEgressRate }}
          {{- $_ := set $podTempAnn "kubernetes.io/egress-bandwidth" (.Values.bandwidth.cleanuphook.maxEgressRate | toString) -}}
        {{- end }}
        {{- $commonAnn := fromYaml (include "eric-data-document-database-pg.annotations" .) -}}
        {{- $appArmorAnn := include "eric-data-document-database-pg.appArmorProfile" (dict "root" . "Scope" "Hook" "containerList" (list "restore-pgdata")) | fromYaml -}}
        {{- include "eric-data-document-database-pg.mergeAnnotations" (dict "location" .Template.Name "sources" (list $podTempAnn $appArmorAnn $commonAnn)) | trim | nindent 8 }}
    spec:
      restartPolicy: Never
      serviceAccountName: {{ template "eric-data-document-database-pg.name" . }}-pgdata-hook
      {{- if include "eric-data-document-database-pg.pullSecrets" . }}
      imagePullSecrets:
        - name: {{ template "eric-data-document-database-pg.pullSecrets" . }}
      {{- end }}
      securityContext:
        fsGroup: {{ template "eric-data-document-database-pg.fsGroup.coordinated" . }}
          {{- if semverCompare ">=1.23.0-0" .Capabilities.KubeVersion.Version }}
        fsGroupChangePolicy: "OnRootMismatch"
          {{- end }}
        {{- if include "eric-data-document-database-pg.podSecurityContext.supplementalGroups" . -}}
{{- include "eric-data-document-database-pg.podSecurityContext.supplementalGroups" . | nindent 8 }}
        {{- end }}
{{- include "eric-data-document-database-pg.seccompProfile" (dict "Values" .Values "Scope" "Pod") | nindent 8 }}
      {{- if or (not (empty .Values.nodeSelector.cleanuphook)) (not (eq "{}" (include "eric-data-document-database-pg.global.nodeSelector" .))) }}
      nodeSelector:
{{- include "eric-data-document-database-pg.nodeSelector.cleanuphook" . | nindent 8 }}
      {{- end }}
      tolerations:
{{ include "eric-data-document-database-pg.merge-tolerations" (dict "root" . "podbasename" "cleanuphook") | nindent 8}}
      {{- if .Values.podPriority.cleanuphook.priorityClassName }}
      priorityClassName: {{ .Values.podPriority.cleanuphook.priorityClassName | quote }}
      {{- end }}
      containers:
        - name: restore-pgdata
          image: {{ template "eric-data-document-database-pg.kubeclientImagePath" . }}
          imagePullPolicy: {{ include "eric-data-document-database-pg.imagePullPolicy" . | quote }}
          env:
          - name: STATEFULSET_NAME
            value: {{ template "eric-data-document-database-pg.name" . }}
          - name: REPLICA_COUNT
            value: {{ .Values.highAvailability.replicaCount | quote }}
          - name: CLUSTER_NAME
            value: {{ template "eric-data-document-database-pg.name" . }}
          - name: KUBERNETES_NAMESPACE
            valueFrom: { fieldRef: { fieldPath: metadata.namespace } }
          - name: TRANSIT_COMPONENT
            value: {{ template "eric-data-document-database-pg.name" . }}-transit-pvc
          - name: TARGET_PG_VERSION
            value: "13"
          - name: LOG_SCHEMA
            value: {{ template "eric-data-document-database-pg.logSchema" . }}
          - name: PHASE
            value: "upgrading"
          - name: TZ
            value: {{ $globalValue.timezone | quote }}
          - name: PG_TERM_PERIOD
            {{- if .Values.terminationGracePeriodSeconds }}
            value: {{ default "30" .Values.terminationGracePeriodSeconds.postgres | quote }}
            {{- else }}
            value: "30"
            {{- end }}
          - name: BR_LOG_LEVEL
            value: {{ .Values.brAgent.logLevel }}
          - name: MONITOR_LOG_LEVEL
            value: {{ .Values.patroni.logLevel }}
          - name: NETWORK_POLICY_HOOK_NAME
            value: {{ template "eric-data-document-database-pg.name" . }}-hook
          {{- if (eq (include "eric-data-document-database-pg.global-security-tls-enabled" .) "false") }}
          - name: PGPASSWORD
            valueFrom:
              secretKeyRef:
                name: {{ required "Require .Values.credentials.kubernetesSecretName " .Values.credentials.kubernetesSecretName | quote }}
                key: {{ .Values.credentials.keyForSuperPw | quote }}
          {{- else if eq .Values.service.endpoints.postgres.tls.enforced "optional" }}
          - name: PGPASSWORD
            valueFrom:
              secretKeyRef:
                name: {{ required "Require .Values.credentials.kubernetesSecretName " .Values.credentials.kubernetesSecretName | quote }}
                key: {{ .Values.credentials.keyForSuperPw | quote }}
          {{- else }}
          - name: PGPASSWORD
            value: "fakepgpass"
          {{- end }}
          - name: ENABLE_SIPTLS
            {{- if (not (eq (include "eric-data-document-database-pg.global-security-tls-enabled" .) "false")) }}
            value: "true"
            {{- else }}
            value: "false"
            {{- end }}
          - name: PG_CLIENT_TLS_CERT_PATH
            value: /run/secrets/{{ template "eric-data-document-database-pg.secretBaseName" . }}-postgres-cert
          - name: CONTAINER_NAME
            value: {{ template "eric-data-document-database-pg.name" . }}-hook
          - name: LOG_REDIRECT
            value: {{ template "eric-data-document-database-pg.logRedirect" . }}
          command:
            - /bin/bash
            - -c
          args:
            - "
              /usr/bin/catatonit -- 
              {{ template "eric-data-document-database-pg.stdRedirectCMD" .  }}
              /restore_pgdata_entrypoint.sh {{ template "eric-data-document-database-pg.hook.scriptPath" . }}; RES=$?; sleep 3; exit ${RES}"
          securityContext:
            {{- include "eric-data-document-database-pg.seccompProfile" (dict "Values" .Values "Scope" "restore-pgdata") | nindent 12 }}
            allowPrivilegeEscalation: false
            privileged: false
            readOnlyRootFilesystem: true
            runAsNonRoot: true
            capabilities:
              drop:
                - ALL
          volumeMounts:
            {{- include "eric-data-document-database-pg.log.mounts-hooks" $logshipperMerged | indent 12 }}
            - name: tmp
              mountPath: /tmp
            - name: pgdata-volume
              mountPath: "/var/pgdata"
          {{- if  (not (eq (include "eric-data-document-database-pg.global-security-tls-enabled" .) "false")) }}
            - name: postgres-client-certificates
              mountPath: /run/secrets/{{ template "eric-data-document-database-pg.secretBaseName" . }}-postgres-cert/
          {{- end }}
          resources:
            requests:
            {{- if .Values.resources.kube_client.requests.cpu }}
              cpu: {{ .Values.resources.kube_client.requests.cpu  | quote }}
            {{- end }}
            {{- if .Values.resources.kube_client.requests.memory }}
              memory: {{ .Values.resources.kube_client.requests.memory  | quote }}
            {{- end }}
            {{- if index .Values.resources.kube_client.requests "ephemeral-storage" }}
              ephemeral-storage: {{ index .Values.resources.kube_client.requests "ephemeral-storage" | quote }}
            {{- end }}
            limits:
            {{- if .Values.resources.kube_client.limits.cpu }}
              cpu: {{ .Values.resources.kube_client.limits.cpu  | quote }}
            {{- end }}
            {{- if .Values.resources.kube_client.limits.memory }}
              memory: {{ .Values.resources.kube_client.limits.memory  | quote }}
            {{- end }}
            {{- if index .Values.resources.kube_client.limits "ephemeral-storage" }}
              ephemeral-storage: {{ index .Values.resources.kube_client.limits "ephemeral-storage" | quote }}
            {{- end }}
      {{- include "eric-data-document-database-pg.log.containers-hooks" $logshipperMerged | indent 8 }}
      volumes:
      {{- include "eric-data-document-database-pg.log.volumes-hooks" $logshipperMerged | indent 6 }}
      - name: tmp
        emptyDir: {}
      - name: pgdata-volume
        persistentVolumeClaim:
          claimName: {{ template "eric-data-document-database-pg.name" . }}-backup-pgdata
      {{- if  (not (eq (include "eric-data-document-database-pg.global-security-tls-enabled" .) "false")) }}
      - name: postgres-client-certificates
        secret:
          secretName: {{ template "eric-data-document-database-pg.secretBaseName" . }}-postgres-cert
          defaultMode: 0640
          optional: true
      {{- end }}
{{- end -}}
{{- end }}


{{- define "eric-data-document-database-pg.cleanPGDataJob" }}
{{- if or .Release.IsUpgrade .Release.IsInstall }}
{{- $globalValue := fromJson (include "eric-data-document-database-pg.global" .) -}}
{{- $logshipperValues := fromJson (include "eric-data-document-database-pg.ls-values" .) -}}
{{- $logshipperCopied := deepCopy . -}}
{{- $logshipperMerged := (mergeOverwrite $logshipperCopied $logshipperValues) -}}
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ template "eric-data-document-database-pg.name" . }}-hook-cleanjob
  labels:
    {{- include "eric-data-document-database-pg.labels.extended-defaults" . | nindent 4 }}
  annotations:
    {{- $helmHooks := dict -}}
    {{- $_ := set $helmHooks "helm.sh/hook" "post-upgrade" -}}
    {{- $_ := set $helmHooks "helm.sh/hook-delete-policy" "hook-succeeded,before-hook-creation" -}}
    {{- $_ := set $helmHooks "helm.sh/hook-weight" "-5" -}}
    {{- $commonAnn := fromYaml (include "eric-data-document-database-pg.annotations" .) -}}
    {{- include "eric-data-document-database-pg.mergeAnnotations" (dict "location" .Template.Name "sources" (list $helmHooks $commonAnn)) | trim | nindent 4 }}
spec:
  template:
    metadata:
      labels:
        {{- $podTemplateLabels := dict -}}
        {{- $_ := set $podTemplateLabels "sidecar.istio.io/inject" "false" -}}
        {{- $_ := set $podTemplateLabels "app" (printf "%s-hook-cleanjob" (include "eric-data-document-database-pg.name" .)) -}}
        {{- $commonLabels := fromYaml (include "eric-data-document-database-pg.labels" .) -}}
        {{- $_ := unset $commonLabels "app" -}}
        {{- $networkpllabels := fromYaml (include "eric-data-document-database-pg.networkpolicyp2.labels" .) -}}
        {{- include "eric-data-document-database-pg.mergeLabels" (dict "location" .Template.Name "sources" (list $podTemplateLabels $commonLabels $networkpllabels)) | trim | nindent 8 }}
      annotations:
        {{- $podTempAnn := dict -}}
        {{- if .Values.bandwidth.cleanuphook.maxEgressRate }}
          {{- $_ := set $podTempAnn "kubernetes.io/egress-bandwidth" (.Values.bandwidth.cleanuphook.maxEgressRate | toString) -}}
        {{- end }}
        {{- $commonAnn := fromYaml (include "eric-data-document-database-pg.annotations" .) -}}
        {{- $appArmorAnn := include "eric-data-document-database-pg.appArmorProfile" (dict "root" . "Scope" "Hook" "containerList" (list "hook-cleanjob")) | fromYaml -}}
        {{- include "eric-data-document-database-pg.mergeAnnotations" (dict "location" .Template.Name "sources" (list $podTempAnn $appArmorAnn $commonAnn)) | trim | nindent 8 }}
    spec:
      restartPolicy: Never
      serviceAccountName: {{ template "eric-data-document-database-pg.name" . }}-hook
      {{- if include "eric-data-document-database-pg.pullSecrets" . }}
      imagePullSecrets:
        - name: {{ template "eric-data-document-database-pg.pullSecrets" . }}
      {{- end }}
      securityContext:
        fsGroup: {{ template "eric-data-document-database-pg.fsGroup.coordinated" . }}
          {{- if semverCompare ">=1.23.0-0" .Capabilities.KubeVersion.Version }}
        fsGroupChangePolicy: "OnRootMismatch"
          {{- end }}
        {{- if include "eric-data-document-database-pg.podSecurityContext.supplementalGroups" . -}}
{{- include "eric-data-document-database-pg.podSecurityContext.supplementalGroups" . | nindent 8 }}
        {{- end }}
{{- include "eric-data-document-database-pg.seccompProfile" (dict "Values" .Values "Scope" "Pod") | nindent 8 }}
      {{- if or (not (empty .Values.nodeSelector.cleanuphook)) (not (eq "{}" (include "eric-data-document-database-pg.global.nodeSelector" .))) }}
      nodeSelector:
{{- include "eric-data-document-database-pg.nodeSelector.cleanuphook" . | nindent 8 }}
      {{- end }}
      tolerations:
{{ include "eric-data-document-database-pg.merge-tolerations" (dict "root" . "podbasename" "cleanuphook") | nindent 8}}
      {{- if .Values.podPriority.cleanuphook.priorityClassName }}
      priorityClassName: {{ .Values.podPriority.cleanuphook.priorityClassName | quote }}
      {{- end }}
      containers:
        - name: hook-cleanjob
          image: {{ template "eric-data-document-database-pg.kubeclientImagePath" . }}
          imagePullPolicy: {{ include "eric-data-document-database-pg.imagePullPolicy" . | quote }}
          env:
          - name: CLUSTER_NAME
            value: {{ template "eric-data-document-database-pg.name" . }}
          - name: LOG_SCHEMA
            value: {{ template "eric-data-document-database-pg.logSchema" . }}
          - name: KUBERNETES_NAMESPACE
            valueFrom: { fieldRef: { fieldPath: metadata.namespace } }
          - name: CONTAINER_NAME
            value: {{ template "eric-data-document-database-pg.name" . }}-hook
          - name: LOG_REDIRECT
            value: {{ template "eric-data-document-database-pg.logRedirect" . }}
          - name: TZ
            value: {{ $globalValue.timezone | quote }}
          command:
            - /bin/bash
            - -c
          args:
            - "/usr/bin/catatonit -- 
              {{ template "eric-data-document-database-pg.stdRedirectCMD" .  }}
              /usr/bin/python {{ template "eric-data-document-database-pg.hook.scriptPath" . }}/cleanjob.py
              --clean_upgrading_pgdata_job; sleep 3"
          securityContext:
            {{- include "eric-data-document-database-pg.seccompProfile" (dict "Values" .Values "Scope" "hook-cleanjob") | nindent 12 }}
            allowPrivilegeEscalation: false
            privileged: false
            readOnlyRootFilesystem: true
            runAsNonRoot: true
            capabilities:
              drop:
                - ALL
          volumeMounts:
          {{- if .Release.IsUpgrade }}
            {{- include "eric-data-document-database-pg.log.mounts-hooks" $logshipperMerged | indent 12 }}
          {{- end }}
            - name: tmp
              mountPath: /tmp
          resources:
            requests:
            {{- if .Values.resources.kube_client.requests.cpu }}
              cpu: {{ .Values.resources.kube_client.requests.cpu  | quote }}
            {{- end }}
            {{- if .Values.resources.kube_client.requests.memory }}
              memory: {{ .Values.resources.kube_client.requests.memory  | quote }}
            {{- end }}
            {{- if index .Values.resources.kube_client.requests "ephemeral-storage" }}
              ephemeral-storage: {{ index .Values.resources.kube_client.requests "ephemeral-storage" | quote }}
            {{- end }}
            limits:
            {{- if .Values.resources.kube_client.limits.cpu }}
              cpu: {{ .Values.resources.kube_client.limits.cpu  | quote }}
            {{- end }}
            {{- if .Values.resources.kube_client.limits.memory }}
              memory: {{ .Values.resources.kube_client.limits.memory  | quote }}
            {{- end }}
            {{- if index .Values.resources.kube_client.limits "ephemeral-storage" }}
              ephemeral-storage: {{ index .Values.resources.kube_client.limits "ephemeral-storage" | quote }}
            {{- end }}
      {{- if .Release.IsUpgrade }}
      {{- include "eric-data-document-database-pg.log.containers-hooks" $logshipperMerged | indent 8 }}
      {{- end }}
      volumes:
      {{- if .Release.IsUpgrade }}
      {{- include "eric-data-document-database-pg.log.volumes-hooks" $logshipperMerged | indent 6 }}
      {{- end }}
      - name: tmp
        emptyDir: {}
{{- end -}}
{{- end }}

{{- define "eric-data-document-database-pg.networkPolicyHook" }}
{{- if or .Release.IsUpgrade .Release.IsInstall }}
{{- $globalValue := fromJson (include "eric-data-document-database-pg.global" .) -}}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ template "eric-data-document-database-pg.name" . }}-hook
  labels:
    {{- include "eric-data-document-database-pg.labels" . | nindent 4 }}
  annotations:
    {{- $helmHooks := dict -}}
    {{- $_ := set $helmHooks "helm.sh/hook" "pre-upgrade" -}}
    {{- $_ := set $helmHooks "helm.sh/hook-weight" "-3" -}}
    {{- $commonAnn := fromYaml (include "eric-data-document-database-pg.annotations" .) -}}
    {{- include "eric-data-document-database-pg.mergeAnnotations" (dict "location" .Template.Name "sources" (list $helmHooks $commonAnn)) | trim | nindent 4 }}
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: {{ template "eric-data-document-database-pg.name" . }}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app.kubernetes.io/name: {{ template "eric-data-document-database-pg.name" . }}
    - podSelector:
        matchLabels:
          app: {{ template "eric-data-document-database-pg.name" . }}-backup-pgdata
    - podSelector:
        matchLabels:
          app: {{ template "eric-data-document-database-pg.name" . }}-restore-pgdata
    - podSelector:
        matchLabels:
          {{ template "eric-data-document-database-pg.name" . }}-access: "true"
    - podSelector:
        matchLabels:
          app.kubernetes.io/name: {{ default "eric-pm-server" .Values.metrics.hostname }}
{{- include "eric-data-document-database-pg.networkPolicy.matchLabels" . | indent 4 }}
    ports:
    - port: 8083
      protocol: TCP
    - port: {{ .Values.service.port }}
      protocol: TCP
{{- if .Values.metrics.enabled }}
    - port: {{ .Values.metrics.service.port }}
      protocol: TCP
{{- end }}
{{- end -}}
{{- end }}


{{- define "eric-data-document-database-pg.upgradeHookPVC" }}
{{- if or .Release.IsUpgrade .Release.IsInstall }}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ template "eric-data-document-database-pg.name" . }}-backup-pgdata
  labels:
    {{- $pvcLabels := dict -}}
    {{- $_ := set $pvcLabels "app" (include "eric-data-document-database-pg.name" .) -}}
    {{- $_ := set $pvcLabels "release" .Release.Name -}}
    {{- $_ := set $pvcLabels "cluster-name" (include "eric-data-document-database-pg.name" .) -}}
    {{- /*TODO: support overriding of heritage: Tiller ?*/ -}}
    {{- $_ := set $pvcLabels "heritage" "Tiller" -}} {{- /* workaround after migrate from helm2 to helm3. Avoid upgrade fail. ADPPRG-26626 */ -}}
    {{- $_ := set $pvcLabels "app.kubernetes.io/instance" .Release.Name -}}
    {{- $commonLabels := fromYaml (include "eric-data-document-database-pg.labels" .) -}}
    {{- include "eric-data-document-database-pg.mergeLabels" (dict "location" .Template.Name "sources" (list $commonLabels $pvcLabels)) | trim | nindent 4 }}
  annotations:
    {{- $pvcAnnotations := dict -}}
    {{- $_ := set $pvcAnnotations "helm.sh/hook" "pre-upgrade" -}}
    {{- $_ := set $pvcAnnotations "helm.sh/hook-delete-policy" "before-hook-creation" -}}
    {{- $_ := set $pvcAnnotations "helm.sh/hook-weight" "-5" -}}
    {{- $commonAnn := fromYaml (include "eric-data-document-database-pg.annotations" .) -}}
    {{- include "eric-data-document-database-pg.mergeAnnotations" (dict "location" .Template.Name "sources" (list $commonAnn $pvcAnnotations)) | nindent 8 }}
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: {{ template "eric-data-document-database-pg.persistentVolumeClaim.size" . }}
  storageClassName: {{ template "eric-data-document-database-pg.persistentVolumeClaim.defaultStorageClassName" . }}
{{- end }}
{{- end }}

{{/*
check if a default value of max_slot_wal_keep_size needs to be set
*/}}
{{- define "eric-data-document-database-pg.default-maxslotwalkeepsize-needed" -}}  
  {{- if .Values.persistentVolumeClaim.housekeeping_threshold -}}
    {{- if (eq "100" (.Values.persistentVolumeClaim.housekeeping_threshold | toString) ) -}}
       {{- "false" -}}
    {{- else -}}
       {{- if (index .Values "postgresConfig") -}}
         {{- if (index .Values "postgresConfig" "max_slot_wal_keep_size") -}}
           {{- "false" -}}
         {{- else -}}
           {{- "true" -}}
         {{- end -}}
       {{- else -}}
         {{- "true" -}}
       {{- end -}}
    {{- end -}}
  {{- else -}}
     {{- "false" -}}
  {{- end -}}
{{- end -}}

{{/*
Define topologySpreadConstraints in ddb
*/}}
{{- define "eric-data-document-database-pg.topologySpreadConstraints.postgres" -}}
{{- range $index, $postgres := .Values.topologySpreadConstraints.postgres }}
- maxSkew: {{ $postgres.maxSkew }}
  topologyKey: {{ $postgres.topologyKey }}
  whenUnsatisfiable: {{ $postgres.whenUnsatisfiable }}
  labelSelector:
    matchLabels:
      app: {{ default $.Chart.Name $.Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end -}}
{{- end -}}


{{/*
Define probes in ddb
*/}}
{{- define "eric-data-document-database-pg.probes" -}}
{{- $default := .Values.probes -}}
{{- $default | toJson -}}
{{- end -}}


{{/*
Define networkpolicy know services
*/}}
{{- define "eric-data-document-database-pg.networkPolicy.matchLabels" -}}
{{- range $index, $label := .Values.networkPolicy.matchLabels }}
- podSelector:
    matchLabels:
      app.kubernetes.io/name: {{ $label }}
{{- end -}}
{{- end -}}

{{/*
Define a helper that determines if PG migration is required by looking at the first PG pod in the cluster and checking
the postgres version it currently is using.
*/}}
{{- define "eric-data-document-database-pg.isMigrationRequired" -}}
{{- $foundPodInCluster := false }}
{{- $foundVersionKeyFromCluster := false -}}
{{- $versionKeyFromClusterIsLatest := false -}}

{{- $foundStatefulSetMetadataInCluster := (lookup "apps/v1" "StatefulSet" .Release.Namespace (include "eric-data-document-database-pg.name"  .) ).metadata -}}
{{- if $foundStatefulSetMetadataInCluster -}}
  {{- if $foundStatefulSetMetadataInCluster.annotations -}}
    {{- if $foundStatefulSetMetadataInCluster.annotations.currentPGVersion -}}
      {{- $foundVersionKeyFromCluster = true -}}
      {{- if eq ("13" | toString) $foundStatefulSetMetadataInCluster.annotations.currentPGVersion -}}
        {{- $versionKeyFromClusterIsLatest = true -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- else -}}
  {{- $foundPodInCluster = (lookup "v1" "Pod" .Release.Namespace (printf "%s-%s" (include "eric-data-document-database-pg.name" . ) "0")) -}}
  {{- if $foundPodInCluster -}}
      {{- range $container := $foundPodInCluster.spec.containers -}}
          {{- range $env := $container.env -}}
              {{- if eq $env.name "TARGET_PG_VERSION" -}}
                  {{- $foundVersionKeyFromCluster = true -}}
                  {{- if eq ($env.value | toString) ("13" | toString) -}}
                      {{- $versionKeyFromClusterIsLatest = true -}}
                  {{- end -}}
              {{- end -}}
          {{- end -}}
      {{- end -}}
  {{- end -}}
{{- end -}}

{{- if and (or $foundPodInCluster $foundStatefulSetMetadataInCluster) (or (not $foundVersionKeyFromCluster) (not $versionKeyFromClusterIsLatest)) -}}
true
{{- else -}}
false
{{- end -}}
{{- end -}}

{{/*
Define hook logshipper enabled
*/}}
{{- define "eric-data-document-database-pg.hooklog" -}} 
{{- if (eq (include "eric-data-document-database-pg.log.streamingMethod" .) "true") }}
{{- if not (eq (((((.Values).global).logShipper).config).hookEnabled | toString) "false") -}}
true
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create a pod service account name.
*/}}
{{- define "eric-data-document-database-pg.bePostgresServiceAccountName" -}}
{{- printf "%s-be-%s" (printf "%s-%v" (include "eric-data-document-database-pg.name" .) "pod") ( .Release.Namespace | sha256sum | substr 0 5 | lower) -}}
{{- end -}}

{{/*
Create a service account name.
*/}}
{{- define "eric-data-document-database-pg.beServiceAccountName" -}}
{{- printf "%s-be" (include "eric-data-document-database-pg.name" .) -}}
{{- end -}}

{{/*
check operator enable
*/}}
{{- define "eric-data-document-database-pg.operator-enabled" -}}
{{- $g := fromJson (include "eric-data-document-database-pg.global" .) -}}
{{- if $g.documentDatabasePG.operator.enabled -}}
  {{- "true" -}}
{{- else -}}
{{- if $g.documentDatabasePg -}}
  {{- if $g.documentDatabasePg.operator -}}
      {{- if $g.documentDatabasePg.operator.enabled -}}
        {{- "true" -}}
      {{- else -}}
        {{- "false" -}}
      {{- end -}}
  {{- else -}}
    {{- "false" -}}
  {{- end -}}
{{- else -}}
  {{- "false" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
check load legecy template enable
*/}}
{{- define "eric-data-document-database-pg.load-legecy-template-enabled" -}}
{{- $load_legecy_template_switch := "true" -}}
{{- if (eq (include "eric-data-document-database-pg.operator-enabled" .) "true") }}
{{- $load_legecy_template_switch = printf "%s" (default false ((.Values).operator).loadTemplate | toString ) -}}
{{- end -}}
{{- printf "%s" $load_legecy_template_switch -}}
{{- end -}}


{{/*
  resource will render only by FE operator if true.
*/}}
{{- define "eric-data-document-database-pg.fe-render" -}}
{{- if and (eq (include "eric-data-document-database-pg.operator-enabled" .) "true") (eq (((.Values).operator).loadTemplate | toString ) "true") -}}
{{- "true"  -}}
{{- else -}}
{{- "false"  -}}
{{- end -}}
{{- end -}}


{{- define "eric-data-document-database-pg.ls-default" -}}
  {{- $default := dict "logshipperSidecarImage" ((((.Values).global).logShipper).config).image -}}
  {{- $defaultName := include "eric-data-document-database-pg.name" . -}}
  {{- $name := default $defaultName .customName -}}
  {{- $logShipperDefaultFiles := list -}}
  {{- $logShipperDefaultFile := dict }}
  {{- $logShipperDefaultFile := merge $logShipperDefaultFile (dict "enabled" true ) -}}
  {{- if (eq (include "eric-data-document-database-pg.operator-enabled" .) "true") }}
   {{- $logShipperDefaultFile := merge $logShipperDefaultFile (dict "paths" (list (printf "%s.log" "postgres") (printf "%s-metrics.log" $name) (printf "%s-bra.log" $name) (printf "%s-brm.log" $name) (printf "%s-hook.log" $name) (printf "%s-feoperator.log" $name) (printf "%s-beoperator.log" $name))) -}}
   {{- else -}}
   {{- $logShipperDefaultFile := merge $logShipperDefaultFile (dict "paths" (list (printf "%s.log" $name) (printf "%s-metrics.log" $name) (printf "%s-bra.log" $name) (printf "%s-brm.log" $name) (printf "%s-hook.log" $name) (printf "%s-feoperator.log" $name) (printf "%s-beoperator.log" $name))) -}}
  {{- end -}}
  {{- $logShipperDefaultFile := merge $logShipperDefaultFile (dict "parsers" (list "json")) -}}
  {{- $logShipperDefaultFiles := append $logShipperDefaultFiles $logShipperDefaultFile -}}
  {{- $default := merge $default (dict "Values" (dict "logShipper" (dict "input" (dict "files" $logShipperDefaultFiles )))) }}
  {{- if (((.Values).logShipper).input).files -}}
  {{- $logShipperCustomFile := dict }}
  {{- $_ := set $logShipperCustomFile "files" (((.Values).logShipper).input).files -}}
  {{- $default := mergeOverwrite $default (dict "Values" (dict "logShipper" (dict "input" $logShipperCustomFile ))) }}
  {{- end -}}
  {{- if ((.Values).logShipper).parsers -}}
  {{- $logShipperCustomParser := dict }}
  {{- $_ := set $logShipperCustomParser "parsers" ((.Values).logShipper).parsers -}}
  {{- $default := mergeOverwrite $default (dict "Values" (dict "logShipper" $logShipperCustomParser )) }}
  {{- end -}}
  {{- $default := mergeOverwrite $default .Values -}}
  {{- $default | toJson -}}
{{- end -}}

{{- define "eric-data-document-database-pg.ls-values" -}}
  {{- $logshipperDefault := fromJson (include "eric-data-document-database-pg.ls-default" .) -}}
  {{- $default := dict -}}
  {{- $default := merge $default $logshipperDefault -}}
  {{- if eq (include "eric-data-document-database-pg.load-legecy-template-enabled" .) "false" }}
      {{- $op_resource_name := include "eric-data-document-database-pg.name" . -}}
      {{- if .Values.fullnameOverride -}}
        {{- $op_resource_name = .Values.fullnameOverride -}}
      {{- end -}}
      {{- $op_resource_name = printf "op-%s" $op_resource_name -}}
      {{- $default := merge $default (dict "Values" (dict "fullnameOverride" $op_resource_name )) -}}
  {{- end -}}
  {{- $default | toJson -}}
{{- end -}}

{{- define "eric-data-document-database-pg.ls-template-values" -}}
  {{- $pg_ls_tempalte_name := include "eric-data-document-database-pg.name" . -}}
  {{- $pg_ls_tempalte_name = printf "tpl-%s-tpl" $pg_ls_tempalte_name -}}
  {{- $logshipperDefault := fromJson (include "eric-data-document-database-pg.ls-default" . ) -}}
  {{- $logshipperDefault := (mergeOverwrite $logshipperDefault (dict "customName" $pg_ls_tempalte_name)) -}}
  {{- $default := dict -}}
  {{- $default := merge $default $logshipperDefault -}}
  {{- $default := merge $default (dict "Values" (dict "fullnameOverride" $pg_ls_tempalte_name )) -}}
  {{- $default | toJson -}}
{{- end -}}

{{/*
Define fe LogLevel
*/}}
{{- define "eric-data-document-database-pg.feLogLevel" -}}
{{- if ((((.Values).operator).fe).log).logLevel -}}
{{- printf "%s" ((((.Values).operator).fe).log).logLevel -}}
{{- else -}}
{{- printf "info" -}}
{{- end -}}
{{- end -}}

{{/*
Define fe LogDynamic
*/}}
{{- define "eric-data-document-database-pg.feLogDynamic" -}}
{{- if eq (((((.Values).operator).fe).log).logadpjson | toString) "false" -}}
false
{{- else -}}
true
{{- end -}}
{{- end -}}

{{/*
Define fe LogAdpJson
*/}}
{{- define "eric-data-document-database-pg.feLogAdpJson" -}}
{{- if not (eq (((((.Values).operator).fe).log).logadpjson | toString) "false") -}}
true
{{- else -}}
false
{{- end -}}
{{- end -}}

{{/*
Define podSecurityContext.supplementalGroups
*/}}
{{- define "eric-data-document-database-pg.podSecurityContext.supplementalGroups" -}}
    {{- $gsupplementalGroups := list -}}
    {{- $lsupplementalGroups := list -}}
    {{- $newsupplementalGroups := list -}}
    {{- if .Values.global -}}
        {{- if .Values.global.podSecurityContext -}}
            {{- if .Values.global.podSecurityContext.supplementalGroups -}}
                {{- $gsupplementalGroups = .Values.global.podSecurityContext.supplementalGroups -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.podSecurityContext -}}
        {{- if .Values.podSecurityContext.supplementalGroups -}}
        {{- $lsupplementalGroups = .Values.podSecurityContext.supplementalGroups -}}
        {{- end -}}
    {{- end -}}
       {{- if $gsupplementalGroups -}}
        {{- range $key, $value := $gsupplementalGroups }}
        {{- $newsupplementalGroups = append $newsupplementalGroups $value -}}
       {{- end }}
       {{- end }}
      {{- if $lsupplementalGroups -}}
       {{- range $key, $value := $lsupplementalGroups }}
         {{- $newsupplementalGroups = append $newsupplementalGroups $value -}}
       {{- end }}
       {{- end }}
   {{- if or $gsupplementalGroups $lsupplementalGroups -}}
   {{- printf "supplementalGroups: %s" (toJson (uniq $newsupplementalGroups)) -}}
   {{- else -}}
   {{- print "" -}}
   {{- end -}}   
{{- end -}}

{{/*
Define LogShipper deployment model: static or dynamic
*/}}
{{- define "eric-data-document-database-pg.logStatic" -}}
  {{- if eq (default "" ((((.Values).global).logShipper).deployment).model) "static" -}}
    {{- if eq (include "eric-data-document-database-pg.operator-enabled" .) "true" -}}
      {{- "true" -}}
    {{- else -}}
      {{- "false" -}}
    {{- end -}}
  {{- else -}}
    {{- "false" -}}
  {{- end -}}
{{- end -}}

{{/*
Define LogShipper resources: container, mounts, volumes
*/}}
{{- define "eric-data-document-database-pg.log.containers" -}}
  {{- if (eq (include "eric-data-document-database-pg.log.streamingMethod" .) "true") }}
    {{- if (eq (include "eric-data-document-database-pg.logStatic" .) "true") }}
    {{- include "eric-data-document-database-pg.log-shipper-sidecar-container" . }}
    {{- else }}
    {{- include "eric-log-shipper-sidecar.log-shipper-sidecar-container" . }}
    {{- end }}
  {{- end }}
{{- end -}}

{{- define "eric-data-document-database-pg.log.containers-hooks" -}}
  {{- if (eq (include "eric-data-document-database-pg.hooklog" .) "true") }}
    {{- if (eq (include "eric-data-document-database-pg.logStatic" .) "true") }}
    {{- include "eric-data-document-database-pg.log-shipper-sidecar-container-for-hooks" . }}
    {{- else }}
    {{- include "eric-log-shipper-sidecar.log-shipper-sidecar-container-for-hooks" . }}
    {{- end }}
  {{- end }}
{{- end -}}

{{- define "eric-data-document-database-pg.log.mounts" -}}
  {{- if (eq (include "eric-data-document-database-pg.log.streamingMethod" .) "true") }}
    {{- if (eq (include "eric-data-document-database-pg.logStatic" .) "true") }}
    {{- include "eric-data-document-database-pg.log-shipper-sidecar-mounts" . }}
    {{- else }}
    {{- include "eric-log-shipper-sidecar.log-shipper-sidecar-mounts" . }}
    {{- end }}
  {{- end }}
{{- end -}}

{{- define "eric-data-document-database-pg.log.mounts-hooks" -}}
  {{- if (eq (include "eric-data-document-database-pg.hooklog" .) "true") }}
    {{- if (eq (include "eric-data-document-database-pg.logStatic" .) "true") }}
    {{- include "eric-data-document-database-pg.log-shipper-sidecar-mounts" . }}
    {{- else }}
    {{- include "eric-log-shipper-sidecar.log-shipper-sidecar-mounts" . }}
    {{- end }}
  {{- end }}
{{- end -}}

{{- define "eric-data-document-database-pg.log.volumes" -}}
  {{- if (eq (include "eric-data-document-database-pg.log.streamingMethod" .) "true") }}
    {{- if (eq (include "eric-data-document-database-pg.logStatic" .) "true") }}
    {{- include "eric-data-document-database-pg.log-shipper-sidecar-volumes" . }}
    {{- else }}
    {{- include "eric-log-shipper-sidecar.log-shipper-sidecar-volumes" . }}
    {{- end }}
  {{- end }}
{{- end -}}

{{- define "eric-data-document-database-pg.log.volumes-hooks" -}}
  {{- if (eq (include "eric-data-document-database-pg.hooklog" .) "true") }}
    {{- if (eq (include "eric-data-document-database-pg.logStatic" .) "true") }}
    {{- include "eric-data-document-database-pg.log-shipper-sidecar-volumes-for-hooks" . }}
    {{- else }}
    {{- include "eric-log-shipper-sidecar.log-shipper-sidecar-volumes-for-hooks" . }}
    {{- end }}
  {{- end }}
{{- end -}}

{{- define "eric-data-document-database-pg.metricsPortName" -}}
  {{- if .Values.enableNewScrapePattern }}
    {{- if and (not (eq (include "eric-data-document-database-pg.global-security-tls-enabled" .) "false")) (eq .Values.service.endpoints.postgresExporter.tls.enforced "required") }}
    {{- print "https-metrics" -}}
    {{- else }}
    {{- print "http-metrics" -}}
    {{- end }}
  {{- else }}
    {{- if and (not (eq (include "eric-data-document-database-pg.global-security-tls-enabled" .) "false")) (eq .Values.service.endpoints.postgresExporter.tls.enforced "required") }}
    {{- print "metrics-tls" -}}
    {{- else }}
    {{- print "metrics" -}}
    {{- end }}
  {{- end }}
{{- end -}}