# Environment
variable homedir {}

# AWS
variable "region" {
  default = "ap-southeast-2"
}

variable "region_config_map" {
  type = "map"
}

variable "vpc_cidr_block" {}

variable "supernet_config_map" {
  type = "map"
}

variable "route53_zone_name" {}

variable "tinc_mesh_ip_octet" {}
variable "global_supernet" {}

variable "instance_key_pair" {
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDi1Ee/tXg/Dc28ZtNna37c0+8oayON/lPIP7xU5aAlQBixcScTz3ESB6SGAH3Hs7zc8cb2KOhwJ9aeqyqkUX/LFnp+KcUOujxjBuAf9Z5eA1jOGm3jcdSbB7k7m7ioFKLRjmS7xxl5Ja3awcCCOjDw76pg4jQoxugO4vL2vipkwudIRgFdmnvx+tsDylVOTlD6PrkLVswiqlwR8FZNkoDVHXeXlBYlLVweG3SXi+UODApx6NMQKpw+qlI16ETQMJCDcIycTw+TsVkMKXBQRwTTT8TG4doWORpl3aEnkM394cWfj4a2wqB495l7HPbY26oREtHXKkN4l9uix+OmvxYZ admin@kubernetes"
}
