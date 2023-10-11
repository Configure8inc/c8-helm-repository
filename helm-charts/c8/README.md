# Configure8 Self-Hosted Helm Chart Deployment Guide

This guide delineates the steps to deploy the Configure8 (C8) application on a Kubernetes cluster using a Helm chart.

<p align="center">
  <img src="../../images/c8-app.png" alt="C8 helm chart" width="300" />
</p>

## Requirements

1. A running Kubernetes version 1.22 or above to guarantee compatibility with the C8 App. Ensure the cluster has public internet access to fetch Docker images from repositories, specifically from GitHub.
2. A Kubernetes user with sufficient cluster access privileges to install the C8 app.
3. The [Helm Package Manager](https://helm.sh/).
4. The [Kubectl](https://kubernetes.io/docs/tasks/tools/)
5. The [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
6. A token provided by the C8 team for adding image pull secrets to the cluster.
7. A __MongoDB__ database must be set up, and accessible by the Kubernetes cluster.
8. A __RabbitMQ__ cluster must be set up for managing message queues within the C8 application.
9. An __OpenSearch__ cluster must be set up for robust search functionality and data analytics within the C8 app.

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
    --from-literal=SENDGRID_API_KEY='value' \
    -n c8 --dry-run=client -o yaml | kubectl apply -f -
```

### Secrets Description

| Name | Type | Default | Description |
|-----|------|---------|-------------|
| API_KEY | string | `""` | Unique secret key |
| CRYPTO_IV | string | `""` | Crypto initialization vector |
| CRYPTO_SECRET | string | `""` | Crypto password |
| DB_PASSWORD | string | `""` | Database password |
| DB_USERNAME | string | `""` | Database username |
| GITHUB_APP_CLIENT_ID | string | `""` | GitHub application client id. Should be created per installation in advance (optional) |
| GITHUB_APP_CLIENT_SECRET | string | `""` | GitHub application client secret. (optional) |
| GITHUB_APP_INSTALL_URL | string | `""` | GitHub application installation url. (optional) |
| GOOGLE_KEY | string | `""` | Google application key. Required for the sign in with google (optional) |
| GOOGLE_SECRET | string | `""` | Google application secret. Required for the login with google (optional) |
| JWT_SECRET | string | `""` | Unique secret used for sign user's JWT tokens |
| RABBITMQ_PASSWORD | string | `""` | RabbitMQ password |
| RABBITMQ_USERNAME | string | `""` | RabbitMQ user |
| SENDGRID_API_KEY | string | `""` | Sendgrid api key password |
----------------------------------------------

## Step 4: Create IAM Role for C8 and DJM Service Accounts

### Step 4.1: Create IAM Policy

Replace the placeholders with your specific values:

> *placeholders description*:

| Name | Description |
|-----|-------------|
| $AWS_EKS_CLUSTER_NAME | The name of the AWS EKS cluster to which we will deploy the application |
| $AWS_EKS_CLUSTER_REGION  | The AWS Region of the AWS EKS cluster to which we will deploy the application |
| $APP_NAMESPACE  | The Kubernetes namespace of the AWS EKS cluster to which we will deploy the application |

```bash
account_id=$(aws sts get-caller-identity --query "Account" --output text)
oidc_provider=$(aws eks describe-cluster --name $AWS_EKS_CLUSTER_NAME --region $AWS_EKS_CLUSTER_REGION --query "cluster.identity.oidc.issuer" --output text | sed -e "s/^https:\/\///")
namespace=$APP_NAMESPACE
service_account_c8_app=c8-backend
service_account_c8_djw=c8-djw
```

### Step 4.2: Create Trust Relationship for IAM Role

Create a trust relationship for the IAM role:

```bash
# Generate a JSON file for the trust relationship
cat >trust-relationship-sa.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${account_id}:oidc-provider/${oidc_provider}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${oidc_provider}:aud": "sts.amazonaws.com",
          "${oidc_provider}:sub": [
            "system:serviceaccount:${namespace}:${service_account_c8_app}",
            "system:serviceaccount:${namespace}:${service_account_c8_djw}"
          ]
        }
      }
    }
  ]
}
EOF
```

### Step 4.3: Create IAM Role

```bash
# Create an IAM role with a defined trust relationship and description
aws iam create-role --role-name sh-c8-service-account --assume-role-policy-document file://trust-relationship-sa.json --description "The role for the Configure8 pods service account"
```

## Step 5: Create IAM Role to Assume by C8 and DJM Service Accounts

### Step 5.1: Download IAM Policy

Download the IAM policy that grants read permissions to all AWS resources:

```bash
curl -o sh-c8-discovery-policy.json https://configure8-resources.s3.us-east-2.amazonaws.com/iam/sh-c8-discovery-policy.json
```

### Step 5.2: Create IAM Policy

Create the IAM policy:

```bash
aws iam create-policy --policy-name sh-c8-discovery-policy --policy-document file://sh-c8-discovery-policy.json
```

### Step 5.3: Create IAM Role

Create an IAM role that can be assumed by the C8 and DJM service accounts:

```bash
# Generate a JSON file for the trust relationship
cat >trust-relationship.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${account_id}:role/sh-c8-service-account"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
```

### Create an IAM role with a defined trust relationship and description

```bash
aws iam create-role --role-name sh-c8-discovery --assume-role-policy-document file://trust-relationship.json --description "sh-c8-discovery"
```

### Attach the sh-c8-discovery to the policy

```bash
aws iam attach-role-policy --role-name sh-c8-discovery --policy-arn=arn:aws:iam::$account_id:policy/sh-c8-discovery-policy
```

> **Note**
> If you want to discover more aws accounts, you have to repeat all steps for each account.

## Step 6: Install the C8 Helm Chart

### Step 6.1: Add Configure8 Chart Repository

Add the [Configure8](https://app.configure8.io) chart repository and update it:

```bash
helm repo add c8 https://helm.configure8.io/store/
helm repo update
```

### Step 6.2: Install the Helm Chart

Install the Helm chart with the desired configurations. Replace the placeholders with your specific values:

```bash
helm upgrade -i sh-c8 ./helm-charts/c8 \
    -n c8 \
    --set variables.AWS_REGION='value' \
    --set variables.DB_HOST='value' \
    --set variables.DB_DATABASE='value' \
    --set variables.DEEPLINK_URL='value' \
    --set variables.HOOKS_CALLBACK_URL='value' \
    --set variables.OPENSEARCH_NODE='value' \
    --set variables.RABBITMQ_HOST='value' \
    --set common.ingress.ingressClassName='value' \
    --set djm.serviceAccount.job_worker.annotations."eks\.amazonaws\.com/role-arn"='The IAM role was created above for the service account' \
    --set backend.serviceAccount.annotations."eks\.amazonaws\.com/role-arn"='The IAM role was created above for the service account'

