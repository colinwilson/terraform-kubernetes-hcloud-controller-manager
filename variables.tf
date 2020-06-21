# Required configuration variables
variable "hcloud_token" {
    description = "Hetzner Cloud API Token"
}
variable "network_name" {
    description = "Hetzner Cloud Network name"
}
variable "cluster_cidr" {
    default = "10.244.0.0/16"
    description = "Pod Network Range"
}