{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}



{{/*
Define a template isOpMigrationRequired that determines if upgrade path belongs to helm to op.
*/}}
{{- define "eric-data-document-database-pg.isOpMigrationRequired" -}}
{{- $foundFeDeployment := (lookup "apps/v1" "Deployment" .Release.Namespace (printf "%s-%s" (include "eric-data-document-database-pg.name" .) "feoperator") ) -}}
{{- if $foundFeDeployment -}}
false
{{- else -}}
true
{{- end -}}
{{- end -}}



{{- define "eric-data-document-database-pg.opNetworkPolicyHook" }}
{{- if .Release.IsUpgrade }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ template "eric-data-document-database-pg.name" . }}-hook-op
  labels:
    {{- include "eric-data-document-database-pg.labels" . | nindent 4 }}
  annotations:
    {{- $helmHooks := dict -}}
    {{- $_ := set $helmHooks "helm.sh/hook" "pre-upgrade" -}}
    {{- $_ := set $helmHooks "helm.sh/hook-weight" "-3" -}}
    {{- $commonAnn := fromYaml (include "eric-data-document-database-pg.annotations" .) -}}
    {{- include "eric-data-document-database-pg.mergeAnnotations" (dict "location" .Template.Name "sources" (list $helmHooks $commonAnn)) | trim | nindent 4 }}
spec:
  podSelector:
    matchLabels:
      migration: documentdb
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app.kubernetes.io/name: {{ template "eric-data-document-database-pg.name" . }}
    - podSelector:
        matchLabels:
          app: {{ template "eric-data-document-database-pg.name" . }}-backup-pgdata
    - podSelector:
        matchLabels:
          app: {{ template "eric-data-document-database-pg.name" . }}-restore-pgdata
    - podSelector:
        matchLabels:
          {{ template "eric-data-document-database-pg.name" . }}-access: "true"
    - podSelector:
        matchLabels:
          app.kubernetes.io/name: {{ default "eric-pm-server" .Values.metrics.hostname }}
{{- include "eric-data-document-database-pg.networkPolicy.matchLabels" . | indent 4 }}
    ports:
    - port: 8083
      protocol: TCP
    - port: {{ .Values.service.port }}
      protocol: TCP
{{- if .Values.metrics.enabled }}
    - port: {{ .Values.metrics.service.port }}
      protocol: TCP
{{- end }}
{{- end -}}
{{- end }}

{{- define "eric-data-document-database-pg.oPCleanPGDataJob" }}
{{- if .Release.IsUpgrade }}
{{- $globalValue := fromJson (include "eric-data-document-database-pg.global" .) -}}
{{- $logshipperValues := fromJson (include "eric-data-document-database-pg.ls-values" .) -}}
{{- $logshipperCopied := deepCopy . -}}
{{- $logshipperMerged := (mergeOverwrite $logshipperCopied $logshipperValues) -}}
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ template "eric-data-document-database-pg.name" . }}-hook-cleanjob-op
  labels:
    {{- include "eric-data-document-database-pg.labels.extended-defaults" . | nindent 4 }}
  annotations:
    {{- $helmHooks := dict -}}
    {{- $_ := set $helmHooks "helm.sh/hook" "post-upgrade" -}}
    {{- $_ := set $helmHooks "helm.sh/hook-delete-policy" "hook-succeeded,before-hook-creation" -}}
    {{- $_ := set $helmHooks "helm.sh/hook-weight" "-5" -}}
    {{- $commonAnn := fromYaml (include "eric-data-document-database-pg.annotations" .) -}}
    {{- include "eric-data-document-database-pg.mergeAnnotations" (dict "location" .Template.Name "sources" (list $helmHooks $commonAnn)) | trim | nindent 4 }}
