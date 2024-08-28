{{- define "eric-pm-server.configmap-reload" -}}
{{- $top := index . 0 }}
{{- $port := index . 1 }}
{{- $svcName := include "eric-pm-server.name" $top }}
{{- if eq $port "8082" }}
{{- $svcName = include "eric-pm-server.promxyName" $top }}
{{- end }}
{{- $g := fromJson (include "eric-pm-server.global" $top) -}}
- name: eric-pm-configmap-reload
  image: {{ template "eric-pm-server.imagePath" (merge (dict "imageName" "eric-pm-configmap-reload") $top ) }}
  imagePullPolicy: {{ template "eric-pm-server.imagePullPolicy" $top }}
  securityContext:
    allowPrivilegeEscalation: false
    privileged: false
    readOnlyRootFilesystem: true
    runAsNonRoot: true
    capabilities:
      drop:
        - ALL
    {{- with (index $top.Values "seccompProfile" "eric-pm-configmap-reload") }}
    seccompProfile:
    {{- toYaml . | nindent 6 }}
    {{- end }}
  args:
    - /bin/bash
    - -c
    - /stdout-redirect
      -service-id={{ $svcName }}
      -container=eric-pm-configmap-reload
      -redirect={{ template "eric-pm-server.log.outputs" $top }}
      -logfile=/logs/configmap-reload.log
      {{- if $top.Values.log }}
      {{- if $top.Values.log.format }}
      {{- if eq $top.Values.log.format "json" }}
      -config=/etc/stdout_redirect_config/config.yml
      -format={{ $top.Values.log.format }}
      {{- end }}
      {{- end }}
      {{- end }}
      -run="/initenv
            --web.listen-address=0.0.0.0:9085
            --volume-dir=/etc/config
            {{- if ne $port "8082" }}
            {{- range $top.Values.server.extraConfigmapMounts }}
            --volume-dir={{ .mountPath }}
            {{- end }}
            {{- end }}
            --webhook-url={{ template "eric-pm-server.configmap-reload.webhook" . }}"
  env:
    - name: POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
    - name: POD_NAMESPACE
      valueFrom:
        fieldRef:
          fieldPath: metadata.namespace
    - name: TZ
      value: {{ $g.timezone | default "UTC" | quote }}
  resources:
{{- include "eric-pm-server.resources" (index $top.Values "resources" "eric-pm-configmap-reload") | indent 2 }}
  volumeMounts:
{{- if (eq "true" (include "eric-pm-server.logShipperEnabled" $top)) }}
{{- include "eric-log-shipper-sidecar.log-shipper-sidecar-mounts" $top | indent 4 }}
{{- end }}
    {{- if $top.Values.log }}
    {{- if $top.Values.log.format }}
    {{- if eq $top.Values.log.format "json" }}
    - name: stdout-redirect-volume
      mountPath: /etc/stdout_redirect_config
    {{- end }}
    {{- end }}
    {{- end }}
    - name: config-volume
      mountPath: /etc/config
      readOnly: true
  {{- if ne $port "8082" }}
  {{- range $ct := $top.Values.server.extraConfigmapMounts }}
    - name: {{ template "eric-pm-server.name" $top }}-{{ $ct.name }}
      mountPath: {{ $ct.mountPath }}
      readOnly: {{ $ct.readOnly }}
  {{- end }}
  {{- end }}
  readinessProbe:
    httpGet:
      port: 9085
      scheme: HTTP
{{ toYaml $top.Values.probes.configmapreload.readinessProbe | indent 4 }}
  livenessProbe:
    httpGet:
      port: 9085
      scheme: HTTP
{{ toYaml $top.Values.probes.configmapreload.livenessProbe | indent 4 }}
{{- end }}
