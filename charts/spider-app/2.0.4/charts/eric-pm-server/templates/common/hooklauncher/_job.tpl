{{- define "eric-pm-server.hkln.job" -}}
{{- $containerName := include "eric-pm-server.hkln.containerName" .root.shh -}}
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ template "eric-pm-server.hkln.name" .root.top }}-{{ .suffix }}
  labels:
    {{- include "eric-pm-server.hkln.labels" .root.shh | nindent 4 }}
  annotations:
    {{- $helmHook := dict -}}
    {{- $_ := set $helmHook "helm.sh/hook" .helmHook -}}
    {{- $_ := set $helmHook "helm.sh/hook-weight" .weight -}}
    {{- $_ := set $helmHook "helm.sh/hook-delete-policy" "before-hook-creation,hook-succeeded" -}}
    {{- $commonAnn := fromYaml (include "eric-pm-server.hkln.annotations" .root.shh) -}}
    {{- include "eric-pm-server.mergeAnnotations" (dict "location" .root.shh.Template.Name "sources" (list $helmHook $commonAnn)) | trim | nindent 4 }}
spec:
  template:
    metadata:
      labels:
        {{- include "eric-pm-server.hkln.labels" .root.shh | nindent 8 }}
      annotations:
        {{- $appArmorAnn := include "eric-pm-server.hkln.appArmorProfileAnn" (dict "root" .root.shh "containerName" $containerName) | fromYaml -}}
        {{- $commonAnn := fromYaml (include "eric-pm-server.hkln.annotations" .root.shh) -}}
        {{- include "eric-pm-server.mergeAnnotations" (dict "location" .root.shh.Template.Name "sources" (list $appArmorAnn $commonAnn)) | trim | nindent 8 }}
    spec:
      {{- if include "eric-pm-server.hkln.pullSecrets" .root.shh }}
      imagePullSecrets:
        - name: {{ template "eric-pm-server.hkln.pullSecrets" .root.shh }}
      {{- end }}
      containers:
        - name: {{ $containerName }}
          image: {{ include "eric-pm-server.hkln.image-path" .root.shh }}
          env:
            - name: TZ
              value: {{ include "eric-pm-server.hkln.timezone" .root.shh }}
          args: [
            "/hooklauncher/hooklauncher",
            "--namespace", {{ .root.shh.Release.Namespace | quote }},

            {{- $chartInfo := include "eric-pm-server.hkln.chartInfo" .root.top | fromYaml -}}
            {{- range $subChartName, $subChartInfo := $chartInfo }}
            "--job-inventory-secret",
            {{ $subChartInfo.jobInventorySecret | quote }},
            "--this-version",
            {{ $subChartInfo.version | quote }},
            {{- end }}
            "--instance", {{ include "eric-pm-server.hkln.name" .root.top | quote }},
            "--this-job", {{ include "eric-pm-server.hkln.name" .root.top }}-{{ .suffix }},
            "--trigger", {{ .trigger | quote }},
            "--cleanup", {{ include "eric-pm-server.hkln.cleanup" .root.shh | quote }},
            "--terminate-early={{ template "eric-pm-server.hkln.terminateEarlyOnFailure" .root.shh }}",
            "--incluster"
          ]
          imagePullPolicy: {{ template "eric-pm-server.hkln.imagePullPolicy" .root.shh }}
          {{- if include "eric-pm-server.hkln.resources" .root.shh }}
          resources:
            {{- include "eric-pm-server.hkln.resources" .root.shh | trim | nindent 12 }}
          {{- end }}
          securityContext:
            allowPrivilegeEscalation: false
            privileged: false
            readOnlyRootFilesystem: true
            runAsNonRoot: true
            capabilities:
              drop:
                - ALL
            {{- if include "eric-pm-server.hkln.seccompProfile" (dict "root" .root.shh "Scope" $containerName) }}
            seccompProfile:
              {{- include "eric-pm-server.hkln.seccompProfile" (dict "root" .root.shh "Scope" $containerName) | trim | nindent 14 }}
            {{- end }}
      restartPolicy: OnFailure
      serviceAccountName: {{ template "eric-pm-server.hkln.name" .root.top }}
      {{- if include "eric-pm-server.hkln.priorityClassName" .root.shh }}
      priorityClassName: {{ include "eric-pm-server.hkln.priorityClassName" .root.shh }}
      {{- end }}
      {{- if (include "eric-pm-server.hkln.tolerations" .root.shh | fromYamlArray) }}
      tolerations: {{- include "eric-pm-server.hkln.tolerations" .root.shh | nindent 8 }}
      {{- end }}
      {{- if include "eric-pm-server.hkln.nodeSelector" .root.shh }}
      nodeSelector: {{- include "eric-pm-server.hkln.nodeSelector" .root.shh | trim | nindent 8 }}
      {{- end }}
      {{- if include "eric-pm-server.hkln.seccompProfile" (dict "root" .root.shh "Scope" "Pod") }}
      securityContext:
        seccompProfile:
          {{- include "eric-pm-server.hkln.seccompProfile" (dict "root" .root.shh "Scope" "Pod") | trim | nindent 10 }}
      {{- end }}
  backoffLimit: {{ template "eric-pm-server.hkln.backoffLimit" .root.shh | default 6 }}
{{- end -}}