spec:
  template:
    metadata:
      labels:
        {{- $podTemplateLabels := dict -}}
        {{- $_ := set $podTemplateLabels "app" (printf "%s-hook-cleanjob" (include "eric-data-document-database-pg.name" .)) -}}
        {{- $_ := set $podTemplateLabels "sidecar.istio.io/inject" "false" -}}
        {{- $commonLabels := fromYaml (include "eric-data-document-database-pg.labels" .) -}}
        {{- $_ := unset $commonLabels "app" -}}
        {{- $networkpllabels := fromYaml (include "eric-data-document-database-pg.networkpolicyp2.labels" .) -}}
        {{- include "eric-data-document-database-pg.mergeLabels" (dict "location" .Template.Name "sources" (list $podTemplateLabels $commonLabels $networkpllabels)) | trim | nindent 8 }}
      annotations:
        {{- $podTempAnn := dict -}}
        {{- if .Values.bandwidth.cleanuphook.maxEgressRate }}
          {{- $_ := set $podTempAnn "kubernetes.io/egress-bandwidth" (.Values.bandwidth.cleanuphook.maxEgressRate | toString) -}}
        {{- end }}
        {{- $commonAnn := fromYaml (include "eric-data-document-database-pg.annotations" .) -}}
        {{- $appArmorAnn := include "eric-data-document-database-pg.appArmorProfile" (dict "root" . "Scope" "Hook" "containerList" (list "hook-cleanjob")) | fromYaml -}}
        {{- include "eric-data-document-database-pg.mergeAnnotations" (dict "location" .Template.Name "sources" (list $podTempAnn $appArmorAnn $commonAnn)) | trim | nindent 8 }}
    spec:
      restartPolicy: Never
      serviceAccountName: {{ template "eric-data-document-database-pg.name" . }}-pgdata-hook-fe
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
{{- include "eric-data-document-database-pg.seccompProfile" (dict "Values" .Values "Scope" "Pod") | nindent 8 }}
      {{- if or (not (empty .Values.nodeSelector.cleanuphook)) (not (eq "{}" (include "eric-data-document-database-pg.global.nodeSelector" .))) }}
      nodeSelector:
{{- include "eric-data-document-database-pg.nodeSelector.cleanuphook" . | nindent 8 }}
      {{- end }}
      tolerations:
{{ include "eric-data-document-database-pg.merge-tolerations" (dict "root" . "podbasename" "cleanuphook ") | nindent 8}}
      {{- if .Values.podPriority.cleanuphook.priorityClassName }}
      priorityClassName: {{ .Values.podPriority.cleanuphook.priorityClassName | quote }}
      {{- end }}
      containers:
        - name: hook-cleanjob
          image: {{ template "eric-data-document-database-pg.kubeclientImagePath" . }}
          imagePullPolicy: {{ include "eric-data-document-database-pg.imagePullPolicy" . | quote }}
          env:
          - name: CLUSTER_NAME
            value: {{ template "eric-data-document-database-pg.name" . }}
          - name: LOG_SCHEMA
            value: {{ template "eric-data-document-database-pg.logSchema" . }}
          - name: RESTORE_JOB_NAME
            value: {{ template "eric-data-document-database-pg.name" . }}-restore-pgdatau-op
          - name: KUBERNETES_NAMESPACE
            valueFrom: { fieldRef: { fieldPath: metadata.namespace } }
          - name: CONTAINER_NAME
            value:  {{ template "eric-data-document-database-pg.name" . }}-hook
          - name: LOG_REDIRECT
            value: {{ template "eric-data-document-database-pg.logRedirect" . }}
          - name: TZ
            value: {{ $globalValue.timezone | quote }}
          command:
            - /bin/bash
            - -c
          args:
            - "/usr/bin/catatonit --
              {{ template "eric-data-document-database-pg.stdRedirectCMD" .  }}
              /usr/bin/python {{ template "eric-data-document-database-pg.hook.scriptPath" . }}/cleanjob.py
              --clean_upgrading_pgdata_job; sleep 3"
          securityContext:
            {{- include "eric-data-document-database-pg.seccompProfile" (dict "Values" .Values "Scope" "hook-cleanjob") | nindent 12 }}
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
          {{- if .Release.IsUpgrade }}
          {{- include "eric-data-document-database-pg.log.mounts-hooks" $logshipperMerged | indent 12 }}
          {{- end }}
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

      {{- include "eric-data-document-database-pg.log.containers-hooks" $logshipperMerged | indent 8 }}
      volumes:
      {{- if .Release.IsUpgrade }}
      {{- include "eric-data-document-database-pg.log.volumes-hooks" $logshipperMerged | indent 6 }}
      {{- end }}
      - name: tmp
        emptyDir: {}
{{- end -}}
{{- end }}


