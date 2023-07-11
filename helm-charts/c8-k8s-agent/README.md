# c8-k8s-agent

![Version: 0.0.1](https://img.shields.io/badge/Version-0.0.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.0.0](https://img.shields.io/badge/AppVersion-1.0.0-informational?style=flat-square)

A Helm chart for c8 k8s-agent

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| CLUSTER_RESOURCE_KEY | string | `""` | key/value pairs to add as variables to the pod |
| CONFIGURE8_API_TOKEN | string | `""` | Provider resource key for the cluster you want to associate discovered resources to. If the cluster exists in the catalog, it will be associated with namespaces and pods as a parent. Otherwise, this value will be ignored once and checked on the next data sync in case the cluster appears in catalog. |
| CONFIGURE8_URL | string | `"https://qa.configure8.io/public/v1"` | Url to configure8 public API |
| FREQUENCY_HOURS | string | `"24"` | Data sync frequency. The number of hours for discovery schedule. Cannot be less than 1. |
| LOGGING_LEVEL | string | `"info"` | Agent logging level. Possible options - 'fatal', 'error', 'warn', 'info', 'debug', 'trace' or 'silent'. Be aware - trace log level will be quite verbose, since it will also print cluster changes. |
| PROVIDER_ACCOUNT_ID | string | `""` | Provider account id for the cluster and its resources. If provided, resources will be created with the specified provider account id. |
| affinity | object | `{}` | affinity |
| envs | object | `{"data":null}` | key/value pairs to add as variables to the pod |
| fullnameOverride | string | `""` |  |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| image.repository | string | `"public.ecr.aws/c8-public/c8-k8s-agent"` | c8 k8s-agent repo |
| image.tag | string | `"latest"` | Overrides the image tag whose default is the latest. |
| imagePullSecrets | list | `[]` | image pull secrets |
| nameOverride | string | `""` |  |
| nodeSelector | object | `{}` | node selector |
| podAnnotations | object | `{}` | pod annotations |
| podSecurityContext | object | `{}` | pod pod security context |
| replicaCount | int | `1` | replica count |
| resources | object | `{}` | If you do want to specify resources, uncomment the following |
| securityContext | object | `{}` |  |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | The name of the service account to use. If not set and create is true, a name is generated using the fullname template |
| tolerations | list | `[]` | tolerations |

----------------------------------------------
