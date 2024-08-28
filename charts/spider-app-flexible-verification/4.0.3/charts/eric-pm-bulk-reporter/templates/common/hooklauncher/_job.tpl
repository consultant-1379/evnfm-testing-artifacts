{{- define "eric-pm-bulk-reporter.hkln.job" -}}
{{- $containerName := include "eric-pm-bulk-reporter.hkln.containerName" .root.shh -}}
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ template "eric-pm-bulk-reporter.hkln.name" .root.top }}-{{ .suffix }}
  labels:
    {{- include "eric-pm-bulk-reporter.hkln.labels" .root.shh | nindent 4 }}
  annotations:
    {{- $helmHook := dict -}}
    {{- $_ := set $helmHook "helm.sh/hook" .helmHook -}}
    {{- $_ := set $helmHook "helm.sh/hook-weight" .weight -}}
    {{- $_ := set $helmHook "helm.sh/hook-delete-policy" "before-hook-creation,hook-succeeded" -}}
    {{- $commonAnn := fromYaml (include "eric-pm-bulk-reporter.hkln.annotations" .root.shh) -}}
    {{- include "eric-pm-bulk-reporter.mergeAnnotations" (dict "location" .root.shh.Template.Name "sources" (list $helmHook $commonAnn)) | trim | nindent 4 }}
spec:
  template:
    metadata:
      labels:
        {{- include "eric-pm-bulk-reporter.hkln.labels" .root.shh | nindent 8 }}
      annotations:
        {{- $appArmorAnn := include "eric-pm-bulk-reporter.hkln.appArmorProfileAnn" (dict "root" .root.shh "containerName" $containerName) | fromYaml -}}
        {{- $commonAnn := fromYaml (include "eric-pm-bulk-reporter.hkln.annotations" .root.shh) -}}
        {{- include "eric-pm-bulk-reporter.mergeAnnotations" (dict "location" .root.shh.Template.Name "sources" (list $appArmorAnn $commonAnn)) | trim | nindent 8 }}
    spec:
      {{- if include "eric-pm-bulk-reporter.hkln.pullSecrets" .root.shh }}
      imagePullSecrets:
        - name: {{ template "eric-pm-bulk-reporter.hkln.pullSecrets" .root.shh }}
      {{- end }}
      containers:
        - name: {{ $containerName }}
          image: {{ include "eric-pm-bulk-reporter.hkln.image-path" .root.shh }}
          env:
            - name: TZ
              value: {{ include "eric-pm-bulk-reporter.hkln.timezone" .root.shh }}
          args: [
            "/hooklauncher/hooklauncher",
            "--namespace", {{ .root.shh.Release.Namespace | quote }},

            {{- $chartInfo := include "eric-pm-bulk-reporter.hkln.chartInfo" .root.top | fromYaml -}}
            {{- range $subChartName, $subChartInfo := $chartInfo }}
            "--job-inventory-secret",
            {{ $subChartInfo.jobInventorySecret | quote }},
            "--this-version",
            {{ $subChartInfo.version | quote }},
            {{- end }}
            "--instance", {{ include "eric-pm-bulk-reporter.hkln.name" .root.top | quote }},
            "--this-job", {{ include "eric-pm-bulk-reporter.hkln.name" .root.top }}-{{ .suffix }},
            "--trigger", {{ .trigger | quote }},
            "--cleanup", {{ include "eric-pm-bulk-reporter.hkln.cleanup" .root.shh | quote }},
            "--terminate-early={{ template "eric-pm-bulk-reporter.hkln.terminateEarlyOnFailure" .root.shh }}",
            "--incluster"
          ]
          imagePullPolicy: {{ template "eric-pm-bulk-reporter.hkln.imagePullPolicy" .root.shh }}
          {{- if include "eric-pm-bulk-reporter.hkln.resources" .root.shh }}
          resources:
            {{- include "eric-pm-bulk-reporter.hkln.resources" .root.shh | trim | nindent 12 }}
          {{- end }}
          securityContext:
            allowPrivilegeEscalation: false
            privileged: false
            readOnlyRootFilesystem: true
            runAsNonRoot: true
            capabilities:
              drop:
                - ALL
            {{- if include "eric-pm-bulk-reporter.hkln.seccompProfile" (dict "root" .root.shh "Scope" $containerName) }}
            seccompProfile:
              {{- include "eric-pm-bulk-reporter.hkln.seccompProfile" (dict "root" .root.shh "Scope" $containerName) | trim | nindent 14 }}
            {{- end }}
      restartPolicy: OnFailure
      serviceAccountName: {{ template "eric-pm-bulk-reporter.hkln.name" .root.top }}
      {{- if include "eric-pm-bulk-reporter.hkln.priorityClassName" .root.shh }}
      priorityClassName: {{ include "eric-pm-bulk-reporter.hkln.priorityClassName" .root.shh }}
      {{- end }}
      {{- if (include "eric-pm-bulk-reporter.hkln.tolerations" .root.shh | fromYamlArray) }}
      tolerations: {{- include "eric-pm-bulk-reporter.hkln.tolerations" .root.shh | nindent 8 }}
      {{- end }}
      {{- if include "eric-pm-bulk-reporter.hkln.nodeSelector" .root.shh }}
      nodeSelector: {{- include "eric-pm-bulk-reporter.hkln.nodeSelector" .root.shh | trim | nindent 8 }}
      {{- end }}
      {{- if include "eric-pm-bulk-reporter.hkln.seccompProfile" (dict "root" .root.shh "Scope" "Pod") }}
      securityContext:
        seccompProfile:
          {{- include "eric-pm-bulk-reporter.hkln.seccompProfile" (dict "root" .root.shh "Scope" "Pod") | trim | nindent 10 }}
      {{- end }}
  backoffLimit: {{ template "eric-pm-bulk-reporter.hkln.backoffLimit" .root.shh | default 6 }}
{{- end -}}
