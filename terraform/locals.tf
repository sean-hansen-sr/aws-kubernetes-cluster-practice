# Kubernetes Cluster Private IP Addresses
variable "kubernetes_private_ips" {
  type    = list(string)
  default = ["10.0.2.10", "10.0.2.11", "10.0.2.12"]
}

# Ubuntu Image
variable "ami_id" {
  type    = string
  default = "ami-033ea4ff4a9c726dc"
} 