{{/*
List of job information for hooklauncher to use for different events.

EXAMPLE:
Multiple supported version could be defined and multiple jobList could be defined.
- supportedSource: ">= 8.1.0-0"
  supportedTarget: "<= 8.0.0-60"
  jobList:
    - weight: 2
      triggerWhen: ["pre-rollback"]
      jobManifest: {{ include "eric-data-document-database-pg.nwp-create-job" (dict "root" . "chartName" $chartName "weight" 1 "triggerWhen" "pre-rollback" "Values" .Values "Chart" .Chart "Release" .Release "Files" .Files "Template" .Template "Capabilities" .Capabilities) | fromYaml | toJson | b64enc | trim | nindent 8 }}

*/}}


{{/*
List of job information for hooklauncher to use for different events.
*/}}
{{- define "eric-data-document-database-pg.hkln.job-inventory-contents" -}}
{{- $chartName := include "eric-data-document-database-pg.hkln.name" . -}}
- supportedSource: "> 8.0.0-0"
  supportedTarget: "*"
  jobList:
    - weight: -10
      triggerWhen: ["pre-rollback"]
      jobManifest: {{ include "eric-data-document-database-pg.prerollback-del-hook" (dict "root" . "chartName" $chartName "weight" -10 "triggerWhen" "pre-rollback" "Values" .Values "Chart" .Chart "Release" .Release "Files" .Files "Capabilities" .Capabilities) | fromYaml | toJson | b64enc | trim | nindent 8 }}
- supportedSource: "> 8.0.0-0"
  supportedTarget: "*"
  jobList:
    - weight: -10
      triggerWhen: ["pre-upgrade"]
      jobManifest: {{ include "eric-data-document-database-pg.predowngrading-patch-hook" (dict "root" . "chartName" $chartName "weight" -10 "triggerWhen" "pre-upgrade" "Values" .Values "Chart" .Chart "Release" .Release "Files" .Files "Capabilities" .Capabilities) | fromYaml | toJson | b64enc | trim | nindent 8 }}
- supportedSource: "> 8.0.0-0"
  supportedTarget: "*"
  jobList:
    - weight: -10
      triggerWhen: ["post-upgrade"]
      jobManifest: {{ include "eric-data-document-database-pg.postupgrading-recreate-hook" (dict "root" . "chartName" $chartName "weight" -10 "triggerWhen" "post-upgrade" "Values" .Values "Chart" .Chart "Release" .Release "Files" .Files "Capabilities" .Capabilities) | fromYaml | toJson | b64enc | trim | nindent 8 }}

{{- end -}}


{{- define "eric-data-document-database-pg.prerollback-del-hook" -}}
{{- $globalValue := fromJson (include "eric-data-document-database-pg.global" .) -}}
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ template "eric-data-document-database-pg.name" . }}-del-hook
  labels: 
    smarthelmhooksjobkind: dynamic
    managedby: "smart-helm-hook"
