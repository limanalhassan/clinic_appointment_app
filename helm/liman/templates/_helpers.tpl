{{- define "liman.name" -}}
{{- .Chart.Name }}
{{- end }}

{{- define "liman.fullname" -}}
{{- printf "%s" .Chart.Name }}
{{- end }}

{{- define "liman.labels" -}}
app.kubernetes.io/name: {{ include "liman.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "liman.selectorLabels" -}}
app.kubernetes.io/name: {{ include "liman.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
