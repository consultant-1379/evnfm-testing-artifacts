# Chart name
{{- define "spider-app.chart" -}}
  {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

# Chart simple name
{{- define "spider-app.name" -}}
  {{- printf "%s" .Chart.Name | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

# Alarm Handler is enabled
{{- define "alarm.enabled" -}}
  {{- if (index .Values "eric-fh-alarm-handler") -}}
    {{- if eq (index .Values "eric-fh-alarm-handler" "enabled" | quote) "\"false\"" -}}
        false
    {{- else -}}
        true
    {{- end -}}
  {{- else -}}
    false
  {{- end -}}
{{- end -}}

# CM YANG Provider is enabled
{{- define "cm-yang.enabled" -}}
  {{- if and (index .Values "eric-cm-yang-provider") -}}
    {{- if eq (index .Values "eric-cm-yang-provider" "enabled" | quote) "\"false\"" -}}
        false
    {{- else -}}
        true
    {{- end -}}
  {{- else -}}
    false
  {{- end -}}
{{- end -}}

# snmp Alarm provider is enabled
{{- define "alarm-provider.enabled" -}}
  {{- if and (index .Values "eric-fh-snmp-alarm-provider") -}}
    {{- if eq (index .Values "eric-fh-snmp-alarm-provider" "enabled" | quote) "\"false\"" -}}
        false
    {{- else -}}
        true
    {{- end -}}
  {{- else -}}
    false
  {{- end -}}
{{- end -}}

# KVDB is enabled
{{- define "kvdb.enabled" -}}
  {{- if and (index .Values "eric-data-kvdb-ag") -}}
    {{- if eq (index .Values "eric-data-kvdb-ag" "enabled" | quote) "\"false\"" -}}
        false
    {{- else -}}
        true
    {{- end -}}
  {{- else -}}
    false
  {{- end -}}
{{- end -}}

# ETCD is enabled
{{- define "etcd.enabled" -}}
  {{- if and (index .Values "eric-data-distributed-coordinator-ed") -}}
    {{- if eq (index .Values "eric-data-distributed-coordinator-ed" "enabled" | quote) "\"false\"" -}}
        false
    {{- else -}}
        true
    {{- end -}}
  {{- else -}}
    false
  {{- end -}}
{{- end -}}

# DDC is enabled
{{- define "ddc.enabled" -}}
  {{- if and (index .Values "eric-odca-diagnostic-data-collector") -}}
    {{- if eq (index .Values "eric-odca-diagnostic-data-collector" "enabled" | quote) "\"false\"" -}}
        false
    {{- else -}}
        true
    {{- end -}}
  {{- else -}}
    false
  {{- end -}}
{{- end -}}

# Backup and Restore is enabled
{{- define "bro.enabled" -}}
  {{- if and (index .Values "eric-ctrl-bro") -}}
    {{- if eq (index .Values "eric-ctrl-bro" "enabled" | quote) "\"false\"" -}}
        false
    {{- else -}}
        true
    {{- end -}}
  {{- else -}}
    false
  {{- end -}}
{{- end -}}

# Container Registry is enabled
{{- define "container-registry.enabled" -}}
  {{- if and (index .Values "eric-lcm-container-registry") -}}
    {{- if eq (index .Values "eric-lcm-container-registry" "enabled" | quote) "\"false\"" -}}
        false
    {{- else -}}
        true
    {{- end -}}
  {{- else -}}
    false
  {{- end -}}
{{- end -}}

{{/*
Create Ericsson Product Info
*/}}
{{- define "spider-app.helm-annotations" -}}
ericsson.com/product-name: "spider-app"
ericsson.com/product-number: "xxxxxxx/1"
ericsson.com/product-revision: "R1A"
{{- end}}

{{/*
Create Ericsson product app.kubernetes.io info
*/}}
{{- define "spider-app.kubernetes-io-info" -}}
app.kubernetes.io/name: {{ .Chart.Name | quote }}
app.kubernetes.io/version: {{ .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- end -}}

