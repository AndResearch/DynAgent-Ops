{{/*
Expand the name of the chart.
*/}}
{{- define "dynagent.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "dynagent.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "dynagent.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "dynagent.labels" -}}
helm.sh/chart: {{ include "dynagent.chart" . }}
{{ include "dynagent.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "dynagent.selectorLabels" -}}
app.kubernetes.io/name: {{ include "dynagent.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "dynagent.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "dynagent.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Database host - returns Cloud SQL proxy localhost or internal PostgreSQL service
*/}}
{{- define "dynagent.databaseHost" -}}
{{- if .Values.database.external }}
{{- .Values.database.host }}
{{- else }}
{{- printf "%s-postgresql" (include "dynagent.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Build an image reference from repository + (digest or tag).
Usage:
{{ include "dynagent.imageRef" (dict "repository" .Values.app.image.repository "tag" .Values.app.image.tag "digest" .Values.app.image.digest) }}
*/}}
{{- define "dynagent.imageRef" -}}
{{- $repo := .repository -}}
{{- $tag := .tag -}}
{{- $digest := .digest | default "" -}}
{{- if $digest -}}
{{ printf "%s@%s" $repo $digest }}
{{- else -}}
{{ printf "%s:%s" $repo $tag }}
{{- end -}}
{{- end }}
