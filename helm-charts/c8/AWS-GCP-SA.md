## Configure AWS access using GCP ServiceAccount (GKE)

This method outlines the procedure for configuring AWS access through a GCP ServiceAccount. It is designed to establish secure cross-cloud access, allowing C8 managed by Google Cloud Platform (GCP) to interact seamlessly with AWS services.

## Step 1: Enable Workload Identity (skip if already enabled)

You can enable Workload Identity on an existing Standard cluster by using the gcloud CLI or the Google Cloud console. Existing node pools are unaffected, but any new node pools in the cluster use Workload Identity.

```bash
gcloud container clusters update CLUSTER_NAME \
    --region=COMPUTE_REGION \
    --workload-pool=PROJECT_ID.svc.id.goog
```

> **Note**
> You can check the current status by running the command ```gcloud container clusters describe CLUSTER_NAME --region=COMPUTE_REGION --format="value(workloadIdentityConfig)```

Replace the following:

- CLUSTER_NAME: the name of your existing GKE cluster.
- COMPUTE_REGION: the Compute Engine region of your cluster. For zonal clusters, use --zone=COMPUTE_ZONE.
- PROJECT_ID: your Google Cloud project ID.

## Step 2: Create a service account and bind it with a k8s service account

<details>
  <summary style="font-size: 22px;">Step 2.1: Create the c8-backend service account and bind it with the k8s service account</summary>

> **Important**
> Replace the PROJECT_ID with the project ID of the Google Cloud project of your IAM service account.

Create GCP SA which will be bound to K8s SA

```bash
gcloud iam service-accounts create c8-backend \
    --project=PROJECT_ID
```

Bind necessary IAM roles to the GCP SA

```bash
gcloud projects add-iam-policy-binding PROJECT_ID \
    --member "serviceAccount:c8-backend@PROJECT_ID.iam.gserviceaccount.com" \
    --role "roles/viewer"
```

Create K8s SA for workload identity in the c8 namespace

```bash
kubectl -n c8 create sa c8-backend
```

Bind K8s SA with GCP SA

```bash
gcloud iam service-accounts add-iam-policy-binding c8-backend@PROJECT_ID.iam.gserviceaccount.com \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:PROJECT_ID.svc.id.goog[c8/c8-backend]"
```

Annotate the Kubernetes Service Account, which can be achieved by adding an annotation to the c8-backend service account during the Helm installation command(or by using the BACKEND_SA_ANNOTATION variable with the installation helper script).

```bash
kubectl -n c8 annotate serviceaccount c8-backend iam.gke.io/gcp-service-account=c8-backend@PROJECT_ID.iam.gserviceaccount.com
```

Get the service account unique client ID (will be used in the step below to create an AWS IAM role).

```bash
gcloud iam service-accounts describe --format json c8-backend@PROJECT_ID.iam.gserviceaccount.com | jq -r '.uniqueId'
```

</details>

<details>
  <summary style="font-size: 22px;">Step 2.2: Create the c8-djw service account and bind it with the k8s service account</summary>

> **Important**
> Replace the PROJECT_ID with the project ID of the Google Cloud project of your IAM service account.

Create GCP SA which will be bound to K8s SA

```bash
gcloud iam service-accounts create c8-djw \
    --project=PROJECT_ID
```

Bind necessary IAM roles to the GCP SA

```bash
gcloud projects add-iam-policy-binding PROJECT_ID \
    --member "serviceAccount:c8-djw@PROJECT_ID.iam.gserviceaccount.com" \
    --role "roles/viewer"
```

Create K8s SA for workload identity in the c8 namespace

```bash
kubectl -n sh create sa c8-djw
```

Bind K8s SA with GCP SA

```bash
gcloud iam service-accounts add-iam-policy-binding c8-djw@PROJECT_ID.iam.gserviceaccount.com \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:PROJECT_ID.svc.id.goog[c8/c8-djw]"
```

Annotate the Kubernetes Service Account, which can be achieved by adding an annotation to the c8-djw service account during the Helm installation command(or by using the DJW_SA_ANNOTATION variable with the installation helper script).

```bash
kubectl -n c8 annotate serviceaccount c8-djw iam.gke.io/gcp-service-account=c8-djw@PROJECT_ID.iam.gserviceaccount.com
```

Get the service account unique client ID (will be used in the step below to create an AWS IAM role).

```bash
gcloud iam service-accounts describe --format json c8-djw@PROJECT_ID.iam.gserviceaccount.com | jq -r '.uniqueId'
```

</details>

</details>

## Step 3: Create AWS IAM Role (will be assumed by C8 backend and djm service accounts to discover resources)

### Step 3.1: Download IAM Policy

Download the IAM policy that grants read permissions to all AWS resources:

```bash
curl -o sh-c8-discovery-policy.json https://configure8-resources.s3.us-east-2.amazonaws.com/iam/sh-c8-discovery-policy.json
```

### Step 3.2: Create IAM Policy

Create the IAM policy:

```bash
aws iam create-policy --policy-name sh-c8-discovery-policy --policy-document file://sh-c8-discovery-policy.json
```

### Step 3.3: Create IAM Role

Create an IAM role that can be assumed by the C8 and DJM service accounts:

> **Important**
> To get gcp_sa_backend_client_id and gcp_sa_djw_client_id values please check the 2.1 step.

| Name | Description |
|-----|-------------|
| $account_id | The AWS account id from which you want to allow run discovery |
| $gcp_sa_backend_client_id | The GCP IAM service account unique client ID (c8-backend) |
| $gcp_sa_djw_client_id | The GCP IAM service account unique client ID (c8-djw) |

```bash
# Generate a JSON file for the trust relationship
cat >trust-relationship.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "RoleForGoogleBackend",
            "Effect": "Allow",
            "Principal": {
                "Federated": "accounts.google.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "accounts.google.com:aud": "${gcp_sa_backend_client_id}"
                }
            }
        },
        {
            "Sid": "RoleForGoogleDjw",
            "Effect": "Allow",
            "Principal": {
                "Federated": "accounts.google.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "accounts.google.com:aud": "${gcp_sa_djw_client_id}"
                }
            }
        }
    ]
}
EOF
```

### Create an IAM role with a defined trust relationship and description

```bash
aws iam create-role --role-name sh-c8-discovery --assume-role-policy-document file://trust-relationship.json --description "sh-c8-discovery"
```

### Attach the sh-c8-discovery-policy policy to the sh-c8-discovery role

```bash
aws iam attach-role-policy --role-name sh-c8-discovery --policy-arn=arn:aws:iam::$account_id:policy/sh-c8-discovery-policy
```

> **Note**
> If you want to discover more AWS accounts, please repeat the 3rd step for each account.