{{- define "eric-data-document-database-pg.preUpgradeHookBackup-data" }}
{{- if .Release.IsUpgrade }}
{{- $globalValue := fromJson (include "eric-data-document-database-pg.global" .) -}}
{{- $logshipperValues := fromJson (include "eric-data-document-database-pg.ls-values" .) -}}
{{- $logshipperCopied := deepCopy . -}}
{{- $logshipperMerged := (mergeOverwrite $logshipperCopied $logshipperValues) -}}
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ template "eric-data-document-database-pg.name" . }}-backup-pgdata-op
  labels: {{- include "eric-data-document-database-pg.labels.extended-defaults" . | nindent 4 }}
  annotations:
    {{- $helmHooks := dict -}}
    {{- $_ := set $helmHooks "helm.sh/hook" "pre-upgrade" -}}
    {{- $_ := set $helmHooks "helm.sh/hook-delete-policy" "hook-succeeded,before-hook-creation" -}}
    {{- $_ := set $helmHooks "helm.sh/hook-weight" "-1" -}}
    {{- $commonAnn := fromYaml (include "eric-data-document-database-pg.annotations" .) -}}
    {{- include "eric-data-document-database-pg.mergeAnnotations" (dict "location" .Template.Name "sources" (list $helmHooks $commonAnn)) | nindent 4 }}
