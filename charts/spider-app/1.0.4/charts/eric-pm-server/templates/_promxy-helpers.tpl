{{/* vim: set filetype=mustache: */}}

{{/*
Expand the name of the promxy deployment
*/}}
{{- define "eric-pm-server.promxyName" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-promxy" $name }}
{{- end -}}

{{/*
Return the right port to communicate with PMS
*/}}
{{- define "eric-pm-server.promxyPort" -}}
{{- $g := fromJson (include "eric-pm-server.global" .) -}}
{{- if $g.security.tls.enabled }}
{{- .Values.server.service.httpsPort }}
{{- else }}
{{- .Values.server.service.httpPort }}
{{- end }}
{{- end -}}

{{/*
Selector labels.
*/}}
{{- define "eric-pm-server.promxySelectorLabels" -}}
component: {{ .Values.server.name | quote }}
app: {{ template "eric-pm-server.promxyName" . }}
release: {{ .Release.Name | quote }}
{{- if eq (include "eric-pm-server.promxyNeedInstanceLabelSelector" .) "true" }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- end -}}
{{- end }}

{{- define "eric-pm-server.promxyNeedInstanceLabelSelector" }}
    {{- $needInstanceLabelSelector := false -}}
    {{- if .Release.IsInstall }}
        {{- $needInstanceLabelSelector = true -}}
    {{- else if .Release.IsUpgrade }}
        {{- $promxy := (lookup "apps/v1" "Deployment" .Release.Namespace (include "eric-pm-server.promxyName" .)) -}}
        {{- if $promxy -}}
            {{- if hasKey $promxy.spec.selector.matchLabels "app.kubernetes.io/instance" -}}
                {{- $needInstanceLabelSelector = true -}}
            {{- end -}}
        {{- else -}}
                {{- $needInstanceLabelSelector = true -}}
        {{- end -}}
    {{- end -}}
    {{- $needInstanceLabelSelector -}}
{{- end }}

{{/*
promxy labels.
*/}}
{{- define "eric-pm-server.promxyLabels" -}}
  {{- $g := fromJson (include "eric-pm-server.global" .) -}}
  {{- $selector := include "eric-pm-server.promxySelectorLabels" . | fromYaml -}}
  {{- $name := (include "eric-pm-server.promxyName" . ) }}
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
promxy labels for Network Policies
*/}}
{{- define "eric-pm-server.promxyPeer.labels" -}}
{{- if (eq "true" (include "eric-pm-server.logShipperEnabled" .)) }}
{{ .Values.logShipper.output.logTransformer.host }}-access: "true"
{{- end }}
{{ template "eric-pm-server.name" . }}-access: "true"
{{- end -}}

{{/*
Defins the name of config map
*/}}
{{- define "eric-pm-server.promxyConfigmap" -}}
{{- if .Values.promxy.configMapOverrideName -}}
{{- .Values.promxy.configMapOverrideName -}}
{{- else -}}
{{- include "eric-pm-server.promxyName" . -}}
{{- end -}}
{{- end -}}


{{/*
Define pod tolerations
*/}}
{{- define "eric-pm-server.promxyTolerations" }}
{{- if (include "eric-pm-server.merge-tolerations" (dict "root" . "podbasename" "eric-pm-server-promxy")) }}
tolerations:
{{- include "eric-pm-server.merge-tolerations" (dict "root" . "podbasename" "eric-pm-server-promxy") | nindent 2 }}
{{- end }}
{{- end }}

{{- define "eric-pm-server.prometheusAnnotations" -}}
{{- $g := fromJson (include "eric-pm-server.global" .) -}}
{{- if $g.security.tls.enabled }}
prometheus.io/path2: {{ .Values.promxy.metricPath | quote}}
prometheus.io/scrape: "true"
prometheus.io/port: "9084"
prometheus.io/scheme: "https"
{{- else }}
prometheus.io/path: {{ .Values.promxy.metricPath | quote}}
prometheus.io/scrape: "true"
prometheus.io/port: "8082"
prometheus.io/scheme: "http"
{{- end }}
{{- end }}

{{- define "eric-pm-server.promxyServiceAccount" -}}
{{- if .Values.promxy.dynamicDiscovery.enabled }}
{{- default (include "eric-pm-server.promxyName" .) .Values.promxy.serviceAccountName }}
{{- else }}
{{- printf "%s" "default" }}
{{- end }}
{{- end }}

{{/*
Create topologySpreadConstraints for eric-pm-server-promxy
*/}}
{{- define "eric-pm-server.eric-pm-server-promxy.topologySpreadConstraints" -}}
{{- include "eric-pm-server.createTopologySpreadConstraints" (dict "component" "eric-pm-server-promxy" "name" (include "eric-pm-server.promxyName" .) "ctx" .) -}}
{{- end -}}

{{/*
Create a merged set of nodeSelectors from global and service level.
*/}}
{{ define "eric-pm-server.eric-pm-server-promxy.nodeSelector" }}
  {{- $g := fromJson (include "eric-pm-server.global" .) -}}

  {{- $global := $g.nodeSelector -}}

  {{- $service := fromJson (include "eric-pm-server.removeNonStringValues" (index .Values.nodeSelector "eric-pm-server-promxy")) -}}

  {{- $context := "eric-pm-server-promxy.nodeSelector" -}}
  {{- include "eric-pm-server.aggregatedMerge" (dict "context" $context "location" .Template.Name "sources" (list $service $global)) | trim -}}
{{ end }}

{{- define "eric-pm-server.eric-pm-server-promxy.securityPolicy.rolename" -}}
{{- if (eq (index .Values.securityPolicy "eric-pm-server-promxy" "rolename") (include "eric-pm-server.promxyName" . )) -}}
{{- printf "'%s' cannot be used as role name." (include "eric-pm-server.promxyName" . ) | fail -}}
{{- else -}}
{{- default "eric-pm-server-promxy-sp" (index .Values.securityPolicy "eric-pm-server-promxy" "rolename") -}}
{{- end -}}
{{- end -}}

{{- define "eric-pm-server.eric-pm-server-promxy.securityPolicy.rolebinding.name" -}}
{{- if (eq (include "eric-pm-server.securityPolicy.rolekind" .) "Role") }}
{{- print (include "eric-pm-server.promxyName" . ) "-r-" (include "eric-pm-server.eric-pm-server-promxy.securityPolicy.rolename" . ) "-sp" -}}
{{- else if (eq (include "eric-pm-server.securityPolicy.rolekind" .) "ClusterRole") }}
{{- print (include "eric-pm-server.promxyName" . ) "-c-" (include "eric-pm-server.eric-pm-server-promxy.securityPolicy.rolename" . ) "-sp" -}}
{{- end }}
{{- end -}}