spec:
  template:
    metadata:
      labels:
        managedby: "smart-helm-hook"
        sidecar.istio.io/inject: "false"
    spec:
      restartPolicy: Never
      serviceAccountName: {{ template "eric-data-document-database-pg.name" . }}-op-dispatch
      {{- if include "eric-data-document-database-pg.pullSecrets" . }}
      imagePullSecrets:
        - name: {{ template "eric-data-document-database-pg.pullSecrets" . }}
      {{- end }}
      securityContext:
        fsGroup: {{ template "eric-data-document-database-pg.fsGroup.coordinated" . }}
          {{- if semverCompare ">=1.23.0-0" .Capabilities.KubeVersion.Version }}
        fsGroupChangePolicy: "OnRootMismatch"
          {{- end }}
        {{- if include "eric-data-document-database-pg.podSecurityContext.supplementalGroups" . -}}
{{- include "eric-data-document-database-pg.podSecurityContext.supplementalGroups" . | nindent 8 }}
        {{- end }}
      {{- if or (not (empty .Values.nodeSelector.oppatchhook)) (not (eq "{}" (include "eric-data-document-database-pg.global.nodeSelector" .))) }}
      nodeSelector:
{{- include "eric-data-document-database-pg.nodeSelector.oppatchhook" . | nindent 8 }}
      {{- end }}
      tolerations:
{{ include "eric-data-document-database-pg.merge-tolerations" (dict "root" . "podbasename" "oppatchhook") | nindent 8}}
      containers:
        - name: op-patch-hook
          image: {{ template "eric-data-document-database-pg.kubeclientImagePath" . }}
          imagePullPolicy: {{ include "eric-data-document-database-pg.imagePullPolicy" . | quote }}
          env:
          - name: TZ
            value: {{ $globalValue.timezone | quote }}
          - name: LOG_SCHEMA
            value: {{ template "eric-data-document-database-pg.logSchema" . }}
          - name: LOG_REDIRECT
            value: "stdout"
          - name: CLUSTER_NAME
            value: {{ template "eric-data-document-database-pg.name" . }}
          - name: RELEASE_NAME
            value: {{ .Release.Name | quote }}
          - name: OP_ENABLED
            {{- if (eq (include "eric-data-document-database-pg.operator-enabled" .) "true") }}
            value: "true"
            {{- else }}
            value: "false"
            {{- end }}
          - name: KUBERNETES_NAMESPACE
            valueFrom: { fieldRef: { fieldPath: metadata.namespace } }
          - name: TRANSIT_COMPONENT
            value: {{ template "eric-data-document-database-pg.name" . }}-transit-pvc
          - name: RELEASE_UPGRADE
            value: {{ .Release.IsUpgrade | quote }}
          - name: CHART_NAME
            value: {{ template "eric-data-document-database-pg.name" . }}
          - name: ENABLE_SIPTLS
            {{- if (not (eq (include "eric-data-document-database-pg.global-security-tls-enabled" .) "false")) }}
            value: "true"
            {{- else }}
            value: "false"
            {{- end }}
          command:
            - /bin/bash
            - -c
          args:
            - "/usr/bin/catatonit -- 
              {{ template "eric-data-document-database-pg.stdRedirectCMD" .  }}
              /usr/bin/python {{ template "eric-data-document-database-pg.hook.scriptPath" . }}/opupgrade_handler.py --prerollback_delete_remaining_resources"
          securityContext:
            allowPrivilegeEscalation: false
            privileged: false
            readOnlyRootFilesystem: true
            runAsNonRoot: true
            capabilities:
              drop:
                - ALL
          volumeMounts:
            - name: tmp
              mountPath: /tmp
          resources:
            requests:
            {{- if .Values.resources.kube_client.requests.cpu }}
              cpu: {{ .Values.resources.kube_client.requests.cpu  | quote }}
            {{- end }}
            {{- if .Values.resources.kube_client.requests.memory }}
              memory: {{ .Values.resources.kube_client.requests.memory  | quote }}
            {{- end }}
            {{- if index .Values.resources.kube_client.requests "ephemeral-storage" }}
              ephemeral-storage: {{ index .Values.resources.kube_client.requests "ephemeral-storage" | quote }}
            {{- end }}
            limits:
            {{- if .Values.resources.kube_client.limits.cpu }}
              cpu: {{ .Values.resources.kube_client.limits.cpu  | quote }}
            {{- end }}
            {{- if .Values.resources.kube_client.limits.memory }}
              memory: {{ .Values.resources.kube_client.limits.memory  | quote }}
            {{- end }}
            {{- if index .Values.resources.kube_client.limits "ephemeral-storage" }}
              ephemeral-storage: {{ index .Values.resources.kube_client.limits "ephemeral-storage" | quote }}
            {{- end }}
      volumes:
      - name: tmp
        emptyDir: {}
{{- end -}}

{{- define "eric-data-document-database-pg.predowngrading-patch-hook" -}}
{{- $globalValue := fromJson (include "eric-data-document-database-pg.global" .) -}}
{{- $rolekind := (include "eric-data-document-database-pg.securityPolicy.rolekind" .) -}}
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ template "eric-data-document-database-pg.name" . }}-upg-hook
  labels: 
    smarthelmhooksjobkind: dynamic
    managedby: "smart-helm-hook"
