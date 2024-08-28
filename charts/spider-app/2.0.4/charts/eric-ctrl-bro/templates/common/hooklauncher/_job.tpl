{{- define "eric-ctrl-bro.hkln.job" -}}
{{- $containerName := include "eric-ctrl-bro.hkln.containerName" .root.shh -}}
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ template "eric-ctrl-bro.hkln.name" .root.top }}-{{ .suffix }}
  labels:
    {{- include "eric-ctrl-bro.hkln.labels" .root.shh | nindent 4 }}
  annotations:
    {{- $helmHook := dict -}}
    {{- $_ := set $helmHook "helm.sh/hook" .helmHook -}}
    {{- $_ := set $helmHook "helm.sh/hook-weight" .weight -}}
    {{- $_ := set $helmHook "helm.sh/hook-delete-policy" "before-hook-creation,hook-succeeded" -}}
    {{- $commonAnn := fromYaml (include "eric-ctrl-bro.hkln.annotations" .root.shh) -}}
    {{- include "eric-ctrl-bro.mergeAnnotations" (dict "location" .root.shh.Template.Name "sources" (list $helmHook $commonAnn)) | trim | nindent 4 }}
spec:
  template:
    metadata:
      labels:
        {{- include "eric-ctrl-bro.hkln.labels" .root.shh | nindent 8 }}
      annotations:
        {{- $appArmorAnn := include "eric-ctrl-bro.hkln.appArmorProfileAnn" (dict "root" .root.shh "containerName" $containerName) | fromYaml -}}
        {{- $commonAnn := fromYaml (include "eric-ctrl-bro.hkln.annotations" .root.shh) -}}
        {{- include "eric-ctrl-bro.mergeAnnotations" (dict "location" .root.shh.Template.Name "sources" (list $appArmorAnn $commonAnn)) | trim | nindent 8 }}
    spec:
      {{- if include "eric-ctrl-bro.hkln.pullSecrets" .root.shh }}
      imagePullSecrets:
        - name: {{ template "eric-ctrl-bro.hkln.pullSecrets" .root.shh }}
      {{- end }}
      containers:
        - name: {{ $containerName }}
          image: {{ include "eric-ctrl-bro.hkln.image-path" .root.shh }}
          env:
            - name: TZ
              value: {{ include "eric-ctrl-bro.hkln.timezone" .root.shh }}
          args: [
            "/hooklauncher/hooklauncher",
            "--namespace", {{ .root.shh.Release.Namespace | quote }},

            {{- $chartInfo := include "eric-ctrl-bro.hkln.chartInfo" .root.top | fromYaml -}}
            {{- range $subChartName, $subChartInfo := $chartInfo }}
            "--job-inventory-secret",
            {{ $subChartInfo.jobInventorySecret | quote }},
            "--this-version",
            {{ $subChartInfo.version | quote }},
            {{- end }}
            "--instance", {{ include "eric-ctrl-bro.hkln.name" .root.top | quote }},
            "--this-job", {{ include "eric-ctrl-bro.hkln.name" .root.top }}-{{ .suffix }},
            "--trigger", {{ .trigger | quote }},
            "--cleanup", {{ include "eric-ctrl-bro.hkln.cleanup" .root.shh | quote }},
            "--terminate-early={{ template "eric-ctrl-bro.hkln.terminateEarlyOnFailure" .root.shh }}",
            "--incluster"
          ]
          imagePullPolicy: {{ template "eric-ctrl-bro.hkln.imagePullPolicy" .root.shh }}
          {{- if include "eric-ctrl-bro.hkln.resources" .root.shh }}
          resources:
            {{- include "eric-ctrl-bro.hkln.resources" .root.shh | trim | nindent 12 }}
          {{- end }}
          securityContext:
            allowPrivilegeEscalation: false
            privileged: false
            readOnlyRootFilesystem: true
            runAsNonRoot: true
            capabilities:
              drop:
                - ALL
            {{- if include "eric-ctrl-bro.hkln.seccompProfile" (dict "root" .root.shh "Scope" $containerName) }}
            seccompProfile:
              {{- include "eric-ctrl-bro.hkln.seccompProfile" (dict "root" .root.shh "Scope" $containerName) | trim | nindent 14 }}
            {{- end }}
      restartPolicy: OnFailure
      serviceAccountName: {{ template "eric-ctrl-bro.hkln.name" .root.top }}
      {{- if include "eric-ctrl-bro.hkln.priorityClassName" .root.shh }}
      priorityClassName: {{ include "eric-ctrl-bro.hkln.priorityClassName" .root.shh }}
      {{- end }}
      {{- if (include "eric-ctrl-bro.hkln.tolerations" .root.shh | fromYamlArray) }}
      tolerations: {{- include "eric-ctrl-bro.hkln.tolerations" .root.shh | nindent 8 }}
      {{- end }}
      {{- if include "eric-ctrl-bro.hkln.nodeSelector" .root.shh }}
      nodeSelector: {{- include "eric-ctrl-bro.hkln.nodeSelector" .root.shh | trim | nindent 8 }}
      {{- end }}
      {{- if include "eric-ctrl-bro.hkln.seccompProfile" (dict "root" .root.shh "Scope" "Pod") }}
      securityContext:
        seccompProfile:
          {{- include "eric-ctrl-bro.hkln.seccompProfile" (dict "root" .root.shh "Scope" "Pod") | trim | nindent 10 }}
      {{- end }}
  backoffLimit: {{ template "eric-ctrl-bro.hkln.backoffLimit" .root.shh | default 6 }}
{{- end -}}
