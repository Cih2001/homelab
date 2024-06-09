# Walkthrough

This is a step by step guide on how to create a home lab.

## Context

### Limitations

1. Vodafone only allows ipv6 host exposure.
1. Github only works with ipv4

### Goals

1. k8s kubernetes cluster in isolated from local lan
1. Metallb and Nginx Ingress Setup
1. Cert-Manager Setup + Let's Encrypt
1. Argocd integration on github.
1. Argo Workflows + Argo Events + Github Integration
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
# This is for accessing your web applications inside kubernetes.
# If you don't want to access any of your web applications from outside world
# modify the server name to be only
# server_name github.<domain_name>;
# which is needed to received github webhooks.
server {
        listen 80;
        listen [::]:80;

        server_name <domain_name> www.<domain_name>;

        location / {
                proxy_pass http://<external-nginx-ingress-ip>;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
        }
}
```

This forwards all http traffic from your domain to your k8s cluster.

However, that's not enough. We need to handle https requests as well. Since we are going
to manage ssl certificates with cert-manager in our kubernetes cluster, our ssl connections
will terminate in kubernetes cluster. Therefore, all we need to do is to stream https
connections further to the

Add following to the end of nginx default config at `/etc/nginx/nginx.conf`:

```
stream {
        server {
                listen 443;
                listen [::]:443;
                proxy_pass <external-nginx-ingress-ip>:443;
        }
}
```

Remember that you have to do this step, after having your kubernetes cluster fully set up
as you need your external nginx ingress ip address.

### Digital Ocean Host

As our Vodafone modem only enables IPv6 host exposure, we are limited to that and we could get away with it, if Github were supporting it.

Unfortenatly, github only support IPv4 for its integration. As a result, to be able to receive Github webhooks, we need to buy a host, to be able
to received ipv4 request and convert them to ipv6 using nginx.

I'm using Digital ocean, but this should be able to be done with any vps service.

#### DNS records

| type  | domain | IP                  |
| ----- | ------ | ------------------- |
| A     | github | IP of external host |
| CNAME | www    | <your domain>       |

#### Nginx

Very similar to Edge service, except that we have to tunnel ipv4 to ipv6, so at `/etc/nginx/sites-available/default`:

```
server {
        listen 80;
        listen [::]:80;

        server_name <domain_name> www.<domain_name>;

        location / {
                proxy_pass http://<ipv6-address-of-edge-service>;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
        }
}

```

and at the end of default nginx config at `/etc/nginx/nginx.conf` append:

```
stream {
        server {
                listen 443;
                listen [::]:443;
                proxy_pass [<ipv6-address-of-edge-service>]:443;
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
--rule="github.geekembly.com/api/webhook=argocd-server:80" \
--annotation='nginx.ingress.kubernetes.io/backend-protocol=HTTPS' \
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

#### MinIO

Minio is an opensource s3 compatible object storage. We will use as:

1. Default object storage for argo workflow artifacts.
1. To setup our own container registry. (We don't want to push our internal images to docker hub or other places.)
1. Some web applications we deploy later may benefit from an s3 compatible object storage.

Minio will be installed automatically by argocd if you run

```sh
k apply -f applications/apps.yaml
```

you also need to install mc cli.

```sh
brew install minio/stable/mc
```

after that, login using default username and password `minioadmin` and `minioadmin` and create a access key, you can name it `workflow-ak`

add the access key to the mc cli using

```sh
mc alias set workflow-ak http://minio.api.geekembly.com <access-key> <secret>
```

also create a bucket using ui, you can name it `artifacts-repo`. now you can list everthing in the bucket by

```sh
mc ls workflow-ak/artifacts-repo
```

also remember to change the admin password.

### Registry

```sh
k apply --dry-run -o yaml -f - <<EOF | kubeseal -o yaml
apiVersion: v1
kind: Secret
metadata:
  name: registry-config-sec
  namespace: registry
stringData:
  config.yml: |
    version: 0.1
    log:
      level: debug
      formatter: text
      fields:
        service: registry
    storage:
      s3:
        accesskey: <minio-access-key>
        secretkey: <minio-secret-key>
        region: us-east-1
        bucket: container-repo
        regionendpoint: minio-svc.minio:9000
        secure: false
        v4auth: true
        chunksize: 5242880
        rootdirectory: /
      delete:
        enabled: true
      maintenance:
        readonly:
          enabled: false
    http:
      addr: :5000
EOF
```

### Argo Workflows

Argo workflows are installed automatically as a argo cd app with helm charts when you apply `apps.yaml`:

Remember to modify the ingress domain in `apps.yaml` file before applying and then:

```sh
k apply -f applications/apps.yaml
```

As argo cli uses kubectl context, it has first class access to argo workflows.
For the UI however we need to use a token. We can use `argo-workflows-server` token for example.

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

#### Artifacts Repository

To be able to save artifact, we need to make a repository available to argo workflows. We are going to use our Minio object storage.

First, we have to define the repository to the argo:

```sh
k apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: argo
  name: artifact-repositories
  annotations:
    workflows.argoproj.io/default-artifact-repository: default-v1-s3-artifact-repository
data:
  default-v1-s3-artifact-repository: |
    s3:
      bucket: artifacts-repo
        endpoint: minio-svc.minio:9000
      insecure: true
      accessKeySecret:
        name: minio-workflow-ak
        key: accessKey
      secretKeySecret:
        name: minio-workflow-ak
        key: secretKey
EOF
```

Now, in every namespace you use workflows:

1. You have to provide the `minio-workflow-ak` Secret. You can use the following command to create the secret using sealed secret.

   ```sh
   k create secret generic -n <app-namespace> minio-workflow-ak --dry-run=client --from-literal="accessKey=<minio-access-key>" --from-literal="secretKey=<minio-secret-key>" --output=yaml | kubeseal -o yaml
   ```

   And add the result to your deployment files for argocd to pick them up.

1. You have to define a reference to artifact repository in your workflows

   ```yaml
   spec:
     artifactRepositoryRef:
       configMap: artifact-repositories
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
k create rolebinding <role-binding-name> --role=argo-workflows-admin --serviceaccount=<namespace>:default -n <namespace>
```
