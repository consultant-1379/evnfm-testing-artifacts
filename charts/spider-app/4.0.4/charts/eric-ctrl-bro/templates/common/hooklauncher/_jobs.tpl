{{- define "eric-ctrl-bro.hkln.jobs" -}}

--- # Install
{{ include "eric-ctrl-bro.hkln.job" (dict "root" . "helmHook" "post-install" "trigger" "post-install" "suffix" "postin" "weight" "-200") }}

--- # Rollback
{{ include "eric-ctrl-bro.hkln.job" (dict "root" . "helmHook" "pre-rollback" "trigger" "pre-phase-version-stepping" "suffix" "stepr" "weight" "-201") }}
---
{{ include "eric-ctrl-bro.hkln.job" (dict "root" . "helmHook" "pre-rollback" "trigger" "pre-rollback" "suffix" "prero" "weight" "-200") }}
---
{{ include "eric-ctrl-bro.hkln.job" (dict "root" . "helmHook" "post-rollback" "trigger" "post-rollback" "suffix" "postr" "weight" "200") }}

--- # Upgrade
{{ include "eric-ctrl-bro.hkln.job" (dict "root" . "helmHook" "pre-upgrade" "trigger" "pre-phase-version-stepping" "suffix" "stepu" "weight" "-201") }}
---
{{ include "eric-ctrl-bro.hkln.job" (dict "root" . "helmHook" "pre-upgrade" "trigger" "pre-upgrade" "suffix" "preup" "weight" "-200") }}
---
{{ include "eric-ctrl-bro.hkln.job" (dict "root" . "helmHook" "post-upgrade" "trigger" "post-upgrade" "suffix" "postu" "weight" "200") }}

{{- end -}}
