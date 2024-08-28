{{- define "eric-data-document-database-pg.hkln.findSHH" -}}
{{- $currentPath := .path -}}
{{- range $candidate, $context := .root.Subcharts }}
{{- $shhSubcharts := $.shhSubcharts -}}
{{- $productName := "" -}}
{{- with $context -}}
{{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
{{- if $productInfo -}}
{{- $productName = index $productInfo "productName" -}}
{{- end -}}
{{- end -}}
{{- if eq $productName "eric-lcm-smart-helm-hooks" -}}
{{- $shhSubchart := append $currentPath $candidate -}}
{{- $shhSubcharts = append $shhSubcharts $shhSubchart -}}
{{- $_ := set $ "shhSubcharts" $shhSubcharts -}}
{{- else -}}
{{- $findSHHArgs := dict "root" $context "path" (append $currentPath $candidate) "shhSubcharts" $shhSubcharts -}}
{{- include "eric-data-document-database-pg.hkln.findSHH" $findSHHArgs -}}
{{- $_ := set $ "shhSubcharts" $findSHHArgs.shhSubcharts -}}
{{- end -}}
{{- end -}}
{{- end -}}


{{- define "eric-data-document-database-pg.hkln.entrypoint" -}}
{{- if and (eq (include "eric-data-document-database-pg.hkln.executor" .) "integration") (has (include "eric-data-document-database-pg.name" .) (include "eric-data-document-database-pg.hkln.executorCharts" . | fromYamlArray )) -}}
{{- $topContext := . -}}
{{- $shhContext := . -}}
{{- $findSHHArgs := dict "root" . "path" list "shhSubcharts" list -}}
{{- include "eric-data-document-database-pg.hkln.findSHH" $findSHHArgs -}}
{{- $paths := $findSHHArgs.shhSubcharts -}}
{{- if eq (len $paths) 0 -}}
{{- fail (printf "Smart Helm Hooks subchart is not included in the integration chart!") -}}
{{- end -}}
{{- if gt (len $paths) 1 -}}
{{- fail (printf "Found multiple Smart Helm Hooks subcharts: %s" $paths) -}}
{{- end -}}
{{- $path := index $paths 0 -}}
{{- $chart := index .Subcharts (first $path) -}}
{{- range $pathSegment := (rest $path) -}}
{{- $chart = index $chart.Subcharts $pathSegment -}}
{{- end -}}
{{- $shhContext = $chart -}}
{{- $_ := set $shhContext "Template" $topContext.Template -}}
{{- include "eric-data-document-database-pg.hkln.manifests" (dict "shh" $shhContext "top" $topContext) -}}
{{- end -}}
{{- end -}}


{{- define "eric-data-document-database-pg.hkln.manifests" -}}
{{- if or (eq (include "eric-data-document-database-pg.hkln.executor" .top) "service") (has (include "eric-data-document-database-pg.name" .top) (include "eric-data-document-database-pg.hkln.executorCharts" .top | fromYamlArray )) -}}
{{ include "eric-data-document-database-pg.hkln.jobs" . }}
{{ include "eric-data-document-database-pg.hkln.rbac" . }}
{{- end -}}
{{- end -}}
