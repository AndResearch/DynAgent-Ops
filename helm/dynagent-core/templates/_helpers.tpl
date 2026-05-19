{{/* dynagent-core Helm chart helpers (Phase 6 Task 6d). */}}

{{- define "dynagent-core.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "dynagent-core.fullname" -}}
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

{{- define "dynagent-core.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "dynagent-core.labels" -}}
helm.sh/chart: {{ include "dynagent-core.chart" . }}
{{ include "dynagent-core.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/component: dynagent-core
app.kubernetes.io/part-of: dynagent
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "dynagent-core.selectorLabels" -}}
app.kubernetes.io/name: {{ include "dynagent-core.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "dynagent-core.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "dynagent-core.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Image reference: repository + (digest preferred over tag for prod).
Usage: {{ include "dynagent-core.imageRef" .Values.app.image }}
*/}}
{{- define "dynagent-core.imageRef" -}}
{{- $repo := .repository -}}
{{- $tag := .tag -}}
{{- $digest := .digest | default "" -}}
{{- if $digest -}}
{{ printf "%s@%s" $repo $digest }}
{{- else -}}
{{ printf "%s:%s" $repo $tag }}
{{- end -}}
{{- end }}
