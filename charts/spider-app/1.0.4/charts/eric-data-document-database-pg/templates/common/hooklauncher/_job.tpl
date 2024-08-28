{{- define "eric-data-document-database-pg.hkln.job" -}}
{{- $containerName := include "eric-data-document-database-pg.hkln.containerName" .root.shh -}}
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ template "eric-data-document-database-pg.hkln.name" .root.top }}-{{ .suffix }}
  labels:
    {{- include "eric-data-document-database-pg.hkln.labels" .root.shh | nindent 4 }}
  annotations:
    {{- $helmHook := dict -}}
    {{- $_ := set $helmHook "helm.sh/hook" .helmHook -}}
    {{- $_ := set $helmHook "helm.sh/hook-weight" .weight -}}
    {{- $_ := set $helmHook "helm.sh/hook-delete-policy" "before-hook-creation,hook-succeeded" -}}
    {{- $commonAnn := fromYaml (include "eric-data-document-database-pg.hkln.annotations" .root.shh) -}}
    {{- include "eric-data-document-database-pg.mergeAnnotations" (dict "location" .root.shh.Template.Name "sources" (list $helmHook $commonAnn)) | trim | nindent 4 }}
spec:
  template:
    metadata:
      labels:
        {{- include "eric-data-document-database-pg.hkln.labels" .root.shh | nindent 8 }}
      annotations:
        {{- $appArmorAnn := include "eric-data-document-database-pg.hkln.appArmorProfileAnn" (dict "root" .root.shh "containerName" $containerName) | fromYaml -}}
        {{- $commonAnn := fromYaml (include "eric-data-document-database-pg.hkln.annotations" .root.shh) -}}
        {{- include "eric-data-document-database-pg.mergeAnnotations" (dict "location" .root.shh.Template.Name "sources" (list $appArmorAnn $commonAnn)) | trim | nindent 8 }}
    spec:
      {{- if include "eric-data-document-database-pg.hkln.pullSecrets" .root.shh }}
      imagePullSecrets:
        - name: {{ template "eric-data-document-database-pg.hkln.pullSecrets" .root.shh }}
      {{- end }}
      containers:
        - name: {{ $containerName }}
          image: {{ include "eric-data-document-database-pg.hkln.image-path" .root.shh }}
          env:
            - name: TZ
              value: {{ include "eric-data-document-database-pg.hkln.timezone" .root.shh }}
          args: [
            "/hooklauncher/hooklauncher",
            "--namespace", {{ .root.shh.Release.Namespace | quote }},

            {{- $chartInfo := include "eric-data-document-database-pg.hkln.chartInfo" .root.top | fromYaml -}}
            {{- range $subChartName, $subChartInfo := $chartInfo }}
            "--job-inventory-secret",
            {{ $subChartInfo.jobInventorySecret | quote }},
            "--this-version",
            {{ $subChartInfo.version | quote }},
            {{- end }}
            "--instance", {{ include "eric-data-document-database-pg.hkln.name" .root.top | quote }},
            "--this-job", {{ include "eric-data-document-database-pg.hkln.name" .root.top }}-{{ .suffix }},
            "--trigger", {{ .trigger | quote }},
            "--cleanup", {{ include "eric-data-document-database-pg.hkln.cleanup" .root.shh | quote }},
            "--terminate-early={{ template "eric-data-document-database-pg.hkln.terminateEarlyOnFailure" .root.shh }}",
            "--incluster"
          ]
          imagePullPolicy: {{ template "eric-data-document-database-pg.hkln.imagePullPolicy" .root.shh }}
          {{- if include "eric-data-document-database-pg.hkln.resources" .root.shh }}
          resources:
            {{- include "eric-data-document-database-pg.hkln.resources" .root.shh | trim | nindent 12 }}
          {{- end }}
          securityContext:
            allowPrivilegeEscalation: false
            privileged: false
            readOnlyRootFilesystem: true
            runAsNonRoot: true
            capabilities:
              drop:
                - ALL
            {{- if include "eric-data-document-database-pg.hkln.seccompProfile" (dict "root" .root.shh "Scope" $containerName) }}
            seccompProfile:
              {{- include "eric-data-document-database-pg.hkln.seccompProfile" (dict "root" .root.shh "Scope" $containerName) | trim | nindent 14 }}
            {{- end }}
      restartPolicy: OnFailure
      serviceAccountName: {{ template "eric-data-document-database-pg.hkln.name" .root.top }}
      {{- if include "eric-data-document-database-pg.hkln.priorityClassName" .root.shh }}
      priorityClassName: {{ include "eric-data-document-database-pg.hkln.priorityClassName" .root.shh }}
      {{- end }}
      {{- if (include "eric-data-document-database-pg.hkln.tolerations" .root.shh | fromYamlArray) }}
      tolerations: {{- include "eric-data-document-database-pg.hkln.tolerations" .root.shh | nindent 8 }}
      {{- end }}
      {{- if include "eric-data-document-database-pg.hkln.nodeSelector" .root.shh }}
      nodeSelector: {{- include "eric-data-document-database-pg.hkln.nodeSelector" .root.shh | trim | nindent 8 }}
      {{- end }}
      {{- if include "eric-data-document-database-pg.hkln.seccompProfile" (dict "root" .root.shh "Scope" "Pod") }}
      securityContext:
        seccompProfile:
          {{- include "eric-data-document-database-pg.hkln.seccompProfile" (dict "root" .root.shh "Scope" "Pod") | trim | nindent 10 }}
      {{- end }}
  backoffLimit: {{ template "eric-data-document-database-pg.hkln.backoffLimit" .root.shh | default 6 }}
{{- end -}}
