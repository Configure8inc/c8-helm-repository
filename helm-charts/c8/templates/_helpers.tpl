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
{{- define "c8.serviceAccountNameBack" -}}
{{- if .Values.backend.serviceAccount.create }}
{{- default (include "c8.fullname" .) .Values.backend.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.backend.serviceAccount.name }}
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


{{/*
Params from the AWS SSM
*/}}
{{- define "helpers.list-env-variables-aws-parameter-store" }}
{{- if .Values.aws_parameter_store.enabled -}}
{{- $name := .Values.aws_parameter_store.secret_name }}
{{- range $key, $value := .Values.aws_parameter_store.data }}
- name: {{ $value.secretKey }}
  valueFrom:
    secretKeyRef:
      name: "{{ $name }}"
      key: {{ $value.secretKey }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Params from the AWS Secret Manager
*/}}
{{- define "helpers.list-env-variables-aws-secrets-manager" }}
{{- if .Values.aws_secrets_manager.enabled -}}
{{- $name := .Values.aws_secrets_manager.secret_name }}
{{- range $key, $value := .Values.aws_secrets_manager.data }}
- name: {{ $value.secretKey }}
  valueFrom:
    secretKeyRef:
      name: "{{ $name }}"
      key: {{ $value.secretKey }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Envs
*/}}
{{- define "helpers.list-env-variables"}}
{{- range $key  := .Values.variables.data }}
- name: "{{ $key.key }}"
  value: "{{ $key.value }}"
{{- end}}
{{- end }}
