provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "kubernetes-admin@homelab-k8s"
}
