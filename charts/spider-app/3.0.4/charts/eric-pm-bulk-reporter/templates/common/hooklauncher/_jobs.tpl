{{- define "eric-pm-bulk-reporter.hkln.jobs" -}}

--- # Install
{{ include "eric-pm-bulk-reporter.hkln.job" (dict "root" . "helmHook" "post-install" "trigger" "post-install" "suffix" "postin" "weight" "-200") }}

--- # Rollback
{{ include "eric-pm-bulk-reporter.hkln.job" (dict "root" . "helmHook" "pre-rollback" "trigger" "pre-phase-version-stepping" "suffix" "stepr" "weight" "-201") }}
---
{{ include "eric-pm-bulk-reporter.hkln.job" (dict "root" . "helmHook" "pre-rollback" "trigger" "pre-rollback" "suffix" "prero" "weight" "-200") }}
---
{{ include "eric-pm-bulk-reporter.hkln.job" (dict "root" . "helmHook" "post-rollback" "trigger" "post-rollback" "suffix" "postr" "weight" "200") }}

--- # Upgrade
{{ include "eric-pm-bulk-reporter.hkln.job" (dict "root" . "helmHook" "pre-upgrade" "trigger" "pre-phase-version-stepping" "suffix" "stepu" "weight" "-201") }}
---
{{ include "eric-pm-bulk-reporter.hkln.job" (dict "root" . "helmHook" "pre-upgrade" "trigger" "pre-upgrade" "suffix" "preup" "weight" "-200") }}
---
{{ include "eric-pm-bulk-reporter.hkln.job" (dict "root" . "helmHook" "post-upgrade" "trigger" "post-upgrade" "suffix" "postu" "weight" "200") }}

{{- end -}}
