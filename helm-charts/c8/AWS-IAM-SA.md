## Step 4: Configure AWS access for the discovery job using service account (AWS EKS)

### Step 1: Create IAM Role for C8 and DJM Service Accounts

### Step 1.1: Create IAM Policy

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

### Step 1.2: Create Trust Relationship for IAM Role

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

### Step 1.3: Create IAM Role

```bash
# Create an IAM role with a defined trust relationship and description
aws iam create-role --role-name sh-c8-service-account --assume-role-policy-document file://trust-relationship-sa.json --description "The role for the Configure8 pods service account"
```

### Step 2: Create IAM Role to Assume by C8 and DJM Service Accounts

### Step 2.1: Download IAM Policy

Download the IAM policy that grants read permissions to all AWS resources:

```bash
curl -o sh-c8-discovery-policy.json https://configure8-resources.s3.us-east-2.amazonaws.com/iam/sh-c8-discovery-policy.json
```

### Step 2.2: Create IAM Policy

Create the IAM policy:

```bash
aws iam create-policy --policy-name sh-c8-discovery-policy --policy-document file://sh-c8-discovery-policy.json
```

### Step 2.3: Create IAM Role

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
> If you want to discover more AWS accounts, please repeat the 2nd step for each account.
