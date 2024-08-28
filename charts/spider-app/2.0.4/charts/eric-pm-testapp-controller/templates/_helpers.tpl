{{/*
Expand the name of the chart.
*/}}
{{- define "eric-pm-testapp-controller.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart version as used by the chart label.
*/}}
{{- define "eric-pm-testapp-controller.version" -}}
{{- printf "%s" .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create image registry url
*/}}
{{- define "eric-pm-testapp-controller.registryUrl" -}}
{{- if .Values.imageCredentials.registry.url -}}
{{- print .Values.imageCredentials.registry.url -}}
{{- else -}}
{{- print .Values.global.registry.url -}}
{{- end -}}
{{- end -}}

{{/*
Create image pull secrets
*/}}
{{- define "eric-pm-testapp-controller.pullSecrets" -}}
{{- if .Values.imageCredentials.pullSecret -}}
{{- print .Values.imageCredentials.pullSecret -}}
{{- else if .Values.global.pullSecret -}}
{{- print .Values.global.pullSecret -}}
{{- end -}}
{{- end -}}


{{/*
Create Ericsson product specific annotations
*/}}
{{- define "eric-pm-testapp-controller.helm-annotations" -}}
annotations:
  ericsson.com/product-name: "ADP CICD PM Testapp Controller"
  ericsson.com/product-number: "CAV 101 XXX/X"
  ericsson.com/product-revision: "R1A"
{{- end -}}

{{/*
Create Pod Annotations
*/}}
{{- define "eric-pm-testapp-controller.annotations" }}
  ericsson.com/nf-name: "spider-app-multi-b-v2"
{{- end}}