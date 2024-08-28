{{/* List of subcharts of this chart
     Not used, maintained for compatibility with integration charts using the
     old autodiscovery mechanism.

     Uses the template eric-data-document-database-pg.hkln.subcharts as an
     extension-point. This template is a block, so does not need to be defined
     by charts. Integration-charts are expected to fill this in with all
     SHH-enabled subcharts.
     While the documentation on subcharts advises against using blocks, the
     concern there is that if there are multiple implementations of blocks only
     one of them will be used. We avoid this problem by having each chart have a
     block with a unique name.

     This block should return a dict, with the key being the chart name or alias
     its value being the original chart name (the prefix of each named template
     within it).

     e.g.,
     {{- define "eric-data-document-database-pg.hkln.subcharts" -}}
     SUBSERVICE1_ALIAS1: SUBSERVICE1_NAME
     SUBSERVICE1_ALIAS2: SUBSERVICE1_NAME
     SUBSERVICE2_NAME: SUBSERVICE2_NAME
     {{- end -}}


     SUBSERVICE_ALIAS refers to the alias given to a given subchart, which
     matches .Chart.name of the given subchart. This alias is used to determine
     the context from .Subcharts when invoking the templates recursively.
     SUBSERVICE_NAME is the prefix of its named templates (which as per
     DR-D1121-061 is required to be the chart's name).
*/}}
{{- define "eric-data-document-database-pg.hkln.directSubcharts" -}}
{{ block "eric-data-document-database-pg.hkln.subcharts" .}}{{ end }}
{{- end -}}

{{- define "eric-data-document-database-pg.hkln.hasSHH" -}}
{{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
{{- if $productInfo -}}
{{- if hasKey (index $productInfo "images") "hooklauncher" -}}
{{- if eq (index $productInfo "productName") "eric-lcm-smart-helm-hooks" -}}
false
{{- else -}}
true
{{- end -}}
{{- else -}}
false
{{- end -}}
{{- else -}}
false
{{- end -}}
{{- end -}}


{{- define "eric-data-document-database-pg.hkln.chartInfo" -}}
{{- if eq "true" (include "eric-data-document-database-pg.hkln.hasSHH" .) }}
{{ include "eric-data-document-database-pg.hkln.name" . }}:
  jobInventorySecret: {{ include "eric-data-document-database-pg.hkln.job-inventory-secret-name" . }}
  version: {{ .Chart.Version | quote }}
{{- end -}}
{{- if eq (include "eric-data-document-database-pg.hkln.executor" .) "integration" -}}
{{- range $subChartName, $subChartContext := .Subcharts }}
{{ include "eric-data-document-database-pg.hkln.chartInfo" $subChartContext }}
{{- end -}}
{{- end -}}
{{- end -}}
