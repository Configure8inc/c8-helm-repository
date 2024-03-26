## Configure AWS access using access keys for IAM users

This method describes the process of configuring AWS access by creating and using access keys for IAM users. It enables AWS access across all installation methods. Don't forget to add AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY to the c8-secret during installation.

### Step 1: Create IAM User

[Please refer to the official AWS documentation about creating access keys for IAM users](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html)

> **Important**
> As a [best practice](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html), use temporary security credentials (such as IAM roles) instead of creating long-term credentials like access keys.

### Step 2: Create IAM Role to assume by EC2 instance role.

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

Create an IAM role that can be assumed by EC2 roles:

| Name | Description |
|-----|-------------|
| $account_id | The AWS account id from which you want to allow run discovery |
| $iam_user  | The AWS IAM user name from which you want to allow run discovery |

```bash
# Generate a JSON file for the trust relationship
cat >trust-relationship.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${account_id}:user/${iam_user}"
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

### Attach the sh-c8-discovery-policy policy to the sh-c8-discovery role

```bash
aws iam attach-role-policy --role-name sh-c8-discovery --policy-arn=arn:aws:iam::${account_id}:policy/sh-c8-discovery-policy
```

> **Note**
> If you want to discover more AWS accounts, please repeat the 2nd step for each account.

> **Important**
> Don't forget to add the AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY variables to the c8-secret.
