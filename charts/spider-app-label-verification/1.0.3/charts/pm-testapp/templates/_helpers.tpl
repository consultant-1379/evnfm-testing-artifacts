{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "pm-testapp.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "pm-testapp.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name "pm-testapp" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pm-testapp.host" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s.%s" .Release.Name .Values.ingress.domain | trunc 63 | trimSuffix "-" -}}
{{- end -}}