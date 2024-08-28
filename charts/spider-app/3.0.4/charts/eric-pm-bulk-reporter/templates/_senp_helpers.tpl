{{- define "eric-pm-bulk-reporter.senp-tapa-sidecar-volumes" -}}
- name: spire-agent-socket
  hostPath:
    path: /run/spire/sockets
    type: Directory
- name: nsm-socket
  hostPath:
    path: /var/lib/networkservicemesh
    type: DirectoryOrCreate
- name: meridio-socket
  emptyDir: {}
{{- end }}

{{- define "eric-pm-bulk-reporter.senp-tapa-sidecar-http-probe-port" -}}
9097
{{- end }}

{{- define "eric-pm-bulk-reporter.senpEnabled" -}}
  {{- $senpEnabled := false -}}
  {{- range $k, $v := .Values.secondaryNetwork }}
      {{- if eq $v.enabled true -}}
          {{- $senpEnabled = true -}}
      {{- end }}
  {{- end }}
  {{- $senpEnabled -}}
{{- end }}

{{- define "eric-pm-bulk-reporter.senp-tapa-sidecar-container" -}}
- name: tapa
  image: {{ template "eric-pm-bulk-reporter.tapaImagePath" . }}
  imagePullPolicy: {{ template "eric-pm-bulk-reporter.pullPolicy" . }}
  env:
  - name: SPIFFE_ENDPOINT_SOCKET
    value: unix:///run/spire/sockets/agent.sock
  - name: MERIDIO_NAME
    valueFrom:
      fieldRef:
        fieldPath: metadata.name
  - name: MERIDIO_NODE
    valueFrom:
      fieldRef:
        fieldPath: spec.nodeName
  - name: LOG_LEVEL
    value: {{ .Values.env.logLevel | quote }}
  {{- if .Values.env.timezone }}
  - name: TZ
    value: {{ .Values.env.timezone | quote }}
  {{- end }}
  - name: MERIDIO_NAMESPACE
    valueFrom:
      fieldRef:
        apiVersion: v1
        fieldPath: metadata.namespace
  - name: MERIDIO_NSM_SOCKET
    value: unix:///var/lib/networkservicemesh/nsm.io.sock
  - name: MERIDIO_NSP_SERVICE_NAME
    value: "eric-tm-senp-nvip-nsp-service"
  - name: MERIDIO_NSP_SERVICE_PORT
    value: "7778"
  - name: MERIDIO_SOCKET
    value: /var/lib/meridio/ambassador.sock
  - name: NETWORK_SERVICE_PATH
    value: {{- range $_, $v := .Values.secondaryNetwork }} {{- if $v.enabled }} {{ join "," (values $v.networkServiceMap) }} {{- end}} {{- end}}
  - name: NSM_MAX_TOKEN_LIFETIME
    value: "10m"
  - name: HTTP_PROBE_PORT
    value: "{{ template "eric-pm-bulk-reporter.senp-tapa-sidecar-http-probe-port" . }}"
  - name: HTTP_PROBE_CMD_DIR
    value: "/app/"
  - name: HTTP_PROBE_SERVICE_NAME
    value: "Meridio-tapa"
  - name: HTTP_PROBE_CONTAINER_NAME
    value: "tapa"
  - name: HTTP_PROBE_POD_NAME
    valueFrom:
      fieldRef:
        apiVersion: v1
        fieldPath: metadata.name
  - name: HTTP_PROBE_NAMESPACE
    valueFrom:
      fieldRef:
        apiVersion: v1
        fieldPath: metadata.namespace
  securityContext:
    runAsNonRoot: true
    readOnlyRootFilesystem: true
    allowPrivilegeEscalation: false
    privileged: false
    capabilities:
      drop:
      - all
  startupProbe:
    httpGet:
      path: "/health/startup"
      port: {{ template "eric-pm-bulk-reporter.senp-tapa-sidecar-http-probe-port" . }}
    initialDelaySeconds: 10
    periodSeconds: 15
    timeoutSeconds: 15
    failureThreshold: 30
    successThreshold: 1
  readinessProbe:
    httpGet:
      path: "/health/readiness"
      port: {{ template "eric-pm-bulk-reporter.senp-tapa-sidecar-http-probe-port" . }}
    initialDelaySeconds: 10
    periodSeconds: 15
    timeoutSeconds: 15
    failureThreshold: 5
    successThreshold: 1
  livenessProbe:
    httpGet:
      path: "/health/liveness"
      port: {{ template "eric-pm-bulk-reporter.senp-tapa-sidecar-http-probe-port" . }}
    initialDelaySeconds: 15
    periodSeconds: 15
    timeoutSeconds: 15
    failureThreshold: 5
    successThreshold: 1
  resources: {{- include "eric-pm-bulk-reporter.resources" (index .Values "resources" "tapa") | indent 2 }}
  volumeMounts:
  - name: spire-agent-socket
    mountPath: /run/spire/sockets
    readOnly: true
  - name: nsm-socket
    mountPath: /var/lib/networkservicemesh
    readOnly: true
  - name: meridio-socket
    mountPath: /var/lib/meridio
    readOnly: false
  - name: tmp-volume
    mountPath: /tmp
{{- end -}}

{{/*
SENP tapa image path
*/}}
{{- define "eric-pm-bulk-reporter.tapaImagePath" -}}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := $productInfo.images.tapa.registry -}}
    {{- $repoPath := $productInfo.images.tapa.repoPath -}}
    {{- $name := $productInfo.images.tapa.name -}}
    {{- $tag := $productInfo.images.tapa.tag -}}

    {{- if .Values.imageCredentials.tapa -}}
        {{- if .Values.imageCredentials.tapa.registry -}}
            {{- if .Values.imageCredentials.tapa.registry.url -}}
                {{- $registryUrl = .Values.imageCredentials.tapa.registry.url -}}
            {{- end -}}
        {{- end -}}
        {{- if not (kindIs "invalid" .Values.imageCredentials.tapa.repoPath) -}}
            {{- $repoPath = .Values.imageCredentials.tapa.repoPath -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.images -}}
        {{- if .Values.images.tapaImage -}}
            {{- if .Values.images.tapaImage.name -}}
                {{- $name = .Values.images.tapaImage.name -}}
            {{- end -}}
            {{- if .Values.images.tapaImage.tag -}}
                {{- $tag = .Values.images.tapaImage.tag -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if $repoPath -}}
        {{- $repoPath = printf "%s/" $repoPath -}}
    {{- end -}}
    {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}