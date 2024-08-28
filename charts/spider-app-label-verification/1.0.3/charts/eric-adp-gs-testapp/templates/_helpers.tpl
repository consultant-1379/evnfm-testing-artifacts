{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{/* DR-HC-061 */}}
{{- define "eric-adp-gs-testapp.name" -}}
{{- if .Values.nameOverride -}}
{{- .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name -}}
{{- printf "%s" $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Connection to dataCoordinator messageBusKf root
*/}}
{{- define "eric-adp-gs-testapp.dataCoordinator.connect" -}}
{{- printf "%s:%s/%s" .Values.dataCoordinator.hostname  .Values.dataCoordinator.port .Values.kafka.hostname -}}
{{- end -}}