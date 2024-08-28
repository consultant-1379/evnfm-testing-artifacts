{{- define "eric-ctrl-bro.hkln.rbac" -}}

{{- $helmHook := dict -}}
{{- $_ := set $helmHook "helm.sh/hook" "pre-install,pre-upgrade,pre-rollback,pre-delete" -}}
{{- $_ := set $helmHook "helm.sh/hook-weight" "-202" -}} {{- /* Must run before any hooklauncher job !!! */ -}}
{{- $commonAnn := fromYaml (include "eric-ctrl-bro.hkln.annotations" .shh) -}}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ template "eric-ctrl-bro.hkln.name" .top }}
  labels:
    {{- include "eric-ctrl-bro.hkln.labels" .shh | nindent 4 }}
  annotations:
    {{- include "eric-ctrl-bro.mergeAnnotations" (dict "location" .shh.Template.Name "sources" (list $helmHook $commonAnn)) | trim | nindent 4 }}
rules:
  - apiGroups: ["batch"]
    resources: ["jobs"]
    verbs: ["create", "delete", "get"]
  - apiGroups: ["batch"]
    resources: ["jobs/status"]
    verbs: ["get"]
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["create"]
  - apiGroups: [""]
    resources: ["secrets"]
    resourceNames: [
      {{- $secretNames := list -}}
      {{ range $subChartName, $subChartInfo := (include "eric-ctrl-bro.hkln.chartInfo" .top | fromYaml) -}}
      {{ $secretNames = append $secretNames ($subChartInfo.jobInventorySecret | quote) }}
      {{- end }}
      {{ join ", " $secretNames }}
    ]
    verbs: ["get"]
  - apiGroups: [""]
    resources: ["secrets"]
    resourceNames: [
      {{- $secretNames := list -}}
      {{ range $subChartName, $subChartInfo := (include "eric-ctrl-bro.hkln.chartInfo" .top | fromYaml) -}}
      {{ $secretNames = append $secretNames (printf "%s-stashed" $subChartInfo.jobInventorySecret | quote) }}
      {{- end }}
      {{ join ", " $secretNames }}
    ]
    verbs: ["get", "update", "delete"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: {{ template "eric-ctrl-bro.hkln.name" .top }}
  labels:
    {{- include "eric-ctrl-bro.hkln.labels" .shh | nindent 4 }}
  annotations:
    {{- include "eric-ctrl-bro.mergeAnnotations" (dict "location" .shh.Template.Name "sources" (list $helmHook $commonAnn)) | trim | nindent 4 }}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: {{ template "eric-ctrl-bro.hkln.name" .top }}
subjects:
  - namespace: {{ .shh.Release.Namespace }}
    kind: ServiceAccount
    name: {{ template "eric-ctrl-bro.hkln.name" .top }}

---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ template "eric-ctrl-bro.hkln.name" .top }}
  labels:
    {{- include "eric-ctrl-bro.hkln.labels" .shh | nindent 4 }}
  annotations:
    {{- include "eric-ctrl-bro.mergeAnnotations" (dict "location" .shh.Template.Name "sources" (list $helmHook $commonAnn)) | trim | nindent 4 }}

---
{{- $rolename := include "eric-ctrl-bro.hkln.securityPolicy.rolename" .shh -}}
{{- $rolekind := include "eric-ctrl-bro.hkln.securityPolicy.rolekind" .shh -}}
{{- if and (ne ($rolekind) "") (ne $rolename "eric-lcm-smart-helm-hooks") }}
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: {{ template "eric-ctrl-bro.hkln.securityPolicy-rolebinding-name" . }}
  labels:
    {{- include "eric-ctrl-bro.hkln.labels" .shh | nindent 4 }}
  annotations:
    {{- include "eric-ctrl-bro.mergeAnnotations" (dict "location" .shh.Template.Name "sources" (list $helmHook $commonAnn)) | trim | nindent 4 }}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: {{ $rolekind }}
  name: {{ $rolename }}
subjects:
- kind: ServiceAccount
  name: {{ template "eric-ctrl-bro.hkln.name" .top }}
{{- else if .top.Values.global -}}
  {{- if .top.Values.global.security -}}
    {{- if .top.Values.global.security.policyBinding -}}
      {{- if .top.Values.global.security.policyBinding.create -}}
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: {{ template "eric-ctrl-bro.hkln.name" .top }}-security-policy
  labels:
    {{- include "eric-ctrl-bro.hkln.labels" .shh | nindent 4 }}
  annotations:
    {{- include "eric-ctrl-bro.mergeAnnotations" (dict "location" .shh.Template.Name "sources" (list $helmHook $commonAnn)) | trim | nindent 4 }}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: {{ include "eric-ctrl-bro.hkln.securityPolicy.reference" .shh }}
subjects:
- kind: ServiceAccount
  name: {{ template "eric-ctrl-bro.hkln.name" .top }}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end }}

{{- end -}}
