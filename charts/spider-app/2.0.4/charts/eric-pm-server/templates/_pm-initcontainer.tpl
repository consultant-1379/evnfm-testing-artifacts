{{- define "eric-pm-server.initContainer" -}}
{{- $top := index . 0 }}
{{- $pod := index . 1 }}
{{- $svcName := include "eric-pm-server.name" $top }}
{{- if eq $pod "eric-pm-promxy" }}
{{- $svcName = include "eric-pm-server.promxyName" $top }}
{{- end }}
{{- $g := fromJson (include "eric-pm-server.global" $top) -}}
- name: eric-pm-initcontainer
  image: {{ template "eric-pm-server.imagePath" (merge (dict "imageName" "eric-pm-initcontainer") $top) }}
  imagePullPolicy: {{ template "eric-pm-server.imagePullPolicy" $top }}
  securityContext:
    allowPrivilegeEscalation: false
    privileged: false
    readOnlyRootFilesystem: true
    runAsNonRoot: true
    capabilities:
      drop:
        - ALL
    {{- with (index $top.Values "seccompProfile" "eric-pm-initcontainer") }}
    seccompProfile:
    {{- toYaml . | nindent 6 }}
    {{- end }}
  args:
    - /bin/bash
    - -c
  {{- if (eq "true" (include "eric-pm-server.logShipperEnabled" $top)) }}
    - /stdout-redirect
      -redirect=all
      -logfile=/logs/pm-initenv.log
      -container=eric-pm-initcontainer
      -service-id={{ $svcName}}
      -run="/initenv"
  {{- else }}
    - /initenv
  {{- end }}
  env:
  - name: TZ
    value: {{ $g.timezone | default "UTC" | quote }}
  {{- if eq $pod "eric-pm-server" }}
  {{- if $g.security.tls.enabled }}
  - name: "ERIC_PM_SERVER_SECRETS_PMCA"
    value: /run/secrets/pmca
  - name: "ERIC_PM_SERVER_SECRETS_CLICERT"
    value: /run/secrets/clicert
  - name: "ERIC_PM_SERVER_SECRETS_PM_INT_RW_CA"
    value: /run/secrets/pm-int-rw-ca
  - name: "ERIC_PM_SERVER_SECRETS_INT_RW_CLICERT"
    value: /run/secrets/int-rw-clicert
  - name: "ERIC_PM_SERVER_SECRETS_CACERT"
    value: /run/secrets/cacert
  {{- end }}
  {{- range $ct := $top.Values.config.certm_tls }}
  - name: {{ printf "ERIC_PM_SERVER_CERTM_CA_%s" $ct.name | upper }}
    value: {{ printf "/run/secrets/remwrtca/%s" $ct.name }}
  - name: {{ printf "ERIC_PM_SERVER_CERTM_CERT_%s" $ct.name | upper }}
    value: {{ printf "/run/secrets/remwrtcert/%s" $ct.name }}
  {{- end }}
  {{- end }}
  {{- if eq $pod "eric-pm-promxy" }}
  {{- if $g.security.tls.enabled }}
  - name: "ERIC_PM_SERVER_SECRETS_PMS"
    value: /run/secrets/pms
  - name: "ERIC_PM_SERVER_SECRETS_CACERT"
    value: /run/secrets/cacert
  - name: ERIC_PM_RPROXY_CA
  {{- if not $top.Values.service.endpoints.reverseproxy.tls.certificateAuthorityBackwardCompatibility }}
    value: "/run/secrets/pmqryca"
  {{- else }}
    value: "/run/secrets/cacert"
  {{- end }}
  - name: ERIC_PM_PROMXY_METRICS_CERT
    value: "/run/secrets/pmcert"
  - name: ERIC_PM_PROMXY_METRICS_CA
    value: "/run/secrets/pmca"
  {{- end }}
  {{- end }}
  resources:
{{- include "eric-pm-server.resources" (index $top.Values "resources" "eric-pm-initcontainer") | indent 2 }}
  volumeMounts:
  {{- if eq $pod "eric-pm-server" }}
  {{- if $g.security.tls.enabled }}
  - name: pmca
    mountPath: /run/secrets/pmca
    readOnly: true
  - name: clicert
    mountPath: /run/secrets/clicert
    readOnly: true
  - name: pm-int-rw-ca
    mountPath: /run/secrets/pm-int-rw-ca
    readOnly: true
  - name: int-rw-clicert
    mountPath: /run/secrets/int-rw-clicert
    readOnly: true
  - name: cacert
    mountPath: /run/secrets/cacert
    readOnly: true
  {{- end }}
  {{- range $ct := $top.Values.config.certm_tls }}
  - name: remote-write-{{ $ct.name }}-ca
    mountPath: /run/secrets/remwrtca/{{ $ct.name }}
    readOnly: true
  - name: remote-write-{{ $ct.name }}-cert
    mountPath: /run/secrets/remwrtcert/{{ $ct.name }}
    readOnly: true
  {{- end }}
  {{- end }}
  {{- if eq $pod "eric-pm-promxy" }}
  {{- if $g.security.tls.enabled }}
  - name: pms-client-certificate
    mountPath: "/run/secrets/pms"
    readOnly: true
  {{- if not $top.Values.service.endpoints.reverseproxy.tls.certificateAuthorityBackwardCompatibility }}
  - name: pmqryca
    mountPath: "/run/secrets/pmqryca"
  {{- end }}
  - name: cacert
    mountPath: "/run/secrets/cacert"
  - name: cert
    mountPath: "/run/secrets/cert"
  - name: pmcert
    mountPath: "/run/secrets/pmcert"
    readOnly: true
  - name: pmca
    mountPath: "/run/secrets/pmca"
    readOnly: true
  {{- end }}
  {{- end }}
{{- if (eq "true" (include "eric-pm-server.logShipperEnabled" $top)) }}
{{- include "eric-log-shipper-sidecar.log-shipper-sidecar-mounts" $top | indent 2 }}
{{- end }}
{{- end }}
