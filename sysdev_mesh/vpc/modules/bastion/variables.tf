variable "vpc_id" {}
variable "route53_external_zone_id" {}

variable "global_supernet" {}

variable "tinc_mesh_ip_octet" {}

variable "zone_name" {}

variable "region" {}
variable "instance_key_pair" {}
variable "vpc_cidr_block" {}

variable "rt_app_id" {}

variable "rt_dmz_id" {}

variable "subnet_dmz_ids" {
  type = "list"
}
