{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "busybox-simple-chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* vim: set filetype=mustache: */}}
{{/*
Print the original name of the chart.
*/}}
{{- define "{{.Chart.Name}}.print" -}}
{{- print .Chart.Name -}}
{{- end -}}
