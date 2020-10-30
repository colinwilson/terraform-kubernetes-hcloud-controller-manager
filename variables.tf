# Required configuration variables
variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
}
variable "network_name" {
  description = "Hetzner Cloud Network name"
}

# Optional configuration variables
variable "cluster_cidr" {
  default     = "10.244.0.0/16"
  description = "Pod Network Range"
}

variable "ccm_image_version" {
  type        = string
  description = "Hetzner Cloud Controller Manager image version"
  default     = "v1.8.1"
}
