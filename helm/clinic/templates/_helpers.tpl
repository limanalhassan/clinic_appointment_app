{{- define "clinic.name" -}}
{{- .Chart.Name }}
{{- end }}

{{- define "clinic.fullname" -}}
{{- printf "%s" .Chart.Name }}
{{- end }}

{{- define "clinic.labels" -}}
app.kubernetes.io/name: {{ include "clinic.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "clinic.selectorLabels" -}}
app.kubernetes.io/name: {{ include "clinic.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
