# Kubernetes Cluster Private IP Addresses
variable "kubernetes_private_ips" {
  type    = list(string)
  default = ["10.0.2.10", "10.0.2.11", "10.0.2.12"]
}
