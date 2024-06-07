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

install with helm:

```sh
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --set nfs.server=x.x.x.x \
    --set nfs.path=/exported/path
```

make it default after setting up

```sh
k patch storageclass nfs-client -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

and then make sure it is set to default by

```sh
k get storageclass
```

#### ArgoCD

ArgoCD is install automatically by kubespary, to access it however, we need to do some manual modifications.

##### Ingress

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

##### Admin Password & CLI

You can get the admin password by

```sh
argocd admin initial-password -n argocd
```

however to use the cli, you have to login with kube context

```sh
argocd login argocd.geekembly.com --core
```

then then you have to set your context to use argocd by default (avoid this, use ui instead.)

```sh
k config set-context --current --namespace=argocd
```

##### Github Access Token

remember that you need to set the context to use argocd namespace first (previous section)

```sh
argocd repo add <repo-link-https> --username=<github_user_name> --password=<github_token>
```

Additional info at [docs](https://argo-cd.readthedocs.io/en/stable/user-guide/private-repositories/)

##### Github Webhook Secret

In the argocd secret, add github webhook secret `webhook.github.secret`

```sh
k edit secret -n argocd argocd-secret
```

and then add

```yaml
stringData:
  webhook.github.secret: <your webhook password>
```

#### Sealed Secrets

will be installed automatically by argocd if you run

```sh
k apply -f applications/apps.yaml
```

### Argo Workflows

Argo workflows are installed automatically as a argo cd app with helm charts when you run:

```sh
k apply -f applications/apps.yaml
```

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

#### Workflow SA

When creating a workflow in a namespace, argo uses the default sa in that namespace, which will almost always have insufficient privileges by default.

Therefore, we need to define a role:

```sh
kubectl create role argo-workflows-admin \
  --namespace <namespace> \
  --verb=list --verb=get --verb=watch --verb=patch --verb=create --verb=update --verb=delete \
  --resource=workflowtaskresults.argoproj.io
```

and assign it to the default sa.

```sh
k create rolebinding <cluster-role-binding-name> --clusterrole=argo-workflows-executor --serviceaccount=<namespace>:default -n <namespace>
```