spec:
  backoffLimit: 0
  template:
    metadata:
      labels:
        {{- $podTemplateLabels := dict -}}
        {{- $_ := set $podTemplateLabels "app" (printf "%s-%s" (include "eric-data-document-database-pg.name" .) "backup-pgdata") -}}
        {{- $_ := set $podTemplateLabels "sidecar.istio.io/inject" "false" -}}
        {{- $commonLabels := fromYaml (include "eric-data-document-database-pg.labels" .) -}}
        {{- $networkpllabels := fromYaml (include "eric-data-document-database-pg.networkpolicyp2.labels" .) -}}
        {{- include "eric-data-document-database-pg.mergeLabels" (dict "location" .Template.Name "sources" (list $commonLabels $podTemplateLabels $networkpllabels)) | nindent 8 }}
      annotations:
        {{- $podTempAnn := dict -}}
        {{- if .Values.bandwidth.cleanuphook.maxEgressRate }}
          {{- $_ := set $podTempAnn "kubernetes.io/egress-bandwidth" (.Values.bandwidth.cleanuphook.maxEgressRate | toString) -}}
        {{- end }}
        {{- $commonAnn := fromYaml (include "eric-data-document-database-pg.annotations" .) -}}
        {{- $appArmorAnn := include "eric-data-document-database-pg.appArmorProfile" (dict "root" . "Scope" "NoLSHook" "containerList" (list "backup-pgdata")) | fromYaml -}}
        {{- include "eric-data-document-database-pg.mergeAnnotations" (dict "location" .Template.Name "sources" (list $podTempAnn $appArmorAnn $commonAnn)) | trim | nindent 8 }}
    spec:
      restartPolicy: Never
      serviceAccountName: {{ template "eric-data-document-database-pg.name" . }}-pgdata-hook-fe
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
{{- include "eric-data-document-database-pg.seccompProfile" (dict "Values" .Values "Scope" "Pod") | nindent 8 }}
      {{- if or (not (empty .Values.nodeSelector.cleanuphook)) (not (eq "{}" (include "eric-data-document-database-pg.global.nodeSelector" .))) }}
      nodeSelector:
{{- include "eric-data-document-database-pg.nodeSelector.cleanuphook" . | nindent 8 }}
      {{- end }}
      tolerations:
{{ include "eric-data-document-database-pg.merge-tolerations" (dict "root" . "podbasename" "cleanuphook ") | nindent 8}}
      {{- if .Values.podPriority.cleanuphook.priorityClassName }}
      priorityClassName: {{ .Values.podPriority.cleanuphook.priorityClassName | quote }}
      {{- end }}
      containers:
        - name: backup-pgdata
          image: {{ template "eric-data-document-database-pg.kubeclientImagePath" . }}
          imagePullPolicy: {{ include "eric-data-document-database-pg.imagePullPolicy" . | quote }}
          env:
          - name: STATEFULSET_NAME
            value: {{ template "eric-data-document-database-pg.name" . }}
          - name: REPLICA_COUNT
            value: {{ .Values.highAvailability.replicaCount | quote }}
          - name: CLUSTER_NAME
            value: {{ template "eric-data-document-database-pg.name" . }}
          - name: RELEASE_NAME
            value: {{ .Release.Name | quote }}
          - name: KUBERNETES_NAMESPACE
            valueFrom: { fieldRef: { fieldPath: metadata.namespace } }
          - name: TRANSIT_COMPONENT
            value: {{ template "eric-data-document-database-pg.name" . }}-transit-pvc
          - name: TARGET_PG_VERSION
            value: "13"
          - name: PHASE
            value: "upgrading"
          - name: LOG_SCHEMA
            value: {{ template "eric-data-document-database-pg.logSchema" . }}
          - name: TZ
            value: {{ $globalValue.timezone | quote }}
          {{- if include "eric-data-document-database-pg.persistentVolumeClaim.defaultStorageClassName" . }}
          - name: STORAGE_CLASSNAME
            value: {{ template "eric-data-document-database-pg.persistentVolumeClaim.defaultStorageClassName" . }}
          {{- end }}
          - name: ENABLE_SIPTLS
            {{- if (not (eq (include "eric-data-document-database-pg.global-security-tls-enabled" .) "false")) }}
            value: "true"
            {{- else }}
            value: "false"
            {{- end }}
          - name: CONTAINER_NAME
            value:  {{ template "eric-data-document-database-pg.name" . }}-hook
          - name: LOG_REDIRECT
            value: "stdout"
          command:
            - /bin/bash
            - -c
          args:
            - "
              /usr/bin/catatonit -- 
              {{ template "eric-data-document-database-pg.stdRedirectCMD" .  }}
              {{ template "eric-data-document-database-pg.hook.scriptPath" . }}/op_backuppgdata.sh
              "
          securityContext:
            {{- include "eric-data-document-database-pg.seccompProfile" (dict "Values" .Values "Scope" "backup-pgdata") | nindent 12 }}
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
            - name: pgdata-volume
              mountPath: "/var/pgdata"
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
      - name: pgdata-volume
        persistentVolumeClaim:
          claimName: {{ template "eric-data-document-database-pg.name" . }}-backup-pgdata-new
{{- end -}}
{{- end }}


{{- define "eric-data-document-database-pg.preUpgradeHookBackup-prepare" }}
{{- if .Release.IsUpgrade }}
{{- $globalValue := fromJson (include "eric-data-document-database-pg.global" .) -}}
{{- $logshipperValues := fromJson (include "eric-data-document-database-pg.ls-values" .) -}}
{{- $logshipperCopied := deepCopy . -}}
{{- $logshipperMerged := (mergeOverwrite $logshipperCopied $logshipperValues) -}}
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ template "eric-data-document-database-pg.name" . }}-backup-prepare-op
  labels: {{- include "eric-data-document-database-pg.labels.extended-defaults" . | nindent 4 }}
  annotations:
    {{- $helmHooks := dict -}}
    {{- $_ := set $helmHooks "helm.sh/hook" "pre-upgrade" -}}
    {{- $_ := set $helmHooks "helm.sh/hook-delete-policy" "hook-succeeded,before-hook-creation" -}}
    {{- $_ := set $helmHooks "helm.sh/hook-weight" "-2" -}}
    {{- $commonAnn := fromYaml (include "eric-data-document-database-pg.annotations" .) -}}
    {{- include "eric-data-document-database-pg.mergeAnnotations" (dict "location" .Template.Name "sources" (list $helmHooks $commonAnn)) | nindent 4 }}
