# Kubernetes Cluster Private IP Addresses
variable "kubernetes_private_ips" {
  type    = list(string)
  default = ["10.0.2.10", "10.0.2.11", "10.0.2.12"]
}

# Ubuntu Setting Values
variable "ubuntu_setting_values" {
  type        = map(string)
  description = "A map of values for settings Ubuntu values"
  
  default = {
    ami              = "ami-033ea4ff4a9c726dc"
    instance_type    = "t3.small"
  }
}
