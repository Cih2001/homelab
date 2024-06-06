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

#### Nginx

We need to use Nginx proxy to tunnel ipv6 request to ipv4. Remember, our vodafone modem can only expose ipv6
but our kubernetes cluster runs on ipv4.

Set the nginx config at `/etc/nginx/sites-available/default` to:

```
server {
        listen [::]:8081 default_server;
        server_name _;

        location /api/webhook {
                proxy_pass https://10.100.0.129/api/webhook;  # Nginx ingress service external IP address
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
        }
}
```

### Kubernetes Cluster

#### Terraform

#### Kubespray

#### NFS Subdir Provisioner

make it default after setting up

```sh
kubectl patch storageclass nfs-client -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

#### ArgoCD

install it with kube spray or help. Then setup an ingres for it

```sh
k create ingress -n argocd argocd-server \
--class=nginx \
--rule="argocd.geekembly.com/*=argocd-server:443" \
--rule="github.geekembly.com/api/webhook=argocd-server:443" \
--annotation='nginx.ingress.kubernetes.io/backend-protocol=HTTPS' \
--annotation='nginx.ingress.kubernetes.io/force-ssl-redirect=true' \
--annotation='nginx.ingress.kubernetes.io/ssl-passthrough=true'
```

second rule is to make sure that our edge server config works for github webhook deliveries.

and to get the password:

```sh
argocd admin initial-password -n argocd
```

#### Sealed Secrets

Add bitnami charts

```sh
argocd repo add https://charts.bitnami.com/bitnami --name bitnami
```

### ArgoCD

#### Github Hooks

### Argo Workflows

Argo workflows are installed automatically as a argo cd app with helm charts.
As argo cli uses kubectl context, it has first class access to argo workflows.
For the UI however we need to use a token. We can use `argo-workflows-server` token for example.

#### Ingress

setup ingress if not yet.

```sh
k create ingress -n argo argo-workflows-server \
--class=nginx --rule="argo.geekembly.com/*=argo-workflows-server:80" \
--annotation='nginx.ingress.kubernetes.io/backend-protocol=HTTP' \
--annotation='nginx.ingress.kubernetes.io/force-ssl-redirect=true' \
--annotation='nginx.ingress.kubernetes.io/ssl-passthrough=true'
```

#### Accessing UI

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

#### Workflow SA

When creating a workflow in a namespace, argo uses the default sa in that namespace, which will almost always have insufficient privileges by default.

Therefore, we need to define a role:

```sh
k apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: argo-workflows-admin
  namespace: <namespace>
rules:
  - apiGroups:
      - argoproj.io
    resources:
      - workflowtaskresults
    verbs:
      - list
      - get
      - watch
      - patch
      - create
      - update
      - delete
EOF
```

and assign it to the default sa.

```sh
k create rolebinding <cluster-role-binding-name> --clusterrole=argo-workflows-executor --serviceaccount=<namespace>:default -n <namespace>
```