spec:
  backoffLimit: 0
  template:
    metadata:
      labels:
        {{- $podTemplateLabels := dict -}}
        {{- $_ := set $podTemplateLabels "sidecar.istio.io/inject" "false" -}}
        {{- $_ := set $podTemplateLabels "app" (printf "%s-%s" (include "eric-data-document-database-pg.name" .) "backup-pgdata") -}}
        {{- $commonLabels := fromYaml (include "eric-data-document-database-pg.labels" .) -}}
        {{- $networkpllabels := fromYaml (include "eric-data-document-database-pg.networkpolicyp2.labels" .) -}}
        {{- include "eric-data-document-database-pg.mergeLabels" (dict "location" .Template.Name "sources" (list $commonLabels $podTemplateLabels $networkpllabels)) | nindent 8 }}
      annotations:
        {{- $podTempAnn := dict -}}
        {{- if .Values.bandwidth.cleanuphook.maxEgressRate }}
          {{- $_ := set $podTempAnn "kubernetes.io/egress-bandwidth" (.Values.bandwidth.cleanuphook.maxEgressRate | toString) -}}
        {{- end }}
        {{- $commonAnn := fromYaml (include "eric-data-document-database-pg.annotations" .) -}}
        {{- $appArmorAnn := include "eric-data-document-database-pg.appArmorProfile" (dict "root" . "Scope" "NoLSHook" "containerList" (list "backup-pgdata")) | fromYaml -}}
        {{- include "eric-data-document-database-pg.mergeAnnotations" (dict "location" .Template.Name "sources" (list $podTempAnn $appArmorAnn $commonAnn)) | trim | nindent 8 }}
    spec:
      restartPolicy: Never
      serviceAccountName: {{ template "eric-data-document-database-pg.name" . }}-pgdata-hook-fe
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
{{- include "eric-data-document-database-pg.seccompProfile" (dict "Values" .Values "Scope" "Pod") | nindent 8 }}
      {{- if or (not (empty .Values.nodeSelector.cleanuphook)) (not (eq "{}" (include "eric-data-document-database-pg.global.nodeSelector" .))) }}
      nodeSelector:
{{- include "eric-data-document-database-pg.nodeSelector.cleanuphook" . | nindent 8 }}
      {{- end }}
      tolerations:
{{ include "eric-data-document-database-pg.merge-tolerations" (dict "root" . "podbasename" "cleanuphook ") | nindent 8}}
      {{- if .Values.podPriority.cleanuphook.priorityClassName }}
      priorityClassName: {{ .Values.podPriority.cleanuphook.priorityClassName | quote }}
      {{- end }}
      containers:
        - name: backup-pgdata
          image: {{ template "eric-data-document-database-pg.kubeclientImagePath" . }}
          imagePullPolicy: {{ include "eric-data-document-database-pg.imagePullPolicy" . | quote }}
          env:
          - name: STATEFULSET_NAME
            value: {{ template "eric-data-document-database-pg.name" . }}
          - name: REPLICA_COUNT
            value: {{ .Values.highAvailability.replicaCount | quote }}
          - name: CLUSTER_NAME
            value: {{ template "eric-data-document-database-pg.name" . }}
          - name: LOG_SCHEMA
            value: {{ template "eric-data-document-database-pg.logSchema" . }}
          - name: RELEASE_NAME
            value: {{ .Release.Name | quote }}
          - name: KUBERNETES_NAMESPACE
            valueFrom: { fieldRef: { fieldPath: metadata.namespace } }
          - name: TRANSIT_COMPONENT
            value: {{ template "eric-data-document-database-pg.name" . }}-transit-pvc
          - name: TARGET_PG_VERSION
            value: "13"
          - name: PHASE
            value: "Prepare"
          {{- if include "eric-data-document-database-pg.persistentVolumeClaim.defaultStorageClassName" . }}
          - name: STORAGE_CLASSNAME
            value: {{ template "eric-data-document-database-pg.persistentVolumeClaim.defaultStorageClassName" . }}
          {{- end }}
          - name: TZ
            value: {{ $globalValue.timezone | quote }}
          - name: ENABLE_SIPTLS
            {{- if (not (eq (include "eric-data-document-database-pg.global-security-tls-enabled" .) "false")) }}
            value: "true"
            {{- else }}
            value: "false"
            {{- end }}
          - name: CONTAINER_NAME
            value:  {{ template "eric-data-document-database-pg.name" . }}-hook
          - name: LOG_REDIRECT
            value: "stdout"
          command:
            - /bin/bash
            - -c
          args:
            - "
              /usr/bin/catatonit -- 
              {{ template "eric-data-document-database-pg.stdRedirectCMD" .  }}
              {{ template "eric-data-document-database-pg.hook.scriptPath" . }}/op_backuppgdata.sh
              "
          securityContext:
            {{- include "eric-data-document-database-pg.seccompProfile" (dict "Values" .Values "Scope" "backup-pgdata") | nindent 12 }}
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
{{- end }}


