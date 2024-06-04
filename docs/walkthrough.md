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

#### NFS

make sure to run, so then pods can change the owenership.

```sh
chown -R 999:999 /mnt/vda1/nfs/
```

### Kubernetes Cluster

#### NFS Subdir Provisioner

make it default after setting up

```sh
kubectl patch storageclass nfs-client -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

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

### Argo Workflows

Argo workflows are installed automatically as a argo cd app with helm charts. As argo cli uses kubectl context, it has first class access to argo workflows. For the UI however we need to use a token. We can use `argo-workflows-server` token for example.

First create a secret that holds token

```sh
k apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  namespace: argo
  name: argo.service-account-token
  annotations:
    kubernetes.io/service-account.name: argo-workflows-server
type: kubernetes.io/service-account-token
EOF
secret/argo.service-account-token created
```

And then get the token like:

```sh
ARGO_TOKEN="Bearer $(kubectl get secret argo.service-account-token -n argo -o=jsonpath='{.data.token}' | base64 --decode)"
echo $ARGO_TOKEN
```

After this, we have to portforward to the argo server to be able to login using browser.

```sh
k port-forward -n argo services/argo-workflows-server 8080:80
```
