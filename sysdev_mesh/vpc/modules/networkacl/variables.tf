variable "vpc_id" {}

variable "supernet_config_map" {
  type = "map"
}

variable "subnet_dmz_ids" {
  type = "list"
}

variable "subnet_app_ids" {
  type = "list"
}

variable "subnet_sys_ids" {
  type = "list"
}

variable "subnet_data_ids" {
  type = "list"
}