spec:
  template:
    metadata:
      labels:
        managedby: "smart-helm-hook"
        sidecar.istio.io/inject: "false"
    spec:
      restartPolicy: Never
      serviceAccountName: {{ template "eric-data-document-database-pg.name" . }}-op-dispatch
      {{- if include "eric-data-document-database-pg.pullSecrets" . }}
      imagePullSecrets:
        - name: {{ template "eric-data-document-database-pg.pullSecrets" . }}
      {{- end }}
      securityContext:
        fsGroup: {{ template "eric-data-document-database-pg.fsGroup.coordinated" . }}
          {{- if semverCompare ">=1.23.0-0" .Capabilities.KubeVersion.Version }}
        fsGroupChangePolicy: "OnRootMismatch"
          {{- end }}
        {{- if include "eric-data-document-database-pg.podSecurityContext.supplementalGroups" . -}}
{{- include "eric-data-document-database-pg.podSecurityContext.supplementalGroups" . | nindent 8 }}
        {{- end }}
      {{- if or (not (empty .Values.nodeSelector.oppatchhook)) (not (eq "{}" (include "eric-data-document-database-pg.global.nodeSelector" .))) }}
      nodeSelector:
{{- include "eric-data-document-database-pg.nodeSelector.oppatchhook" . | nindent 8 }}
      {{- end }}
      tolerations:
{{ include "eric-data-document-database-pg.merge-tolerations" (dict "root" . "podbasename" "oppatchhook") | nindent 8}}
      containers:
        - name: op-patch-hook
          image: {{ template "eric-data-document-database-pg.kubeclientImagePath" . }}
          imagePullPolicy: {{ include "eric-data-document-database-pg.imagePullPolicy" . | quote }}
          env:
          - name: TZ
            value: {{ $globalValue.timezone | quote }}
          - name: LOG_SCHEMA
            value: {{ template "eric-data-document-database-pg.logSchema" . }}
          - name: LOG_REDIRECT
            value: "stdout"
          - name: CLUSTER_NAME
            value: {{ template "eric-data-document-database-pg.name" . }}
          - name: RELEASE_NAME
            value: {{ .Release.Name | quote }}
          - name: OP_ENABLED
            {{- if (eq (include "eric-data-document-database-pg.operator-enabled" .) "true") }}
            value: "true"
            {{- else }}
            value: "false"
            {{- end }}
          - name: KUBERNETES_NAMESPACE
            valueFrom: { fieldRef: { fieldPath: metadata.namespace } }
          - name: TRANSIT_COMPONENT
            value: {{ template "eric-data-document-database-pg.name" . }}-transit-pvc
          - name: RELEASE_UPGRADE
            value: {{ .Release.IsUpgrade | quote }}
          - name: CHART_NAME
            value: {{ template "eric-data-document-database-pg.name" . }}
            {{- if $rolekind }}
          - name: SECURITY_ROLEBINDING_SUFFIX
            value: sa-{{ lower (trunc 1 $rolekind) }}-{{ include "eric-data-document-database-pg.securityPolicy.rolename" (dict "Values" .Values "PodName" "postgres") }}
            {{- end }}
          - name: ENABLE_SIPTLS
            {{- if (not (eq (include "eric-data-document-database-pg.global-security-tls-enabled" .) "false")) }}
            value: "true"
            {{- else }}
            value: "false"
            {{- end }}
          command:
            - /bin/bash
            - -c
          args:
            - "/usr/bin/catatonit -- 
              {{ template "eric-data-document-database-pg.stdRedirectCMD" .  }}
              /usr/bin/python {{ template "eric-data-document-database-pg.hook.scriptPath" . }}/opupgrade_handler.py --preupgrade_helm_adopt_patch"
          securityContext:
            allowPrivilegeEscalation: false
            privileged: false
            readOnlyRootFilesystem: true
            runAsNonRoot: true
            capabilities:
              drop:
                - ALL
          volumeMounts:
            - name: tmp
              mountPath: /tmp
          resources:
            requests:
            {{- if .Values.resources.kube_client.requests.cpu }}
              cpu: {{ .Values.resources.kube_client.requests.cpu  | quote }}
            {{- end }}
            {{- if .Values.resources.kube_client.requests.memory }}
              memory: {{ .Values.resources.kube_client.requests.memory  | quote }}
            {{- end }}
            {{- if index .Values.resources.kube_client.requests "ephemeral-storage" }}
              ephemeral-storage: {{ index .Values.resources.kube_client.requests "ephemeral-storage" | quote }}
            {{- end }}
            limits:
            {{- if .Values.resources.kube_client.limits.cpu }}
              cpu: {{ .Values.resources.kube_client.limits.cpu  | quote }}
            {{- end }}
            {{- if .Values.resources.kube_client.limits.memory }}
              memory: {{ .Values.resources.kube_client.limits.memory  | quote }}
            {{- end }}
            {{- if index .Values.resources.kube_client.limits "ephemeral-storage" }}
              ephemeral-storage: {{ index .Values.resources.kube_client.limits "ephemeral-storage" | quote }}
            {{- end }}
      volumes:
      - name: tmp
        emptyDir: {}
{{- end -}}



{{- define "eric-data-document-database-pg.postupgrading-recreate-hook" -}}
{{- $globalValue := fromJson (include "eric-data-document-database-pg.global" .) -}}
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ template "eric-data-document-database-pg.name" . }}-dng-hook
  labels: 
    smarthelmhooksjobkind: dynamic
    managedby: "smart-helm-hook"
