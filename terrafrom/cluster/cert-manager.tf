resource "kubernetes_manifest" "letsencrypt-staging-cluster-issuer" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "ClusterIssuer"
    "metadata" = {
      "name" = "letsencrypt-staging"
    }
    "spec" = {
      "acme" = {
        "server" = "https://acme-staging-v02.api.letsencrypt.org/directory"
        "email"  = "hamidreza.ebtehaj@gmail.com"
        "privateKeySecretRef" = {
          "name" = "letsencrypt-staging"
        }
        "solvers" = [
          {
            "http01" = {
              "ingress" = {
                "ingressClassName" = "nginx"
              }
            }
          }
        ]
      }
    }
  }
}

resource "kubernetes_manifest" "letsencrypt-prod-cluster-issuer" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "ClusterIssuer"
    "metadata" = {
      "name" = "letsencrypt-prod"
    }
    "spec" = {
      "acme" = {
        "server" = "https://acme-v02.api.letsencrypt.org/directory"
        "email"  = "hamidreza.ebtehaj@gmail.com"
        "privateKeySecretRef" = {
          "name" = "letsencrypt-prod"
        }
        "solvers" = [
          {
            "http01" = {
              "ingress" = {
                "ingressClassName" = "nginx"
              }
            }
          }
        ]
      }
    }
  }
}
