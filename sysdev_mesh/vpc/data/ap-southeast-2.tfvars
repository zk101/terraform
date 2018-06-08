region_config_map = {
  amazon_zones = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
  subnets_dmz  = ["10.128.0.0/23", "10.128.2.0/23", "10.128.4.0/23"]
  subnets_app  = ["10.128.64.0/23", "10.128.66.0/23", "10.128.68.0/23"]
  subnets_sys  = ["10.128.72.0/23", "10.128.74.0/23", "10.128.76.0/23"]
  subnets_data = ["10.128.128.0/23", "10.128.130.0/23", "10.128.132.0/23"]
}

supernet_config_map = {
  dmz  = "10.128.0.0/18"
  app  = "10.128.64.0/18"
  data = "10.128.128.0/18"
}

region = "ap-southeast-2"

vpc_cidr_block = "10.128.0.0/16"

global_supernet = "10.128.0.0/11"

tinc_mesh_ip_octet = "1"

route53_zone_name = "sysdev-mesh.exos.fm"
