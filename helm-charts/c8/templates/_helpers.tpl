{{/*
Expand the name of the chart.
*/}}
{{- define "c8.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "c8.fullname" -}}
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
{{- define "c8.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Generate deployment frontend pod labels
*/}}
{{- define "c8.frontendLabels" -}}
{{- if .Values.frontend.labels }}
{{- toYaml .Values.frontend.labels | nindent 4 }}
{{- end }}
{{- end -}}

{{/*
Generate deployment backend pod labels
*/}}
{{- define "c8.backendLabels" -}}
{{- if .Values.backend.labels }}
{{- toYaml .Values.backend.labels | nindent 4 }}
{{- end }}
{{- end -}}

{{/*
Generate deployment ssa pod labels
*/}}
{{- define "c8.ssaLabels" -}}
{{- if .Values.ssa.labels }}
{{- toYaml .Values.ssa.labels | nindent 4 }}
{{- end }}
{{- end -}}

{{/*
Generate deployment pns pod labels
*/}}
{{- define "c8.pnsLabels" -}}
{{- if .Values.pns.labels }}
{{- toYaml .Values.pns.labels | nindent 4 }}
{{- end }}
{{- end -}}

{{/*
Generate deployment djm pod labels
*/}}
{{- define "c8.djmLabels" -}}
{{- if .Values.djm.labels }}
{{- toYaml .Values.djm.labels | nindent 4 }}
{{- end }}
{{- end -}}


{{/*
Common labels
*/}}
{{- define "c8.labels" -}}
helm.sh/chart: {{ include "c8.chart" . }}
{{ include "c8.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "c8.selectorLabels" -}}
app.kubernetes.io/name: {{ include "c8.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the frontend service account to use
*/}}
{{- define "c8.serviceAccountNameFront" -}}
{{- if .Values.frontend.serviceAccount.create }}
{{- default (include "c8.fullname" .) .Values.frontend.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.frontend.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the backend service account to use
*/}}
{{- define "c8.serviceAccountNameBackend" -}}
{{- if .Values.backend.serviceAccount.create }}
{{- default (include "c8.fullname" .) .Values.backend.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.backend.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the djm service account to use
*/}}
{{- define "c8.serviceAccountNameDjm" -}}
{{- if .Values.djm.serviceAccount.create }}
{{- default (include "c8.fullname" .) .Values.djm.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.djm.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the crep service account to use
*/}}
{{- define "c8.serviceAccountNameCrep" -}}
{{- if .Values.crep.serviceAccount.create }}
{{- default (include "c8.fullname" .) .Values.crep.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.crep.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the djw service account to use
*/}}
{{- define "c8.serviceAccountNameDjw" -}}
{{- if .Values.djm.serviceAccount.job_worker.create }}
{{- default (include "c8.fullname" .) .Values.djm.serviceAccount.job_worker.name }}
{{- else }}
{{- default "default" .Values.djm.serviceAccount.job_worker.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the ssa service account to use
*/}}
{{- define "c8.serviceAccountNameSsa" -}}
{{- if .Values.ssa.serviceAccount.create }}
{{- default (include "c8.fullname" .) .Values.ssa.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.ssa.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the pns service account to use
*/}}
{{- define "c8.serviceAccountNamePns" -}}
{{- if .Values.pns.serviceAccount.create }}
{{- default (include "c8.fullname" .) .Values.pns.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.pns.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Return if ingress is stable.
*/}}
{{- define "c8.ingress.isStable" -}}
{{- eq (include "c8.ingress.apiVersion" .) "networking.k8s.io/v1" }}
{{- end }}

{{/*
Return if ingress supports ingressClassName.
*/}}
{{- define "c8.ingress.supportsIngressClassName" -}}
{{- or (eq (include "c8.ingress.isStable" .) "true") (and (eq (include "c8.ingress.apiVersion" .) "networking.k8s.io/v1beta1") (semverCompare ">= 1.18-0" .Capabilities.KubeVersion.Version)) }}
{{- end }}

{{/*
Return if ingress supports pathType.
*/}}
{{- define "c8.ingress.supportsPathType" -}}
{{- or (eq (include "c8.ingress.isStable" .) "true") (and (eq (include "c8.ingress.apiVersion" .) "networking.k8s.io/v1beta1") (semverCompare ">= 1.18-0" .Capabilities.KubeVersion.Version)) }}
{{- end }}

{{/*
Return the appropriate apiVersion for ingress.
*/}}
{{- define "c8.ingress.apiVersion" -}}
{{- if and ($.Capabilities.APIVersions.Has "networking.k8s.io/v1") (semverCompare ">= 1.19-0" .Capabilities.KubeVersion.Version) }}
{{- print "networking.k8s.io/v1" }}
{{- else if $.Capabilities.APIVersions.Has "networking.k8s.io/v1beta1" }}
{{- print "networking.k8s.io/v1beta1" }}
{{- else }}
{{- print "extensions/v1beta1" }}
{{- end }}
{{- end }}
