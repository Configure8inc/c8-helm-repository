{{/*
Expand the name of the chart.
*/}}
{{- define "discovery-job-manager.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "discovery-job-manager.fullname" -}}
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
{{- define "discovery-job-manager.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "discovery-job-manager.labels" -}}
helm.sh/chart: {{ include "discovery-job-manager.chart" . }}
{{ include "discovery-job-manager.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "discovery-job-manager.selectorLabels" -}}
app.kubernetes.io/name: {{ include "discovery-job-manager.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "discovery-job-manager.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "discovery-job-manager.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
Return if ingress is stable.
*/}}
{{- define "discovery-job-manager.ingress.isStable" -}}
{{- eq (include "discovery-job-manager.ingress.apiVersion" .) "networking.k8s.io/v1" }}
{{- end }}

{{/*
Return if ingress supports ingressClassName.
*/}}
{{- define "discovery-job-manager.ingress.supportsIngressClassName" -}}
{{- or (eq (include "discovery-job-manager.ingress.isStable" .) "true") (and (eq (include "discovery-job-manager.ingress.apiVersion" .) "networking.k8s.io/v1beta1") (semverCompare ">= 1.18-0" .Capabilities.KubeVersion.Version)) }}
{{- end }}

{{/*
Return if ingress supports pathType.
*/}}
{{- define "discovery-job-manager.ingress.supportsPathType" -}}
{{- or (eq (include "discovery-job-manager.ingress.isStable" .) "true") (and (eq (include "discovery-job-manager.ingress.apiVersion" .) "networking.k8s.io/v1beta1") (semverCompare ">= 1.18-0" .Capabilities.KubeVersion.Version)) }}
{{- end }}

{{/*
Return the appropriate apiVersion for ingress.
*/}}
{{- define "discovery-job-manager.ingress.apiVersion" -}}
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
Envs from configMap
*/}}
{{- define "helpers.variables_from_configmaps"}}
{{- range $key  := .Values.variables_from_configmaps.configmap_names }}
- configMapRef:
    name: {{ $key }}
{{- end}}
{{- end }}

{{/*
Envs from secrets
*/}}
{{- define "helpers.variables_from_secrets" }}
{{- range $key  := .Values.variables_from_secrets.secrets_names }}
- secretRef:
    name: {{ $key }}
{{- end }}
{{- end }}

{{/*
Envs
*/}}
{{- define "addEnvironmentVariables" -}}
{{- range $key, $value := .Values.variables }}
{{- if ne $value "" }}
- name: {{ $key }}
  value: {{ $value }}
{{- end -}}
{{- end -}}
{{- end -}}
