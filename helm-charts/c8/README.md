# Configure8 Self-Hosted Helm Chart Deployment Guide

This guide delineates the steps to deploy the Configure8 (C8) application on a Kubernetes cluster using a Helm chart.

<p align="center">
  <img src="../../images/c8-sh.png" alt="C8 helm chart" width="300" />
</p>

## Requirements

1. A running Kubernetes version 1.22 or above is required to guarantee compatibility with the C8 App. Ensure the cluster has public internet access to fetch Docker images from repositories, specifically from GitHub.
2. A Kubernetes user with sufficient cluster access privileges is required to install the C8 app.
3. The [Helm Package Manager](https://helm.sh/).
4. The [Kubectl](https://kubernetes.io/docs/tasks/tools/)
5. The [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
6. A token provided by the C8 team is required for adding image pull secrets to the cluster.
7. A __MongoDB__ version 6.0 or above must be set up and accessible by the Kubernetes cluster.
8. A __RabbitMQ__ version 3.13 or above must be set up for managing message queues within the C8 application.
9. A __Redis__ version 7.2 or above must be set up for caching data.
10. An __OpenSearch__ cluster version 2.5 or above must be set up for robust search functionality and data analytics within the C8 app.
11. A __Snowflake__ account must be set up to provide fast search capabilities and the ability to perform complex aggregations([you can use the script to configure all privileges for a Snowflake db using a script.](scripts/Snowflake/README.md)).

## Step 1: Creating a Namespace

Isolate the C8 application by creating a Kubernetes namespace named "c8":

```bash
kubectl create namespace c8
```

## Step 2: Create Docker Registry Secret

Create a Kubernetes secret to access the C8 Docker registry. Replace <Token provided to you by the C8 team> and <your email> with your specific token and email address, respectively:

```bash
kubectl create secret docker-registry c8-docker-registry-secret \
--docker-server=ghcr.io \
--docker-username=c8-user \
--docker-password=<Token provided to you by the C8 team> \
--docker-email=<your email>` \
-n c8
```

## Step 3: Create C8 Application Secret

Generate a Kubernetes secret for the C8 application, which will contain sensitive data such as API keys and database credentials. Replace 'value' with the actual values:

```bash
kubectl create secret generic c8-secret \
    --from-literal=API_KEY='value' \
    --from-literal=CRYPTO_IV='value' \
    --from-literal=CRYPTO_SECRET='value' \
    --from-literal=JWT_SECRET='value' \
    --from-literal=DB_USERNAME='value' \
    --from-literal=DB_PASSWORD='value' \
    --from-literal=RABBITMQ_USERNAME='value' \
    --from-literal=RABBITMQ_PASSWORD='value' \
    --from-literal=REDIS_USERNAME='value' \
    --from-literal=REDIS_PASSWORD='value' \
    --from-literal=SMTP_USERNAME='value' \
    --from-literal=SMTP_PASSWORD='value' \
    --from-literal=SF_USERNAME='value' \
    --from-literal=SF_PASSWORD='value' \
    -n c8 --dry-run=client -o yaml | kubectl apply -f -
```

### Secrets Description

| Name                      | Type   | Required | Default | Description                                                                                      |
|---------------------------|--------|----------|---------|--------------------------------------------------------------------------------------------------|
| AWS_ACCESS_KEY_ID         | string | False    | `""`    | A unique identifier associated with an AWS User.                                                 |
| AWS_SECRET_ACCESS_KEY     | string | False    | `""`    | A secret string associated with the AWS_ACCESS_KEY_ID for an AWS IAM user or role.               |
| API_KEY                   | string | True     | `""`    | Unique secret key                                                                                |
| CRYPTO_IV                 | string | True     | `""`    | Crypto initialization vector                                                                     |
| CRYPTO_SECRET             | string | True     | `""`    | Crypto password                                                                                  |
| DB_PASSWORD               | string | True     | `""`    | Database password                                                                                |
| DB_USERNAME               | string | True     | `""`    | Database username                                                                                |
| GITHUB_APP_CLIENT_ID      | string | False    | `""`    | GitHub application client id. Should be created per installation in advance (optional)           |
| GITHUB_APP_CLIENT_SECRET  | string | False    | `""`    | GitHub application client secret.                                                                |
| GITHUB_APP_INSTALL_URL    | string | False    | `""`    | GitHub application installation url.                                                             |
| GOOGLE_KEY                | string | False    | `""`    | Google application key. Required for the sign in with google                                     |
| GOOGLE_SECRET             | string | False    | `""`    | Google application secret. Required for the login with google                                    |
| JWT_SECRET                | string | True     | `""`    | Unique secret used for sign user's JWT tokens                                                    |
| RABBITMQ_PASSWORD         | string | True     | `""`    | RabbitMQ password                                                                                |
| RABBITMQ_USERNAME         | string | True     | `""`    | RabbitMQ user                                                                                    |
| REDIS_PASSWORD            | string | False    | `""`    | Redis password                                                                                   |
| REDIS_USERNAME            | string | False    | `""`    | Redis user                                                                                       |
| SMTP_USERNAME             | string | True     | `""`    | Username for SMTP server.                                                                        |
| SMTP_PASSWORD             | string | True     | `""`    | Password or token for SMTP authentication.                                                       |
| SF_USERNAME               | string | True     | `""`    | Username for Snowflake db access.                                                                |
| SF_PASSWORD               | string | True     | `""`    | Password for Snowflake db access.                                                                |
| SEGMENT_KEY               | string | False    | `""`    | Segment key for application analytics.                                                           |


<div style="background-color: #FF5146; border-left: 5px solid #2196F3; padding: 0.5em; color: black;">
  <strong>Warning:</strong> You need to generate your own API_KEY, CRYPTO_IV, JWT_SECRET, and CRYPTO_SECRET which can be any cryptographically secure random string. For secure random number generation recommendations, refer to the Open Web Application Security Project (OWASP):
  <a href="https://cheatsheetseries.owasp.org/cheatsheets/Cryptographic_Storage_Cheat_Sheet.html#secure-random-number-generation" target="_blank">OWASP Cryptographic Storage Cheat Sheet</a>
</div>
<div style="background-color: #60ABFF; border-left: 5px solid #2196F3; padding: 0.5em; color: black;">
  <strong>CRYPTO_IV:</strong> The initialization vector (IV) should be 16 bytes. You can generate it using Node.js's crypto module's randomBytes function. Here's how you might do it:<br><br>
  <code style="background-color: #f0f0f0; padding: 2px; color: black;">import crypto from 'crypto';</code><br>
  <code style="background-color: #f0f0f0; padding: 2px; color: black;">const iv = crypto.randomBytes(16);</code><br><br>
  This will generate a new, random 16-byte initialization vector each time it's run. Remember, each encryption operation should use a unique IV.
</div>

## Step 4: Install the C8 Helm Chart

### Step 4.1: Configure access for the discovery job

#### AWS

- [Using service account](./AWS-IAM-SA.md)
- [Using IAM role for EC2](./AWS-IAM-EC2-ROLE.md)
- [Using access keys for IAM users (AWS\Azure\GCP\Self-Hosted)](./AWS-IAM-KEYS.md)
- [Using GCP ServiceAccount (GKE)](./AWS-GCP-SA.md)

#### GCP (It can be configured after chart installation)

- [Using service account](https://docs.configure8.io/configure8-product-docs/fundamentals/plug-ins/gcp)

#### Azure (It can be configured after chart installation)

- [Using application](https://docs.configure8.io/configure8-product-docs/fundamentals/plug-ins/azure)

### Step 4.2: Add Configure8 Chart Repository

Add the [Configure8](https://app.configure8.io) chart repository and update it:

```bash
helm repo add c8 https://helm.configure8.io/store/
helm repo update
```

> **Note**
> Please do not forget to add persistence configuration if you want to update the [application logo](https://docs.configure8.io/configure8-product-docs/fundamentals/settings/organization#theme); see the 'backend.persistence' environment variables for details.

> **Note**
> The example below the uses discovery access type [using GCP ServiceAccount (GKE) to access AWS](./AWS-GCP-SA.md)

```bash
helm upgrade -i c8 c8/c8 \
    -n c8 \
    --set variables.AWS_REGION='value' \
    --set variables.DB_HOST='value' \
    --set variables.DB_DATABASE='value' \
    --set variables.DEEPLINK_URL='value' \
    --set variables.HOOKS_CALLBACK_URL='value' \
    --set variables.OPENSEARCH_NODE='value' \
    --set variables.RABBITMQ_HOST='value' \
    --set variables.REDIS_HOST='value' \
    --set common.ingress.ingressClassName='value' \
    --set djm.serviceAccount.job_worker.annotations."iam\.gke\.io/gcp-service-account"="c8-backend@PROJECT_ID.iam.gserviceaccount.com" \
    --set backend.serviceAccount.annotations."iam\.gke\.io/gcp-service-account"="c8-djw@PROJECT_ID.iam.gserviceaccount.com"
```

> **Note**
> The example below uses the discovery access type [Using service account (EKS)](./AWS-IAM-SA.md)

```bash
helm upgrade -i c8 c8/c8 \
    -n c8 \
    --set variables.AWS_REGION='value' \
    --set variables.DB_HOST='value' \
    --set variables.DB_DATABASE='value' \
    --set variables.DEEPLINK_URL='value' \
    --set variables.HOOKS_CALLBACK_URL='value' \
    --set variables.OPENSEARCH_NODE='value' \
    --set variables.RABBITMQ_HOST='value' \
    --set variables.REDIS_HOST='value' \
    --set common.ingress.ingressClassName='value' \
    --set djm.serviceAccount.job_worker.annotations."eks\.amazonaws\.com/role-arn"='The IAM role was created above for the service account' \
    --set backend.serviceAccount.annotations."eks\.amazonaws\.com/role-arn"='The IAM role was created above for the service account'
```

> **Note**
> The example below uses the discovery access type: Azure application, GCP service account, and AWS access keys.

```bash
helm upgrade -i c8 c8/c8 \
    -n c8 \
    --set variables.AWS_REGION='value' \
    --set variables.DB_HOST='value' \
    --set variables.DB_DATABASE='value' \
    --set variables.DEEPLINK_URL='value' \
    --set variables.HOOKS_CALLBACK_URL='value' \
    --set variables.OPENSEARCH_NODE='value' \
    --set variables.RABBITMQ_HOST='value' \
    --set variables.REDIS_HOST='value' \
    --set common.ingress.ingressClassName='value'
```

> **Note**
> Depending on the chosen discovery access type, the serviceAccount parameters can be overridden

Once you successfully install a Helm chart that includes Ingress configurations, the next vital step is to establish a CNAME record in your DNS settings. This is essential to map your domain name to the Ingress controller's service endpoint.

Ensuring that the DNS propagates the new record correctly and securely linking it via TLS/SSL certificates (if applicable) will bolster both usability and security for end-users navigating to your c8 applications.

### Application Variables

The table below lists the key application variables that can be configured during deployment:

| Key                                     | Type   | Required | Default                  | Description                                                                                                                                 |
|-----------------------------------------|--------|----------|--------------------------|---------------------------------------------------------------------------------------------------------------------------------------------|
| variables.AWS_REGION | string | `"us-east-1"` | The region what actually we use with AWS integration |
| variables.DB_AUTH_MECHANISM | string | `"SCRAM-SHA-1"` | The mechanism of how to authenticate with the database. Might be SCRAM-SHA-1 or any other supported by mongodb |
| variables.DB_AUTH_SOURCE | string | `"c8"` | DB aurh source |
| variables.DB_CONNECTION_ADDITIONAL_PARAMS | string | `""` | Additional parameters for the database connection, should be provided int query params format like "key1=value&key2=value2". If no params provided should be empty string. |
| variables.DB_DATABASE | string | `"c8"` | Database name |
| variables.DB_HOST | string | `""` | Database host |
| variables.DB_PORT | string | `"27017"` | Database port |
| variables.DB_WRITE_RETRIES | string | `"true"` | Allow to retry write operations in case of failure |
| variables.DEEPLINK_URL | string | `""` | Url on which the application will be available. For example https://configure8.my-company.io |
| variables.DEFAULT_SENDER | string | `""` | Default email for sending notifications. |
| variables.DISABLE_ANALYTICS | string | `"true"` | Enable or disable analytics |
| variables.ENV | string | `"prod"` | Application env |
| variables.LOGGING_LEVEL | string | `"info"` | Logging level |
| variables.MAINTENANCE_MODE | string | `"false"` | Maintenance mode |
| variables.MONGO_DRIVER_TYPE | string | `"mongoDb"` | Type of the driver. For atlas mongoDbAtlas and mongoDb for the regular instance |
| variables.NODE_ENV | string | `"production"` | Node environment |
| variables.NODE_PORT | string | `"5000"` | Node port |
| variables.OLAP_DB | string | `"snowflake"` | Online analytical processing DB type |
| variables.OPENSEARCH_AWS_AUTHENTICATE | string | `"true"` | Enable or disable AWS authentication |
| variables.OPENSEARCH_AWS_SERVICE | string | `"es"` | Specify the AWS OpenSearch service type, either 'es' for OpenSearch or 'aoss' for serverless OpenSearch Service |
| variables.OPENSEARCH_NODE | string | `""` | ElasticSearch url |
| variables.RABBITMQ_HOST | string | `""` | RabbitMQ host |
| variables.RABBITMQ_PORT | int | `5672` | RabbitMQ port |
| variables.RABBITMQ_USE_SSL | string | `"false"` | RabbitMQ ssl flag |
| variables.REDIS_CACHE_TTL | string | `"900"` | Redis cache ttl |
| variables.REDIS_CONNECT_TIMEOUT | string | `"5000"` | Redis connect timeout |
| variables.REDIS_ENABLED | string | `"true"` | Enable or disable redis cache |
| variables.REDIS_HOST | string | `""` | Redis host |
| variables.REDIS_PORT | string | `"6379"` | Redis port |
| variables.SF_ACCOUNT | string | `""` | Snowflake account name |
| variables.SF_DATABASE | string | `"C8"` | Snowflake db name |
| variables.SF_POOLSIZE | string | `"5"` | Snowflake poolsize |
| variables.SF_READ_WAREHOUSE | string | `""` | Snowflake RO warehouse name |
| variables.SF_SCHEMA | string | `"PUBLIC"` | Snowflake db schema |
| variables.SF_WRITE_WAREHOUSE | string | `""` | Snowflake RW warehouse name |
| variables.SMTP_HOST | string | `"smtp.sendgrid.net"` | Address of the SMTP server (e.g., SendGrid's server). |
| variables.SMTP_PORT | string | `"587"` | Port for connecting to the SMTP server |
| variables.SSA_SWAGGER_ENABLED | string | `"false"` | Enable or disable swagger documentation |
| variables.STAGE | string | `"prod"` | Application stage |
| variables.SWAGGER_ENABLED | string | `"false"` | Enable or disable swagger documentation |
| variables.TZ | string | `"America/New_York"` | Application timezone |
| variables.USE_SMTP_STRATEGY | string | `"true"` | Flag to use SMTP for emails |
| variables.VERSION | string | `"v1.0.0"` | Application version |

### The C8 Helm Chart Parameters

The table below shows configurable parameters when deploying the C8 Helm chart:

#### Backend environment variables

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| backend.affinity | object | `{}` | Affinity for pod assignment <https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity> |
| backend.autoscaling.enabled | bool | `false` |  |
| backend.autoscaling.maxReplicas | int | `10` |  |
| backend.autoscaling.minReplicas | int | `1` |  |
| backend.autoscaling.targetCPUUtilizationPercentage | int | `80` |  |
| backend.autoscaling.targetMemoryUtilizationPercentage | int | `80` |  |
| backend.enabled | bool | `true` |  |
| backend.image.pullPolicy | string | `"IfNotPresent"` |  |
| backend.image.repository | string | `"ghcr.io/configure8inc/c8-backend"` |  |
| backend.labels | object | `{"appComponent":"backend"}` | Backend labels |
| backend.livenessProbe.failureThreshold | int | `3` |  |
| backend.livenessProbe.httpGet.path | string | `"/api/v1/ping"` |  |
| backend.livenessProbe.httpGet.port | int | `5000` |  |
| backend.livenessProbe.periodSeconds | int | `10` |  |
| backend.livenessProbe.timeoutSeconds | int | `10` |  |
| backend.nodeSelector | object | `{}` | Node labels for pod assignment <https://kubernetes.io/docs/user-guide/node-selection/> |
| backend.persistence.accessModes | list | `["ReadWriteOne"]` | Access mode |
| backend.persistence.annotations | object | `{}` | PVC annotations |
| backend.persistence.enabled | bool | `false` | Enable persistence using Persistent Volume Claims |
| backend.persistence.existingClaim | string | `""` | Use an existing PVC? If yes, set this to the name of the PVC |
| backend.persistence.extraPvcLabels | object | `{}` | PVC extra PVC labels |
| backend.persistence.finalizers | list | `["kubernetes.io/pvc-protection"]` | PVC finalizers |
| backend.persistence.mountPath | string | `"/home/c8/app/packages/backend"` | Mount path |
| backend.persistence.selectorLabels | object | `{}` | PVC selector labels |
| backend.persistence.size | string | `"10Gi"` | Storage size |
| backend.persistence.storageClassName | string | `"efs-sc"` | Storage class name |
| backend.persistence.type | string | `"pvc"` | Persistence type |
| backend.podAnnotations | object | `{}` |  |
| backend.podDisruptionBudget.enabled | bool | `false` | Specifies whether pod disruption budget should be created |
| backend.podDisruptionBudget.minAvailable | string | `"50%"` | Number or percentage of pods that must be available |
| backend.podSecurityContext.fsGroup | int | `1051` |  |
| backend.podSecurityContext.runAsGroup | int | `1051` |  |
| backend.podSecurityContext.runAsNonRoot | bool | `true` |  |
| backend.podSecurityContext.runAsUser | int | `1051` |  |
| backend.readinessProbe.failureThreshold | int | `3` |  |
| backend.readinessProbe.httpGet.path | string | `"/api/v1/ping"` |  |
| backend.readinessProbe.httpGet.port | int | `5000` |  |
| backend.readinessProbe.periodSeconds | int | `10` |  |
| backend.readinessProbe.timeoutSeconds | int | `10` |  |
| backend.replicaCount | int | `1` |  |
| backend.resources | object | `{"limits":{"cpu":2,"memory":"2Gi"},"requests":{"cpu":1,"memory":"2Gi"}}` | Define resources requests and limits for Pods. <https://kubernetes.io/docs/user-guide/compute-resources/> |
| backend.securityContext.allowPrivilegeEscalation | bool | `false` |  |
| backend.securityContext.capabilities.drop[0] | string | `"ALL"` |  |
| backend.securityContext.readOnlyRootFilesystem | bool | `true` |  |
| backend.service | object | `{"port":"5000","type":"ClusterIP"}` | Configuration for backend service |
| backend.serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| backend.serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| backend.serviceAccount.name | string | `"c8-backend"` | The name of the service account to use. If not set and create is true, a name is generated using the fullname template |
| backend.startupProbe.failureThreshold | int | `5` |  |
| backend.startupProbe.httpGet.path | string | `"/api/v1/ping"` |  |
| backend.startupProbe.httpGet.port | int | `5000` |  |
| backend.startupProbe.initialDelaySeconds | int | `20` |  |
| backend.startupProbe.periodSeconds | int | `10` |  |
| backend.startupProbe.timeoutSeconds | int | `10` |  |
| backend.tolerations | list | `[]` | Tolerations for pod assignment <https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/> |

#### Common envs

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| fullnameOverride | string | `""` | Provide a name to substitute for the full names of resources |
| nameOverride | string | `""` | Provide a name in place of c8 for `app:` labels |
| commonLabels | object | `{}` | Labels to apply to all resources |
| common.C8_SECRET_NAME | string | `"c8-secret"` |  |
| common.IMAGE_PULL_SECRET | string | `"c8-docker-registry-secret"` | image pull secrets |
| common.app_version | string | `"1.0.0"` | Application version (used for deployment and image tags) |
| common.ingress.annotations | object | `{}` |  |
| common.ingress.enabled | bool | `true` | Enable ingress object for external access to the resources . Do not forget to add common.ingress.ingressClassName="" |
| common.ingress.ingressClassName | string | `""` |  |
| common.ingress.labels | object | `{}` |  |
| common.ingress.pathType | string | `"Prefix"` |  |
| common.revisionHistoryLimit | int | `3` |  |
| common.ttlSecondsAfterFinished | int | `172800` |  |

#### Discovery job manager\worker environment variables

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| djm.DJW_IMAGE_REPO | string | `"ghcr.io/configure8inc/c8-djw"` | Discovery job worker image |
| djm.DJW_NODE_SELECTOR_KEY | string | `""` | Discovery job worker NodeSelector key |
| djm.DJW_NODE_SELECTOR_VALUE | string | `""` | Discovery job worker NodeSelector value |
| djm.DJW_POD_SECURITY_CONTEXT | string | `"{\"runAsUser\": 1052, \"runAsGroup\": 1052, \"runAsNonRoot\": true}"` | Discovery job worker pod security context |
| djm.affinity | object | `{}` | Affinity for pod assignment <https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity> |
| djm.container.port | string | `"5000"` |  |
| djm.enabled | bool | `true` |  |
| djm.image.pullPolicy | string | `"IfNotPresent"` |  |
| djm.image.repository | string | `"ghcr.io/configure8inc/c8-djm"` | c8 docker image repository |
| djm.labels | object | `{"appComponent":"djm"}` | Backend labels |
| djm.nodeSelector | object | `{}` | Node labels for pod assignment <https://kubernetes.io/docs/user-guide/node-selection/> |
| djm.podAnnotations | object | `{}` |  |
| djm.podSecurityContext.fsGroup | int | `1052` |  |
| djm.podSecurityContext.runAsGroup | int | `1052` |  |
| djm.podSecurityContext.runAsNonRoot | bool | `true` |  |
| djm.podSecurityContext.runAsUser | int | `1052` |  |
| djm.replicaCount | int | `1` |  |
| djm.resources | object | `{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"512Mi"}}` | Define resources requests and limits for Pods. <https://kubernetes.io/docs/user-guide/compute-resources/> |
| djm.securityContext.allowPrivilegeEscalation | bool | `false` |  |
| djm.securityContext.capabilities.drop[0] | string | `"ALL"` |  |
| djm.securityContext.readOnlyRootFilesystem | bool | `true` |  |
| djm.serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| djm.serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| djm.serviceAccount.job_worker.annotations | object | `{}` | Annotations to add to the service account |
| djm.serviceAccount.job_worker.create | bool | `true` | Specifies whether a service account should be created |
| djm.serviceAccount.job_worker.name | string | `"c8-djw"` | The name of the djw service account to use. If not set and create is true, a name is generated using the fullname template |
| djm.serviceAccount.name | string | `"c8-djm"` | The name of the service account to use. If not set and create is true, a name is generated using the fullname template |
| djm.tolerations | list | `[]` | Tolerations for pod assignment <https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/> |

#### Frontend environment variables

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| frontend.affinity | object | `{}` | Affinity for pod assignment <https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity> |
| frontend.autoscaling.enabled | bool | `false` |  |
| frontend.autoscaling.maxReplicas | int | `10` |  |
| frontend.autoscaling.minReplicas | int | `1` |  |
| frontend.autoscaling.targetCPUUtilizationPercentage | int | `80` |  |
| frontend.autoscaling.targetMemoryUtilizationPercentage | int | `80` |  |
| frontend.enabled | bool | `true` |  |
| frontend.image.pullPolicy | string | `"IfNotPresent"` |  |
| frontend.image.repository | string | `"ghcr.io/configure8inc/c8-frontend"` |  |
| frontend.labels | object | `{"appComponent":"frontend"}` | Frontend labels |
| frontend.livenessProbe.failureThreshold | int | `2` |  |
| frontend.livenessProbe.httpGet.path | string | `"/"` |  |
| frontend.livenessProbe.httpGet.port | int | `8080` |  |
| frontend.livenessProbe.periodSeconds | int | `10` |  |
| frontend.nodeSelector | object | `{}` | Node labels for pod assignment <https://kubernetes.io/docs/user-guide/node-selection/> |
| frontend.podAnnotations | object | `{}` |  |
| frontend.podDisruptionBudget.enabled | bool | `false` |  |
| frontend.podDisruptionBudget.minAvailable | string | `"50%"` |  |
| frontend.podSecurityContext.fsGroup | int | `101` |  |
| frontend.podSecurityContext.runAsGroup | int | `101` |  |
| frontend.podSecurityContext.runAsNonRoot | bool | `true` |  |
| frontend.podSecurityContext.runAsUser | int | `101` |  |
| frontend.readinessProbe.failureThreshold | int | `2` |  |
| frontend.readinessProbe.httpGet.path | string | `"/"` |  |
| frontend.readinessProbe.httpGet.port | int | `8080` |  |
| frontend.readinessProbe.initialDelaySeconds | int | `20` |  |
| frontend.readinessProbe.periodSeconds | int | `10` |  |
| frontend.replicaCount | int | `1` |  |
| frontend.resources | object | `{"limits":{"cpu":1,"memory":"256Mi"},"requests":{"cpu":0.2,"memory":"256Mi"}}` | Define resources requests and limits for Pods. <https://kubernetes.io/docs/user-guide/compute-resources/> |
| frontend.securityContext.allowPrivilegeEscalation | bool | `false` |  |
| frontend.securityContext.capabilities.drop[0] | string | `"ALL"` |  |
| frontend.service | object | `{"port":"8080","type":"ClusterIP"}` | Configuration for frontend service |
| frontend.serviceAccount.annotations | object | `{}` |  |
| frontend.serviceAccount.create | bool | `true` |  |
| frontend.serviceAccount.name | string | `"c8-frontend"` |  |
| frontend.tolerations | list | `[]` | Tolerations for pod assignment <https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/> |

#### Migration environment variables

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| migration.affinity | object | `{}` | Affinity for pod assignment <https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity> |
| migration.image.pullPolicy | string | `"IfNotPresent"` |  |
| migration.image.repository | string | `"ghcr.io/configure8inc/c8-migrations"` |  |
| migration.labels | object | `{"appComponent":"migration"}` | Migration labels |
| migration.nodeSelector | object | `{}` | Node labels for pod assignment <https://kubernetes.io/docs/user-guide/node-selection/> |
| migration.podSecurityContext.fsGroup | int | `1051` |  |
| migration.podSecurityContext.runAsGroup | int | `1051` |  |
| migration.podSecurityContext.runAsNonRoot | bool | `true` |  |
| migration.podSecurityContext.runAsUser | int | `1051` |  |
| migration.securityContext.allowPrivilegeEscalation | bool | `false` |  |
| migration.securityContext.capabilities.drop[0] | string | `"ALL"` |  |
| migration.tolerations | list | `[]` | Tolerations for pod assignment <https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/> |

#### Platform notification service environment variables

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| pns.affinity | object | `{}` | Affinity for pod assignment <https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity> |
| pns.autoscaling.enabled | bool | `false` |  |
| pns.autoscaling.maxReplicas | int | `10` |  |
| pns.autoscaling.minReplicas | int | `1` |  |
| pns.autoscaling.targetCPUUtilizationPercentage | int | `80` |  |
| pns.autoscaling.targetMemoryUtilizationPercentage | int | `80` |  |
| pns.container.port | string | `"5000"` |  |
| pns.enabled | bool | `true` |  |
| pns.image.pullPolicy | string | `"IfNotPresent"` |  |
| pns.image.repository | string | `"ghcr.io/configure8inc/c8-pns"` |  |
| pns.labels | object | `{"appComponent":"pns"}` | Backend labels |
| pns.nodeSelector | object | `{}` | Node labels for pod assignment <https://kubernetes.io/docs/user-guide/node-selection/> |
| pns.podAnnotations | object | `{}` |  |
| pns.podDisruptionBudget.enabled | bool | `false` |  |
| pns.podDisruptionBudget.minAvailable | string | `"50%"` |  |
| pns.podSecurityContext.fsGroup | int | `1057` |  |
| pns.podSecurityContext.runAsGroup | int | `1057` |  |
| pns.podSecurityContext.runAsNonRoot | bool | `true` |  |
| pns.podSecurityContext.runAsUser | int | `1057` |  |
| pns.replicaCount | int | `1` |  |
| pns.resources | object | `{"limits":{"cpu":"500m","memory":"256Mi"},"requests":{"cpu":"100m","memory":"256Mi"}}` | Define resources requests and limits for Pods. <https://kubernetes.io/docs/user-guide/compute-resources/> |
| pns.securityContext.allowPrivilegeEscalation | bool | `false` |  |
| pns.securityContext.capabilities.drop[0] | string | `"ALL"` |  |
| pns.securityContext.readOnlyRootFilesystem | bool | `true` |  |
| pns.service | object | `{"enabled":true,"port":"5000","type":"ClusterIP"}` | Configuration for pns service |
| pns.serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| pns.serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| pns.serviceAccount.name | string | `"c8-pns"` | The name of the service account to use. If not set and create is true, a name is generated using the fullname template |
| pns.tolerations | list | `[]` | Tolerations for pod assignment <https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/> |

#### Self-service actions environment variables

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| ssa.affinity | object | `{}` | Affinity for pod assignment <https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity> |
| ssa.container.port | string | `"5000"` |  |
| ssa.enabled | bool | `true` |  |
| ssa.image.pullPolicy | string | `"IfNotPresent"` |  |
| ssa.image.repository | string | `"ghcr.io/configure8inc/c8-ssa"` |  |
| ssa.ingress.annotations | object | `{}` |  |
| ssa.ingress.enabled | bool | `true` |  |
| ssa.ingress.ingressClassName | string | `""` |  |
| ssa.ingress.labels | object | `{}` |  |
| ssa.ingress.pathType | string | `"Prefix"` |  |
| ssa.labels | object | `{"appComponent":"ssa"}` | Backend labels |
| ssa.livenessProbe.failureThreshold | int | `3` |  |
| ssa.livenessProbe.httpGet.path | string | `"/self-service/api/health"` |  |
| ssa.livenessProbe.httpGet.port | int | `5000` |  |
| ssa.livenessProbe.httpGet.scheme | string | `"HTTP"` |  |
| ssa.livenessProbe.periodSeconds | int | `10` |  |
| ssa.livenessProbe.timeoutSeconds | int | `10` |  |
| ssa.nodeSelector | object | `{}` | Node labels for pod assignment <https://kubernetes.io/docs/user-guide/node-selection/> |
| ssa.podAnnotations | object | `{}` |  |
| ssa.podDisruptionBudget.enabled | bool | `false` | Specifies whether pod disruption budget should be created |
| ssa.podDisruptionBudget.minAvailable | string | `"50%"` | Number or percentage of pods that must be available |
| ssa.podSecurityContext.fsGroup | int | `1055` |  |
| ssa.podSecurityContext.runAsGroup | int | `1055` |  |
| ssa.podSecurityContext.runAsNonRoot | bool | `true` |  |
| ssa.podSecurityContext.runAsUser | int | `1055` |  |
| ssa.readinessProbe.failureThreshold | int | `3` |  |
| ssa.readinessProbe.httpGet.path | string | `"/self-service/api/health"` |  |
| ssa.readinessProbe.httpGet.port | int | `5000` |  |
| ssa.readinessProbe.httpGet.scheme | string | `"HTTP"` |  |
| ssa.readinessProbe.periodSeconds | int | `10` |  |
| ssa.readinessProbe.timeoutSeconds | int | `10` |  |
| ssa.replicaCount | int | `1` |  |
| ssa.resources | object | `{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"512Mi"}}` | Define resources requests and limits for Pods. <https://kubernetes.io/docs/user-guide/compute-resources/> |
| ssa.securityContext.allowPrivilegeEscalation | bool | `false` |  |
| ssa.securityContext.capabilities.drop[0] | string | `"ALL"` |  |
| ssa.securityContext.readOnlyRootFilesystem | bool | `true` |  |
| ssa.service | object | `{"enabled":true,"port":"5000","type":"ClusterIP"}` | Configuration for ssa service |
| ssa.serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| ssa.serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| ssa.serviceAccount.name | string | `"c8-ssa"` | The name of the service account to use. If not set and create is true, a name is generated using the fullname template |
| ssa.tolerations | list | `[]` | Tolerations for pod assignment <https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/> |
