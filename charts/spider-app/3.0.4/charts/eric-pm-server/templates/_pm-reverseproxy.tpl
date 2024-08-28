{{- define "eric-pm-server.reverseProxy" -}}
{{- $top := index . 0 }}
{{- $port := index . 1 }}
{{- $svcName := include "eric-pm-server.name" $top }}
{{- $g := fromJson (include "eric-pm-server.global" $top) -}}
- name: eric-pm-reverseproxy
  ports:
    - name: http-metrics
      containerPort: 9088
      protocol: TCP
    - name: http-rproxy-pm
      containerPort: 9089
      protocol: TCP
{{- if eq $port "8082" }}
{{- $svcName = include "eric-pm-server.promxyName" $top }}
    - name: https-tls
      containerPort: 9084
      protocol: TCP
{{- end }}
  image: {{ template "eric-pm-server.imagePath" (merge (dict "imageName" "eric-pm-reverseproxy") $top) }}
  imagePullPolicy: {{ template "eric-pm-server.imagePullPolicy" $top }}
  securityContext:
    allowPrivilegeEscalation: false
    privileged: false
    readOnlyRootFilesystem: true
    runAsNonRoot: true
    capabilities:
      drop:
        - ALL
    {{- with (index $top.Values "seccompProfile" "eric-pm-reverseproxy") }}
    seccompProfile:
    {{- toYaml . | nindent 6 }}
    {{- end }}
  args:
    - /bin/bash
    - -c
  {{- if (eq "true" (include "eric-pm-server.logShipperEnabled" $top)) }}
    - /stdout-redirect
      -service-id={{ $svcName }}
      -container=eric-pm-reverseproxy
      -redirect={{ template "eric-pm-server.log.outputs" $top }}
      -logfile=/logs/pm-reverseproxy.log
      -run="/initenv"
  {{- else }}
    - /initenv
  {{- end }}
  env:
    - name: SERVICE_NAME
{{- if eq $port "8082" }}
      value: {{ include "eric-pm-server.promxyName" $top | quote }}
{{- else }}
      value: {{ include "eric-pm-server.name" $top | quote }}
{{- end}}
    - name: PM_TLS_PORT
      value: "9089"
    - name: LOG_LEVEL
      value: {{ $top.Values.logLevel }}
    - name: SERVER_CERTIFICATE_AUTHORITY
    {{- if not $top.Values.service.endpoints.reverseproxy.tls.certificateAuthorityBackwardCompatibility }}
      value: "/run/secrets/pmqryca/query-cacertbundle.pem"
    {{- else }}
      value: "/run/secrets/cacert/cacertbundle.pem"
    {{- end}}
    {{- if eq $port "8082" }}
    {{- if eq $top.Values.promxy.endpoints.pmScrapeTarget.tls.enforced "required" }}
    - name: TLS_SCRAPE_REQUIRED
      value: {{ true | quote }}
    {{- else }}
    - name: TLS_SCRAPE_REQUIRED
      value: {{ false | quote }}
    {{- end }}
    - name: TLS_SCRAPE_VERIFY_CLIENT_REQUIRED
      value: {{ default "required" $top.Values.promxy.endpoints.pmScrapeTarget.tls.verifyClientCertificate }}
    - name: PROMXY_ENABLED
      value: {{ true | quote }}
    {{- end }}
    - name: SERVER_CERTIFICATE_DIR
      value: "/run/secrets/cert"
    - name: CLIENT_TLS_VERIFICATION
      value: {{ default "required" $top.Values.service.endpoints.reverseproxy.tls.verifyClientCertificate | quote }}
    - name: PM_HOST
      value: {{ printf "http://localhost:%s" $port }}
    - name: RW_TIMEOUT
      value: {{ $top.Values.service.endpoints.reverseproxy.readWriteTimeout | quote }}
    - name: TZ
      value: {{ $g.timezone | default "UTC" | quote }}
    - name: CONTAINER_NAME
      value: eric-pm-reverseproxy
    - name: NAMESPACE
      value: {{ $top.Release.Namespace }}
    - name: POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
  readinessProbe:
    httpGet:
      path: "/readiness"
      port: 9088
{{ toYaml $top.Values.probes.reverseproxy.readinessProbe | indent 4 }}
  livenessProbe:
    httpGet:
      path: "/liveness"
      port: 9088
{{ toYaml $top.Values.probes.reverseproxy.livenessProbe | indent 4 }}
  resources:
{{- include "eric-pm-server.resources" (index $top.Values "resources" "eric-pm-reverseproxy") | indent 2 }}
  volumeMounts:
    {{- if not $top.Values.service.endpoints.reverseproxy.tls.certificateAuthorityBackwardCompatibility }}
    - name: pmqryca
      mountPath: "/run/secrets/pmqryca"
    {{- else }}
    - name: cacert
      mountPath: "/run/secrets/cacert"
    {{- end }}
{{- if (eq "true" (include "eric-pm-server.logShipperEnabled" $top)) }}
{{- include "eric-log-shipper-sidecar.log-shipper-sidecar-mounts" $top | indent 4 }}
{{- end}}
    - name: cert
      mountPath: "/run/secrets/cert"
{{- if eq $port "8082" }}
    - name: pmcert
      mountPath: "/run/secrets/pmcert"
      readOnly: true
    - name: pmca
      mountPath: "/run/secrets/pmca"
      readOnly: true
{{- end }}
{{- end }}
