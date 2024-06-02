# Walkthrough

This is a step by step guide on how to create a home lab.

## Context

### Limitations

1. Vodafone only allows ipv6 host exposure.
1. Github only works with ipv4

### Goals

1. k8s kubernetes cluster in isolated from local lan
1. Argocd integration on github.
1. MinIO object storage
1. Sealed Secrets
1. Prometeus and Grafana

Bonus:

1. Argo workflows.
1. Kustomize.

## Design

### Hardware

### Proxmox

### pfSense

### EdgeServices

### Kubernetes Cluster

#### ArgoCD

can be done with kubespray

#### Sealed Secrets

Add bitnami charts

```sh
argocd repo add https://charts.bitnami.com/bitnami --name bitnami
```

#### Terraform

#### Kubespray

### ArgoCD

#### Github Hooks
