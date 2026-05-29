{{/*
Expand the name of the chart.
*/}}
{{- define "garage.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "garage.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create the name of the rpc secret
*/}}
{{- define "garage.rpcSecretName" -}}
{{- .Values.garage.existingRpcSecret | default (printf "%s-rpc-secret" (include "garage.fullname" .)) -}}
{{- end }}

{{/*
Create the name of the Garage config map.
*/}}
{{- define "garage.configMapName" -}}
{{- .Values.garage.existingConfigMap | default (printf "%s-config" (include "garage.fullname" .)) -}}
{{- end }}

{{/*
Create the Garage container image reference.
*/}}
{{- define "garage.image" -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion -}}
{{- if .Values.image.digest -}}
{{- printf "%s@%s" .Values.image.repository .Values.image.digest -}}
{{- else if hasPrefix "@" $tag -}}
{{- printf "%s%s" .Values.image.repository $tag -}}
{{- else -}}
{{- printf "%s:%s" .Values.image.repository $tag -}}
{{- end -}}
{{- end }}

{{/*
Create the Garage init container image reference.
*/}}
{{- define "garage.initImage" -}}
{{- if .Values.initImage.digest -}}
{{- printf "%s@%s" .Values.initImage.repository .Values.initImage.digest -}}
{{- else if hasPrefix "@" .Values.initImage.tag -}}
{{- printf "%s%s" .Values.initImage.repository .Values.initImage.tag -}}
{{- else -}}
{{- printf "%s:%s" .Values.initImage.repository .Values.initImage.tag -}}
{{- end -}}
{{- end }}

{{/*
Create the Garage UI container image reference.
*/}}
{{- define "garage.uiImage" -}}
{{- if .Values.ui.image.digest -}}
{{- printf "%s@%s" .Values.ui.image.repository .Values.ui.image.digest -}}
{{- else if hasPrefix "@" .Values.ui.image.tag -}}
{{- printf "%s%s" .Values.ui.image.repository .Values.ui.image.tag -}}
{{- else -}}
{{- printf "%s:%s" .Values.ui.image.repository .Values.ui.image.tag -}}
{{- end -}}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "garage.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "garage.labels" -}}
helm.sh/chart: {{ include "garage.chart" . }}
{{ include "garage.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{- toYaml . | nindent 0 }}
{{- end }}
{{- end }}

{{/*
Common annotations
*/}}
{{- define "garage.annotations" -}}
{{- with .Values.commonAnnotations }}
{{- toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "garage.selectorLabels" -}}
app.kubernetes.io/name: {{ include "garage.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "garage.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "garage.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the Garage UI service account to use
*/}}
{{- define "garage.uiServiceAccountName" -}}
{{- if .Values.ui.serviceAccount.create }}
{{- default (include "garage.uiFullname" .) .Values.ui.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.ui.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create a default Garage UI name.
*/}}
{{- define "garage.uiName" -}}
{{- printf "%s-ui" (include "garage.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Create a default fully qualified Garage UI app name.
*/}}
{{- define "garage.uiFullname" -}}
{{- printf "%s-ui" (include "garage.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Selector labels for Garage UI.
*/}}
{{- define "garage.uiSelectorLabels" -}}
app.kubernetes.io/name: {{ include "garage.uiName" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: ui
{{- end }}

{{/*
Common labels for Garage UI.
*/}}
{{- define "garage.uiLabels" -}}
helm.sh/chart: {{ include "garage.chart" . }}
{{ include "garage.uiSelectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{- toYaml . | nindent 0 }}
{{- end }}
{{- end }}

{{/*
Resolve the Garage UI S3 endpoint.
*/}}
{{- define "garage.uiEndpoint" -}}
{{- if .Values.ui.s3.endpoint -}}
{{- .Values.ui.s3.endpoint -}}
{{- else -}}
{{- printf "%s.%s.svc.cluster.local:%v" (include "garage.fullname" .) .Release.Namespace (.Values.service.s3.api.port | int) -}}
{{- end -}}
{{- end }}

{{/*
    Returns given number of random Hex characters.
    In practice, it generates up to 100 randAlphaNum strings
    that are filtered from non-hex characters and augmented
    to the resulting string that is finally trimmed down.
*/}}
{{- define "garage.randHex" -}}
    {{- $result := "" }}
    {{- range $i := until 100 }}
        {{- if lt (len $result) . }}
            {{- $rand_list := randAlphaNum . | splitList "" -}}
            {{- $reduced_list := without $rand_list "g" "h" "i" "j" "k" "l" "m" "n" "o" "p" "q" "r" "s" "t" "u" "v" "w" "x" "y" "z" "A" "B" "C" "D" "E" "F" "G" "H" "I" "J" "K" "L" "M" "N" "O" "P" "Q" "R" "S" "T" "U" "V" "W" "X" "Y" "Z" }}
            {{- $rand_string := join "" $reduced_list }}
            {{- $result = print $result $rand_string -}}
        {{- end }}
    {{- end }}
    {{- $result | trunc . }}
{{- end }}
