{{/*
Create chart version as used by the chart label.
*/}}
{{- define "busybox-simple-chart.version" -}}
{{- printf "%s" .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "busybox-simple-chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "busybox-simple-chart.product-info" }}
ericsson.com/product-name: "Example Product"
ericsson.com/product-number: "CXP90001/2"
ericsson.com/product-revision: "{{.Values.productInfo.rstate}}"
{{- end}}
