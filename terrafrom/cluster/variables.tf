variable "acme_email" {
  description = "Email address used for ACME registration"
  type        = string
  default     = "hamidreza.ebtehaj@gmail.com"
}

variable "ingress_class" {
  description = "Ingress class to be used for ACME http01 solver"
  type        = string
  default     = "nginx"
}
