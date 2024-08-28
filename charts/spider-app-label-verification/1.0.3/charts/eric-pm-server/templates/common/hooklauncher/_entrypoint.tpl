{{- define "eric-pm-server.hkln.findSHH" -}}
{{- $currentPath := .path -}}
{{- range $candidate, $context := .root.Subcharts }}
{{- $shhSubcharts := $.shhSubcharts -}}
{{- $productName := "" -}}
{{- with $context -}}
{{- $productName = index (fromYaml (.Files.Get "eric-product-info.yaml")) "productName" -}}
{{- end -}}
{{- if eq $productName "eric-lcm-smart-helm-hooks" -}}
{{- $shhSubchart := append $currentPath $candidate -}}
{{- $shhSubcharts = append $shhSubcharts $shhSubchart -}}
{{- $_ := set $ "shhSubcharts" $shhSubcharts -}}
{{- else -}}
{{- $findSHHArgs := dict "root" $context "path" (append $currentPath $candidate) "shhSubcharts" $shhSubcharts -}}
{{- include "eric-pm-server.hkln.findSHH" $findSHHArgs -}}
{{- $_ := set $ "shhSubcharts" $findSHHArgs.shhSubcharts -}}
{{- end -}}
{{- end -}}
{{- end -}}


{{- define "eric-pm-server.hkln.entrypoint" -}}
{{- if and (eq (include "eric-pm-server.hkln.executor" .) "integration") (has (include "eric-pm-server.name" .) (include "eric-pm-server.hkln.executorCharts" . | fromYamlArray )) -}}
{{- $topContext := . -}}
{{- $shhContext := . -}}
{{- $findSHHArgs := dict "root" . "path" list "shhSubcharts" list -}}
{{- include "eric-pm-server.hkln.findSHH" $findSHHArgs -}}
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
{{- include "eric-pm-server.hkln.manifests" (dict "shh" $shhContext "top" $topContext) -}}
{{- end -}}
{{- end -}}


{{- define "eric-pm-server.hkln.manifests" -}}
{{- if or (eq (include "eric-pm-server.hkln.executor" .top) "service") (has (include "eric-pm-server.name" .top) (include "eric-pm-server.hkln.executorCharts" .top | fromYamlArray )) -}}
{{ include "eric-pm-server.hkln.jobs" . }}
{{ include "eric-pm-server.hkln.rbac" . }}
{{- end -}}
{{- end -}}
