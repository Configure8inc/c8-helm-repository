## Configure AWS access using IAM role for EC2

This method allows you to create an IAM role for C8 and assume it from another role.

### Step 1: Create IAM Role for EC2

[Please refer to the official AWS documentation about creating an AWS IAM role for the EC2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html#create-iam-role)

## Step 2: Create IAM Role to assume by EC2 instance role.

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
| $ec2_role  | The AWS role name from which you want to allow run discovery |

```bash
# Generate a JSON file for the trust relationship
cat >trust-relationship.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${account_id}:role/${ec2_role}"
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
