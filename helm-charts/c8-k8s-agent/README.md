# c8-k8s-agent

![Version: 0.0.1](https://img.shields.io/badge/Version-0.0.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.0.0](https://img.shields.io/badge/AppVersion-1.0.0-informational?style=flat-square)

A Helm chart for c8 k8s-agent

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | affinity |
| envs | object | `{"data":null}` | key/value pairs to add as variables to the pod |
| fullnameOverride | string | `""` |  |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| image.repository | string | `"public.ecr.aws/c8-public/c8-k8s-agent"` | c8 k8s-agent repo |
| image.tag | string | `"latest"` | Overrides the image tag whose default is the latest. |
| imagePullSecrets | list | `[]` | image pull secrets |
| livenessProbe | object | `{}` | liveness probe |
| nameOverride | string | `""` |  |
| nodeSelector | object | `{}` | node selector |
| podAnnotations | object | `{}` | pod annotations |
| podSecurityContext | object | `{}` | pod pod security context |
| readinessProbe | object | `{}` | readiness probe |
| replicaCount | int | `1` | replica count |
| resources | object | `{}` | If you do want to specify resources, uncomment the following |
| securityContext | object | `{}` |  |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | The name of the service account to use. If not set and create is true, a name is generated using the fullname template |
| tolerations | list | `[]` | tolerations |

----------------------------------------------