spec:
  template:
    metadata:
      labels:
        managedby: "smart-helm-hook"
        sidecar.istio.io/inject: "false"
    spec:
      restartPolicy: Never
      serviceAccountName: {{ template "eric-data-document-database-pg.name" . }}-op-dispatch
      {{- if include "eric-data-document-database-pg.pullSecrets" . }}
      imagePullSecrets:
        - name: {{ template "eric-data-document-database-pg.pullSecrets" . }}
      {{- end }}
      securityContext:
        fsGroup: {{ template "eric-data-document-database-pg.fsGroup.coordinated" . }}
          {{- if semverCompare ">=1.23.0-0" .Capabilities.KubeVersion.Version }}
        fsGroupChangePolicy: "OnRootMismatch"
          {{- end }}
        {{- if include "eric-data-document-database-pg.podSecurityContext.supplementalGroups" . -}}
{{- include "eric-data-document-database-pg.podSecurityContext.supplementalGroups" . | nindent 8 }}
        {{- end }}
      {{- if or (not (empty .Values.nodeSelector.oppatchhook)) (not (eq "{}" (include "eric-data-document-database-pg.global.nodeSelector" .))) }}
      nodeSelector:
{{- include "eric-data-document-database-pg.nodeSelector.oppatchhook" . | nindent 8 }}
      {{- end }}
      tolerations:
{{ include "eric-data-document-database-pg.merge-tolerations" (dict "root" . "podbasename" "oppatchhook") | nindent 8}}
      containers:
        - name: op-recreate-hook
          image: {{ template "eric-data-document-database-pg.kubeclientImagePath" . }}
          imagePullPolicy: {{ include "eric-data-document-database-pg.imagePullPolicy" . | quote }}
          env:
          - name: TZ
            value: {{ $globalValue.timezone | quote }}
          - name: LOG_SCHEMA
            value: {{ template "eric-data-document-database-pg.logSchema" . }}
          - name: LOG_REDIRECT
            value: "stdout"
          - name: CLUSTER_NAME
            value: {{ template "eric-data-document-database-pg.name" . }}
          - name: RELEASE_NAME
            value: {{ .Release.Name | quote }}
          - name: OP_ENABLED
            {{- if (eq (include "eric-data-document-database-pg.operator-enabled" .) "true") }}
            value: "true"
            {{- else }}
            value: "false"
            {{- end }}
          - name: KUBERNETES_NAMESPACE
            valueFrom: { fieldRef: { fieldPath: metadata.namespace } }
          - name: TRANSIT_COMPONENT
            value: {{ template "eric-data-document-database-pg.name" . }}-transit-pvc
          - name: RELEASE_UPGRADE
            value: {{ .Release.IsUpgrade | quote }}
          - name: CHART_NAME
            value: {{ template "eric-data-document-database-pg.name" . }}
          - name: ENABLE_SIPTLS
            {{- if (not (eq (include "eric-data-document-database-pg.global-security-tls-enabled" .) "false")) }}
            value: "true"
            {{- else }}
            value: "false"
            {{- end }}
          command:
            - /bin/bash
            - -c
          args:
            - "/usr/bin/catatonit -- 
              {{ template "eric-data-document-database-pg.stdRedirectCMD" .  }} 
              /usr/bin/python {{ template "eric-data-document-database-pg.hook.scriptPath" . }}/opupgrade_handler.py --postupgrade_helm_adpot_recreate_rbac"
          securityContext:
            allowPrivilegeEscalation: false
            privileged: false
            readOnlyRootFilesystem: true
            runAsNonRoot: true
            capabilities:
              drop:
                - ALL
          volumeMounts:
            - name: tmp
              mountPath: /tmp
          resources:
            requests:
            {{- if .Values.resources.kube_client.requests.cpu }}
              cpu: {{ .Values.resources.kube_client.requests.cpu  | quote }}
            {{- end }}
            {{- if .Values.resources.kube_client.requests.memory }}
              memory: {{ .Values.resources.kube_client.requests.memory  | quote }}
            {{- end }}
            {{- if index .Values.resources.kube_client.requests "ephemeral-storage" }}
              ephemeral-storage: {{ index .Values.resources.kube_client.requests "ephemeral-storage" | quote }}
            {{- end }}
            limits:
            {{- if .Values.resources.kube_client.limits.cpu }}
              cpu: {{ .Values.resources.kube_client.limits.cpu  | quote }}
            {{- end }}
            {{- if .Values.resources.kube_client.limits.memory }}
              memory: {{ .Values.resources.kube_client.limits.memory  | quote }}
            {{- end }}
            {{- if index .Values.resources.kube_client.limits "ephemeral-storage" }}
              ephemeral-storage: {{ index .Values.resources.kube_client.limits "ephemeral-storage" | quote }}
            {{- end }}
      volumes:
      - name: tmp
        emptyDir: {}
{{- end -}}