```

Once you successfully install a Helm chart that includes Ingress configurations, the next vital step is to establish a CNAME record in your DNS settings. This is essential to map your domain name to the Ingress controller's service endpoint.

Ensuring that the DNS propagates the new record correctly and securely linking it via TLS/SSL certificates (if applicable) will bolster both usability and security for end-users navigating to your c8 applications.

### Application Variables

The table below lists the key application variables that can be configured during deployment:

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| variables.API_PREFIX | string | `"/api/v1"` | Used to define the relative path to the backend API |
| variables.AWS_REGION | string | `"na"` | Deprecated and not needed anymore, so will be deleted soon |
| variables.DB_AUTH_MECHANISM | string | `"SCRAM-SHA-1"` | The mechanism of how to authenticate with the database. Might be 'mqlDriver' for atlas mongodb or SCRAM-SHA-1 for regular one |
| variables.DB_DATABASE | string | `"c8"` | Database name |
| variables.DB_HOST | string | `""` | Database host |
| variables.DB_PORT | string | `"27017"` | Database port |
| variables.DEEPLINK_URL | string | `""` | Url on which the application will be available. For example https://configure8.my-company.io |
| variables.DEFAULT_SENDER | string | `"notifications@configure8.io"` |  |
| variables.DISCOVERY_CONTAINER_NAME | string | `"c8-discovery-job-worker"` | Workers container names |
| variables.DJM_API_PREFIX | string | `"/api/v1"` | Required for the health checks |
| variables.DJW_TRACK_ENTITY_LINEAGE | string | `"true"` | Storing diff information for the resources |
| variables.HOOKS_CALLBACK_URL | string | `""` | Url on which the application will be available. Usually should be the same as DEEPLINK_URLFor example https://configure8.my-company.io |
| variables.JOB_DEAD_TIMEOUT_HOURS | string | `"3"` | Maximum hours for the job execution |
| variables.JOB_TYPES | string | `"DISCOVERY, DISCOVERY_ON_DEMAND, AUTOMAPPING_BY_TAGS, COSTS_RECALCULATE, SCORECARD_AGGREGATION, SCORECARD_AGGREGATION_ON_DEMAND, SSA_TERMINATION, CALCULATE_SERVICE_DETAILS, SCORECARD_NOTIFICATION, SERVICE_NOTIFICATION, CREDENTIALS_NOTIFICATION"` | list of the jobs that are going to be executed by discovery manager |
| variables.LOOP_SLEEP_TIME | string | `"10000"` | Determines the time when the schedule should be checked |
| variables.MAX_JOB_LIMIT | string | `"10"` | Maximum simultaneously executed jobs |
| variables.MONGO_DRIVER_TYPE | string | `"mongoDb"` | Type of the driver. For atlas mongoDbAtlas and mongoDb for the regular instance |
| variables.OPENSEARCH_NODE | string | `""` | ElasticSearch url |
| variables.RABBITMQ_HOST | string | `""` | RabbitMQ host |
| variables.RABBITMQ_PORT | int | `5672` | RabbitMQ port |
| variables.SEGMENT_KEY | string | `"na"` | Application analytics segment key |
| variables.SSA_API_PREFIX | string | `"/self-service/api"` | Used to define the relative path to the backend API, by default should be /self-service/api |
| variables.SSA_SWAGGER_DESCRIPTION | string | `"Self Service API documentation"` | Description for the swagger file, usually shouldn't be changed |
| variables.SSA_SWAGGER_ENABLED | string | `"false"` | Enable or disable swagger documentation |
| variables.SSA_SWAGGER_PREFIX | string | `"/self-service/api/docs"` | Swagger documentation relative url, by default /self-service/api/docs |
| variables.SSA_SWAGGER_TITLE | string | `"C8 Self-Service API"` | Swagger documentation title |
| variables.SWAGGER_DESCRIPTION | string | `"C8 API"` | Description for the swagger file, usually shouldn't be changed |
| variables.SWAGGER_ENABLED | string | `"false"` | Enable or disable swagger documentation |
| variables.SWAGGER_PREFIX | string | `"/docs"` | Swagger documentation relative url |
| variables.SWAGGER_TITLE | string | `"C8 Backend API"` | Swagger documentation title |
| variables.TZ | string | `"America/New_York"` | Application timezone |
| variables.USE_K8 | string | `"true"` | For the production should be true |

### The C8 Helm Chart Parameters

The table below shows configurable parameters when deploying the C8 Helm chart:

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| backend.affinity | object | `{}` | Affinity for pod assignment https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity |
| backend.autoscaling.enabled | bool | `false` |  |
| backend.autoscaling.maxReplicas | int | `10` |  |
| backend.autoscaling.minReplicas | int | `1` |  |
| backend.autoscaling.targetCPUUtilizationPercentage | int | `80` |  |
| backend.autoscaling.targetMemoryUtilizationPercentage | int | `80` |  |
| backend.enabled | bool | `true` |  |
| backend.image.pullPolicy | string | `"IfNotPresent"` |  |
| backend.image.repository | string | `"ghcr.io/configure8inc/c8-backend"` |  |
| backend.image.tag | string | `"0.0.3"` |  |
| backend.nodeSelector | object | `{}` | Node labels for pod assignment https://kubernetes.io/docs/user-guide/node-selection/ |
| backend.podAnnotations | object | `{}` |  |
| backend.podDisruptionBudget.enabled | bool | `false` | Specifies whether pod disruption budget should be created |
| backend.podDisruptionBudget.minAvailable | string | `"50%"` | Number or percentage of pods that must be available |
| backend.podSecurityContext | object | `{}` |  |
| backend.replicaCount | int | `1` |  |
| backend.resources | object | `{}` |  |
| backend.securityContext | object | `{}` |  |
| backend.service | object | `{"port":"5000","type":"ClusterIP"}` | Configuration for backend service |
| backend.serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| backend.serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| backend.serviceAccount.name | string | `""` | The name of the service account to use. If not set and backend.serviceAccount.create is true, a name is generated using the fullname template |
| backend.tolerations | list | `[]` | Tolerations for pod assignment https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/ |
| common.C8_SECRET_NAME | string | `"c8-secret"` |  |
| common.IMAGE_PULL_SECRET | string | `"c8-docker-registry-secret"` | Image pull secrets |
| common.ingress.annotations | object | `{}` |  |
| common.ingress.enabled | bool | `true` | Enable ingress object for external access to the resources. Do not forget to add common.ingress.ingressClassName="" |
| common.ingress.ingressClassName | string | `""` |  |
| common.ingress.labels | object | `{}` |  |
| common.ingress.pathType | string | `"Prefix"` |  |
| commonLabels | object | `{}` | Labels to apply to all resources |
| djm.DJW_IMAGE | string | `"ghcr.io/configure8inc/c8-djw:0.0.3"` |  |
| djm.affinity | object | `{}` | Affinity for pod assignment https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity |
| djm.container.port | string | `"5000"` |  |
| djm.enabled | bool | `true` |  |
| djm.image.pullPolicy | string | `"IfNotPresent"` |  |
| djm.image.repository | string | `"ghcr.io/configure8inc/c8-djm"` | c8 docker image repository |
| djm.image.tag | string | `"0.0.3"` |  |
| djm.nodeSelector | object | `{}` | Node labels for pod assignment https://kubernetes.io/docs/user-guide/node-selection/ |
| djm.podAnnotations | object | `{}` |  |
| djm.podSecurityContext | object | `{}` |  |
| djm.replicaCount | int | `1` |  |
| djm.resources | object | `{}` |  |
| djm.securityContext | object | `{}` |  |
| djm.serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| djm.serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| djm.serviceAccount.job_worker.annotations | object | `{}` | Annotations to add to the service account |
| djm.serviceAccount.job_worker.name | string | `nil` | The name of the djw service account to use. If not set and djm.serviceAccount.create is true, a name is generated using the fullname template |
| djm.serviceAccount.name | string | `""` | The name of the service account to use. If not set and djm.serviceAccount.create is true, a name is generated using the fullname template |
| djm.tolerations | list | `[]` | Tolerations for pod assignment https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/ |
| frontend.affinity | object | `{}` | Affinity for pod assignment https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity |
| frontend.autoscaling.enabled | bool | `false` |  |
| frontend.autoscaling.maxReplicas | int | `10` |  |
| frontend.autoscaling.minReplicas | int | `1` |  |
| frontend.autoscaling.targetCPUUtilizationPercentage | int | `80` |  |
| frontend.autoscaling.targetMemoryUtilizationPercentage | int | `80` |  |
| frontend.enabled | bool | `true` |  |
| frontend.image.pullPolicy | string | `"IfNotPresent"` |  |
| frontend.image.repository | string | `"ghcr.io/configure8inc/c8-frontend"` |  |
| frontend.image.tag | string | `"0.0.3"` |  |
| frontend.limits.cpu | string | `"300m"` |  |
| frontend.limits.memory | string | `"128Mi"` |  |
| frontend.nodeSelector | object | `{}` | Node labels for pod assignment https://kubernetes.io/docs/user-guide/node-selection/ |
| frontend.podAnnotations | object | `{}` |  |
| frontend.podDisruptionBudget.enabled | bool | `false` |  |
| frontend.podDisruptionBudget.minAvailable | string | `"50%"` |  |
| frontend.podSecurityContext | object | `{}` |  |
| frontend.replicaCount | int | `1` |  |
| frontend.requests.cpu | string | `"100m"` |  |
| frontend.requests.memory | string | `"128Mi"` |  |
| frontend.resources | object | `{}` |  |
| frontend.securityContext | object | `{}` |  |
| frontend.service | object | `{"port":"80","type":"ClusterIP"}` | Configuration for frontend service |
| frontend.serviceAccount.annotations | object | `{}` |  |
| frontend.serviceAccount.create | bool | `false` |  |
| frontend.serviceAccount.name | string | `""` |  |
| frontend.tolerations | list | `[]` | Tolerations for pod assignment https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/ |
| fullnameOverride | string | `""` | Provide a name to substitute for the full names of resources |
| migration.affinity | object | `{}` | Affinity for pod assignment https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity |
| migration.image.pullPolicy | string | `"IfNotPresent"` |  |
| migration.image.repository | string | `"ghcr.io/configure8inc/c8-migrations"` |  |
| migration.image.tag | string | `"0.0.3"` |  |
| migration.nodeSelector | object | `{}` | Node labels for pod assignment https://kubernetes.io/docs/user-guide/node-selection/ |
| migration.serviceAccount.annotations | object | `{}` |  |
| migration.serviceAccount.create | bool | `false` |  |
| migration.serviceAccount.name | string | `""` |  |
| migration.tolerations | list | `[]` | Tolerations for pod assignment https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/ |
| nameOverride | string | `""` | Provide a name in place of c8 for `app:` labels |
| pns.affinity | object | `{}` | Affinity for pod assignment https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity |
| pns.autoscaling.enabled | bool | `false` |  |
| pns.autoscaling.maxReplicas | int | `10` |  |
| pns.autoscaling.minReplicas | int | `1` |  |
| pns.autoscaling.targetCPUUtilizationPercentage | int | `80` |  |
| pns.autoscaling.targetMemoryUtilizationPercentage | int | `80` |  |
| pns.container.port | string | `"5000"` |  |
| pns.enabled | bool | `true` |  |
| pns.image.pullPolicy | string | `"IfNotPresent"` |  |
| pns.image.repository | string | `"ghcr.io/configure8inc/c8-pns"` |  |
| pns.image.tag | string | `"0.0.3"` |  |
| pns.nodeSelector | object | `{}` | Node labels for pod assignment https://kubernetes.io/docs/user-guide/node-selection/ |
| pns.podAnnotations | object | `{}` |  |
| pns.podDisruptionBudget.enabled | bool | `false` |  |
| pns.podDisruptionBudget.minAvailable | string | `"50%"` |  |
| pns.podSecurityContext | object | `{}` |  |
| pns.replicaCount | int | `1` |  |
| pns.resources | object | `{}` |  |
| pns.securityContext | object | `{}` |  |
| pns.service | object | `{"enabled":true,"port":"5000","type":"ClusterIP"}` | Configuration for pns service |
| pns.serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| pns.serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| pns.serviceAccount.name | string | `""` | The name of the service account to use. If not set and pns.serviceAccount.create is true, a name is generated using the fullname template |
| pns.tolerations | list | `[]` | Tolerations for pod assignment https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/ |
| ssa.affinity | object | `{}` | Affinity for pod assignment https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity |
| ssa.container.port | string | `"5000"` |  |
| ssa.enabled | bool | `true` |  |
| ssa.image.pullPolicy | string | `"IfNotPresent"` |  |
| ssa.image.repository | string | `"ghcr.io/configure8inc/c8-ssa"` |  |
| ssa.image.tag | string | `"0.0.3"` |  |
| ssa.ingress.annotations | object | `{}` |  |
| ssa.ingress.enabled | bool | `true` |  |
| ssa.ingress.ingressClassName | string | `""` |  |
| ssa.ingress.labels | object | `{}` |  |
| ssa.ingress.pathType | string | `"Prefix"` |  |
| ssa.nodeSelector | object | `{}` | Node labels for pod assignment https://kubernetes.io/docs/user-guide/node-selection/ |
| ssa.podAnnotations | object | `{}` |  |
| ssa.podDisruptionBudget.enabled | bool | `false` | Specifies whether pod disruption budget should be created |
| ssa.podDisruptionBudget.minAvailable | string | `"50%"` | Number or percentage of pods that must be available |
| ssa.podSecurityContext | object | `{}` |  |
| ssa.replicaCount | int | `1` |  |
| ssa.resources | object | `{}` |  |
| ssa.securityContext | object | `{}` |  |
| ssa.service | object | `{"enabled":true,"port":"5000","type":"ClusterIP"}` | Configuration for ssa service |
| ssa.serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| ssa.serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| ssa.serviceAccount.name | string | `""` | The name of the service account to use. If not set and ssa.serviceAccount.create is true, a name is generated using the fullname template |
| ssa.tolerations | list | `[]` | Tolerations for pod assignment https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/ |

----------------------------------------------
