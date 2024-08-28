{{- define "eric-pm-bulk-reporter.roleBinding.reference" -}}
{{- $g := fromJson (include "eric-pm-bulk-reporter.global" .) -}}
  {{- if $g -}}
    {{- if $g.security -}}
      {{- if $g.security.policyReferenceMap -}}
        {{ $mapped := index .Values "global" "security" "policyReferenceMap" "plc-38dc0a0ee2b2564ef10039d2c6c0e0" }}
        {{- if $mapped -}}
          {{ $mapped }}
        {{- else -}}
          plc-38dc0a0ee2b2564ef10039d2c6c0e0
        {{- end -}}
      {{- else -}}
        plc-38dc0a0ee2b2564ef10039d2c6c0e0
      {{- end -}}
    {{- else -}}
      plc-38dc0a0ee2b2564ef10039d2c6c0e0
    {{- end -}}
  {{- else -}}
    plc-38dc0a0ee2b2564ef10039d2c6c0e0
  {{- end -}}
{{- end -}}

# Automatically generated annotations for documentation purposes.
{{- define "eric-pm-bulk-reporter.roleBinding.annotations" -}}
  {{- $static := dict -}}
  {{- $_ := set $static "ericsson.com/security-policy.type" "restricted/custom" -}}
  {{- $_ := set $static "ericsson.com/security-policy.capabilities" "audit_write chown kill net_bind_service setgid setuid sys_chroot" -}}
  {{- $annotations := include "eric-pm-bulk-reporter.annotations" . | fromYaml -}}
  {{- include "eric-pm-bulk-reporter.mergeAnnotations" (dict "location" (.Template.Name) "sources" (list $static $annotations)) | trim }}
{{- end -}}

{{- define "eric-pm-bulk-reporter.securityPolicy.rolekind" -}}
{{- $g := fromJson (include "eric-pm-bulk-reporter.global" .) -}}
{{- .Values.global.securityPolicy.rolekind -}}
{{- end -}}

{{- define "eric-pm-bulk-reporter.securityPolicy.rolename" -}}
{{- default "eric-pm-bulk-reporter" ( index .Values.securityPolicy "eric-pm-bulk-reporter" "rolename" ) -}}
{{- end -}}

{{- define "eric-pm-bulk-reporter.helmtest.securityPolicy.rolename" -}}
{{- default "eric-pm-bulk-reporter-helmtest" .Values.securityPolicy.helmtest.rolename -}}
{{- end -}}

{{/*
Function to check for DR-D1123-134 and DR-D1123-124
*/}}
{{- define "eric-pm-bulk-reporter.securityPolicy" -}}
{{- $createFlag := "false" -}}
{{- $oldPolicyFlag := "false" -}}
{{- $g := fromJson (include "eric-pm-bulk-reporter.global" .) -}}
{{- if $g -}}
  {{- if $g.securityPolicy -}}
    {{- if $g.securityPolicy.rolekind -}}
      {{- if and (ne .Values.global.securityPolicy.rolekind "Role") (ne .Values.global.securityPolicy.rolekind "ClusterRole") -}}
        {{- printf "For global.securityPolicy.rolekind is not set correctly." | fail -}}
      {{- end -}}
      {{- $createFlag = "true" -}}
    {{- else -}}
      {{- $createFlag = "false" -}}
    {{- end -}}
  {{- else if $g.security -}}
    {{- if $g.security.policyBinding -}}
      {{- if $g.security.policyBinding.create -}}
        {{- $createFlag = "true" -}}
        {{- $oldPolicyFlag = "true" -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- dict "createFlag" $createFlag "oldPolicyFlag" $oldPolicyFlag | toJson -}}
{{- end -}}

{{- define "eric-pm-bulk-reporter.securityPolicy.rolebinding.name" -}}
{{- if (eq "true" .oldPolicyFlag) }}
{{- print (include "eric-pm-bulk-reporter.name" .root ) "-security-policy" -}}
{{- else }}
{{- if (eq (include "eric-pm-bulk-reporter.securityPolicy.rolekind" .root) "Role") }}
{{- print (include "eric-pm-bulk-reporter.name" .root ) "-r-" (include "eric-pm-bulk-reporter.securityPolicy.rolename" .root ) "-sp" -}}
{{- else if (eq (include "eric-pm-bulk-reporter.securityPolicy.rolekind" .root) "ClusterRole") }}
{{- print (include "eric-pm-bulk-reporter.name" .root ) "-c-" (include "eric-pm-bulk-reporter.securityPolicy.rolename" .root ) "-sp" -}}
{{- end }}
{{- end }}
{{- end -}}

{{- define "eric-pm-bulk-reporter.helmtest.securityPolicy.rolebinding.name" -}}
{{- if (eq (include "eric-pm-bulk-reporter.securityPolicy.rolekind" .) "Role") }}
{{- print (include "eric-pm-bulk-reporter.helmtest.serviceAccountName" .) "-r-" (include "eric-pm-bulk-reporter.helmtest.securityPolicy.rolename" . ) "-sp" -}}
{{- else if (eq (include "eric-pm-bulk-reporter.securityPolicy.rolekind" .) "ClusterRole") }}
{{- print (include "eric-pm-bulk-reporter.helmtest.serviceAccountName" .) "-c-" (include "eric-pm-bulk-reporter.helmtest.securityPolicy.rolename" . ) "-sp" -}}
{{- end }}
{{- end -}}

{{- define "eric-pm-bulk-reporter.helmtest.serviceAccountName" -}}
{{- print ( include "eric-pm-bulk-reporter.name" . ) "-helmtest-sa" -}}
{{- end -}}