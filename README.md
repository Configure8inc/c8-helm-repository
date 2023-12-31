# [configure8](https://app.configure8.io) Kubernetes Helm Charts.

## Requirements

Kubernetes: `>=1.22.0-0`

## Usage

To utilize these charts, it's essential to have [Helm](https://helm.sh) installed. For guidance on initiating with Helm, you can consult its [documentation](https://helm.sh/docs/).

Add the [Configure8](https://app.configure8.io) chart repository and update it:

```bash
helm repo add c8 https://helm.configure8.io/store/
helm repo update
```

## Installation

### c8 Deployment Guide
- [AWS\GCP\Azure\Self-Hosted](helm-charts/c8/README.md)

#### Configure AWS access for the discovery job
- [Using service account](helm-charts/c8/AWS-IAM-SA.md)
- [Using IAM role for EC2](helm-charts/c8/AWS-IAM-EC2-ROLE.md)
- [Using access keys for IAM users (AWS\Azure\GCP\Self-Hosted)](helm-charts/c8/AWS-IAM-KEYS.md)
- [Using GCP ServiceAccount (GKE)](helm-charts/c8/AWS-GCP-SA.md)

#### Configure GCP access for the discovery job
- [Using service account](https://docs.configure8.io/configure8-product-docs/fundamentals/plug-ins/gcp)

#### Configure Azure access for the discovery job
- [Using application](https://docs.configure8.io/configure8-product-docs/fundamentals/plug-ins/azure)

### c8-k8s-agent Deployment Guide
- [AWS\GCP\Azure\Self-Hosted](helm-charts/c8/README.md)
