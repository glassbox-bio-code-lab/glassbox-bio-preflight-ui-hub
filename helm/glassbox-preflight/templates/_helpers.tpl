{{- define "preflight.name" -}}
glassbox-preflight
{{- end -}}

{{- define "preflight.fullname" -}}
{{- printf "%s-preflight" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "preflight.labels" -}}
app.kubernetes.io/name: {{ include "preflight.name" . }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name (.Chart.Version | replace "+" "_") }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "preflight.selectorLabels" -}}
app.kubernetes.io/name: {{ include "preflight.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "preflight.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "preflight.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "preflight.dataClaimName" -}}
{{- $existingClaim := (((.Values.storage).pvc).existingClaim | default "") -}}
{{- default (default (printf "%s-data" (include "preflight.fullname" .)) .Values.app.dataPvc) $existingClaim -}}
{{- end -}}

{{- define "preflight.image" -}}
{{- if .digest -}}
{{ printf "%s@%s" .repository .digest }}
{{- else -}}
{{ printf "%s:%s" .repository .tag }}
{{- end -}}
{{- end -}}

{{- define "preflight.authSecretName" -}}
{{- if .Values.auth.existingSecret -}}
{{- .Values.auth.existingSecret -}}
{{- else -}}
{{- printf "%s-auth" (include "preflight.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "preflight.authTokensJson" -}}
{{- $secretName := include "preflight.authSecretName" . -}}
{{- $existing := lookup "v1" "Secret" .Release.Namespace $secretName -}}
{{- if and $existing (hasKey $existing.data "K8S_API_TOKENS") -}}
{{ index $existing.data "K8S_API_TOKENS" | b64dec }}
{{- else if and $existing (hasKey $existing.data "K8S_API_TOKEN") -}}
{{ toJson (list (dict "token" (index $existing.data "K8S_API_TOKEN" | b64dec) "user" "preflight-admin" "role" "admin")) }}
{{- else if (.Values.auth.tokensJson | trim) -}}
{{ .Values.auth.tokensJson | trim }}
{{- else if (.Values.app.authToken | trim) -}}
{{ toJson (list (dict "token" (.Values.app.authToken | trim) "user" "preflight-admin" "role" "admin")) }}
{{- else -}}
{{ toJson (list (dict "token" (randAlphaNum 32) "user" "preflight-admin" "role" "admin")) }}
{{- end -}}
{{- end -}}

{{- define "preflight.addonDefinitionById" -}}
{{- $root := index . 0 -}}
{{- $addonId := index . 1 -}}
{{- $match := dict -}}
{{- range $entry := $root.Values.addons.registry }}
  {{- if eq (($entry.id | default "") | toString) ($addonId | toString) }}
    {{- $match = $entry -}}
  {{- end }}
{{- end }}
{{- toYaml $match -}}
{{- end -}}

{{- define "preflight.addonInstallationValues" -}}
{{- $root := index . 0 -}}
{{- $addonId := index . 1 -}}
{{- $legacy := (index $root.Values.addons $addonId) | default dict -}}
{{- $installations := (index $root.Values.addons "installations") | default dict -}}
{{- $override := (index $installations $addonId) | default dict -}}
{{- $merged := mergeOverwrite (deepCopy $legacy) $override -}}
{{- toYaml $merged -}}
{{- end -}}

{{- define "preflight.addonServiceAccountName" -}}
{{- $root := index . 0 -}}
{{- $addon := index . 1 -}}
{{- $values := (include "preflight.addonInstallationValues" (list $root $addon.id) | fromYaml) | default dict -}}
{{- $name := (($addon.install.serviceAccountName | default "") | toString) | default ((get $values "serviceAccountName") | default "") -}}
{{- if $name -}}
{{ $name }}
{{- else -}}
{{ printf "gbx-%s-runner" $addon.id }}
{{- end -}}
{{- end -}}

{{- define "preflight.addonConfigMapName" -}}
{{- $root := index . 0 -}}
{{- $addon := index . 1 -}}
{{- $values := (include "preflight.addonInstallationValues" (list $root $addon.id) | fromYaml) | default dict -}}
{{- $name := (($addon.install.configMapName | default "") | toString) | default ((get $values "configMapName") | default "") -}}
{{- if $name -}}
{{ $name }}
{{- else -}}
{{ printf "gbx-%s-addon" $addon.id }}
{{- end -}}
{{- end -}}

{{- define "preflight.addonRunnerImage" -}}
{{- $root := index . 0 -}}
{{- $addon := index . 1 -}}
{{- $values := (include "preflight.addonInstallationValues" (list $root $addon.id) | fromYaml) | default dict -}}
{{- $runnerImage := (get $values "runnerImage") | default "" -}}
{{- if $runnerImage -}}
{{ $runnerImage }}
{{- else -}}
  {{- $image := (get $values "image") | default dict -}}
  {{- if and (kindIs "map" $image) (get $image "repository") -}}
{{ include "preflight.image" $image }}
  {{- end -}}
{{- end -}}
{{- end -}}

{{- define "preflight.addonConfigData" -}}
{{- $root := index . 0 -}}
{{- $addon := index . 1 -}}
{{- $values := (include "preflight.addonInstallationValues" (list $root $addon.id) | fromYaml) | default dict -}}
{{- $install := ($addon.install | default dict) -}}
{{- $configData := (deepCopy ((get $values "configData") | default dict)) -}}
{{- $projectsDirKey := (($install.projectsDirKey | default "") | toString | trim) -}}
{{- if and $projectsDirKey (hasKey $values $projectsDirKey) (not (hasKey $configData $projectsDirKey)) }}
  {{- $_ := set $configData $projectsDirKey (get $values $projectsDirKey) -}}
{{- end }}
{{- if and (hasKey $values "secretRefs") (not (hasKey $configData "secretRefs")) }}
  {{- $_ := set $configData "secretRefs" (get $values "secretRefs") -}}
{{- end }}
{{- toYaml $configData -}}
{{- end -}}