{{- define "eric-data-document-database-pg.oPRestorePGDataJob" }}
{{- if .Release.IsUpgrade }}
{{- $globalValue := fromJson (include "eric-data-document-database-pg.global" .) -}}
{{- $logshipperValues := fromJson (include "eric-data-document-database-pg.ls-values" .) -}}
{{- $logshipperCopied := deepCopy . -}}
{{- $logshipperMerged := (mergeOverwrite $logshipperCopied $logshipperValues) -}}
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ template "eric-data-document-database-pg.name" . }}-restore-pgdatau-op
  labels: {{- include "eric-data-document-database-pg.labels.extended-defaults" . | nindent 4 }}
  annotations: {{- include "eric-data-document-database-pg.annotations" . | nindent 4 }}
spec:
  backoffLimit: 0
  template:
    metadata:
      labels:
        {{- $podTemplateLabels := dict -}}
        {{- $_ := set $podTemplateLabels "sidecar.istio.io/inject" "false" -}}
        {{- $_ := set $podTemplateLabels "app" (printf "%s-%s" (include "eric-data-document-database-pg.name" .) "restore-pgdata") -}}
        {{- $commonLabels := fromYaml (include "eric-data-document-database-pg.labels" .) -}}
        {{- $networkpllabels := fromYaml (include "eric-data-document-database-pg.networkpolicyp2.labels" .) -}}
        {{- include "eric-data-document-database-pg.mergeLabels" (dict "location" .Template.Name "sources" (list $commonLabels $podTemplateLabels $networkpllabels)) | nindent 8 }}
      annotations:
        {{- $podTempAnn := dict -}}
        {{- if .Values.bandwidth.cleanuphook.maxEgressRate }}
          {{- $_ := set $podTempAnn "kubernetes.io/egress-bandwidth" (.Values.bandwidth.cleanuphook.maxEgressRate | toString) -}}
        {{- end }}
        {{- $commonAnn := fromYaml (include "eric-data-document-database-pg.annotations" .) -}}
        {{- $appArmorAnn := include "eric-data-document-database-pg.appArmorProfile" (dict "root" . "Scope" "Hook" "containerList" (list "restore-pgdata")) | fromYaml -}}
        {{- include "eric-data-document-database-pg.mergeAnnotations" (dict "location" .Template.Name "sources" (list $podTempAnn $appArmorAnn $commonAnn)) | trim | nindent 8 }}
    spec:
      restartPolicy: Never
      serviceAccountName: {{ template "eric-data-document-database-pg.name" . }}-pgdata-hook-fe
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
{{- include "eric-data-document-database-pg.seccompProfile" (dict "Values" .Values "Scope" "Pod") | nindent 8 }}
      {{- if or (not (empty .Values.nodeSelector.cleanuphook)) (not (eq "{}" (include "eric-data-document-database-pg.global.nodeSelector" .))) }}
      nodeSelector:
{{- include "eric-data-document-database-pg.nodeSelector.cleanuphook" . | nindent 8 }}
      {{- end }}
      tolerations:
{{ include "eric-data-document-database-pg.merge-tolerations" (dict "root" . "podbasename" "cleanuphook ") | nindent 8}}
      {{- if .Values.podPriority.cleanuphook.priorityClassName }}
      priorityClassName: {{ .Values.podPriority.cleanuphook.priorityClassName | quote }}
      {{- end }}
      containers:
        - name: restore-pgdata
          image: {{ template "eric-data-document-database-pg.kubeclientImagePath" . }}
          imagePullPolicy: {{ include "eric-data-document-database-pg.imagePullPolicy" . | quote }}
          env:
          - name: STATEFULSET_NAME
            value: {{ template "eric-data-document-database-pg.name" . }}
          - name: REPLICA_COUNT
            value: {{ .Values.highAvailability.replicaCount | quote }}
          - name: CLUSTER_NAME
            value: {{ template "eric-data-document-database-pg.name" . }}
          - name: KUBERNETES_NAMESPACE
            valueFrom: { fieldRef: { fieldPath: metadata.namespace } }
          - name: TRANSIT_COMPONENT
            value: {{ template "eric-data-document-database-pg.name" . }}-transit-pvc
          - name: TARGET_PG_VERSION
            value: "13"
          - name: PHASE
            value: "restoredata"
          - name: LOG_SCHEMA
            value: {{ template "eric-data-document-database-pg.logSchema" . }}
          - name: TZ
            value: {{ $globalValue.timezone | quote }}
          - name: PG_TERM_PERIOD
            {{- if .Values.terminationGracePeriodSeconds }}
            value: {{ default "30" .Values.terminationGracePeriodSeconds.postgres | quote }}
            {{- else }}
            value: "30"
            {{- end }}
          - name: NETWORK_POLICY_HOOK_NAME
            value: {{ template "eric-data-document-database-pg.name" . }}-hook-op
          - name: ENABLE_SIPTLS
            {{- if (not (eq (include "eric-data-document-database-pg.global-security-tls-enabled" .) "false")) }}
            value: "true"
            {{- else }}
            value: "false"
            {{- end }}
          - name: CONTAINER_NAME
            value:  {{ template "eric-data-document-database-pg.name" . }}-hook
          - name: LOG_REDIRECT
            value: {{ template "eric-data-document-database-pg.logRedirect" . }}
          command:
            - /bin/bash
            - -c
          args:
            - "
              /usr/bin/catatonit -- 
              {{ template "eric-data-document-database-pg.stdRedirectCMD" .  }}
              /usr/bin/python {{ template "eric-data-document-database-pg.hook.scriptPath" . }}/op_postupgrade_handler.py; RES=$?; sleep 3; exit ${RES}"
          securityContext:
            {{- include "eric-data-document-database-pg.seccompProfile" (dict "Values" .Values "Scope" "restore-pgdata") | nindent 12 }}
            allowPrivilegeEscalation: false
            privileged: false
            readOnlyRootFilesystem: true
            runAsNonRoot: true
            capabilities:
              drop:
                - ALL
          volumeMounts:
          {{- include "eric-data-document-database-pg.log.mounts-hooks" $logshipperMerged | indent 12 }}
            - name: tmp
              mountPath: /tmp
            - name: pgdata-volume
              mountPath: "/var/pgdata"
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
      {{- include "eric-data-document-database-pg.log.containers-hooks" $logshipperMerged | indent 8 }}
      volumes:
      {{- include "eric-data-document-database-pg.log.volumes-hooks" $logshipperMerged | indent 6 }}
      - name: tmp
        emptyDir: {}
      - name: pgdata-volume
        persistentVolumeClaim:
          claimName: {{ template "eric-data-document-database-pg.name" . }}-backup-pgdata-new
{{- end -}}
{{- end }}

