provider "aws" {
  region                  = "${var.region}"
  shared_credentials_file = "${var.homedir}/.aws/creds"
}

module "vpc" {
  source         = "modules/vpc"
  vpc_cidr_block = "${var.vpc_cidr_block}"
}

module "route53" {
  source    = "modules/route53"
  vpc_id    = "${module.vpc.vpc_id}"
  zone_name = "${var.route53_zone_name}"
  region    = "${var.region}"
}

module "igw" {
  source = "modules/igw"
  vpc_id = "${module.vpc.vpc_id}"
}

module "routetable" {
  source         = "modules/routetable"
  vpc_id         = "${module.vpc.vpc_id}"
  vpc_cidr_block = "${var.vpc_cidr_block}"
  igw_id         = "${module.igw.igw_id}"
}

module "subnet" {
  source            = "modules/subnet"
  region_config_map = "${var.region_config_map}"
  vpc_id            = "${module.vpc.vpc_id}"
  rt_dmz_id         = "${module.routetable.rt_dmz_id}"
  rt_app_id         = "${module.routetable.rt_app_id}"
  rt_data_id        = "${module.routetable.rt_data_id}"
}

module "networkacl" {
  source              = "modules/networkacl"
  vpc_id              = "${module.vpc.vpc_id}"
  supernet_config_map = "${var.supernet_config_map}"
  subnet_dmz_ids      = "${module.subnet.subnet_dmz_ids}"
  subnet_app_ids      = "${module.subnet.subnet_app_ids}"
  subnet_sys_ids      = "${module.subnet.subnet_sys_ids}"
  subnet_data_ids     = "${module.subnet.subnet_data_ids}"
}

module "natgw" {
  source         = "modules/natgw"
  rt_app_id      = "${module.routetable.rt_app_id}"
  subnet_dmz_ids = "${module.subnet.subnet_dmz_ids}"
}

module "bastion" {
  source                   = "modules/bastion"
  vpc_id                   = "${module.vpc.vpc_id}"
  vpc_cidr_block           = "${var.vpc_cidr_block}"
  route53_external_zone_id = "${module.route53.external_zone_id}"
  global_supernet          = "${var.global_supernet}"
  zone_name                = "${var.route53_zone_name}"
  tinc_mesh_ip_octet       = "${var.tinc_mesh_ip_octet}"
  region                   = "${var.region}"
  instance_key_pair        = "${var.instance_key_pair}"
  rt_app_id                = "${module.routetable.rt_app_id}"
  rt_dmz_id                = "${module.routetable.rt_dmz_id}"
  subnet_dmz_ids           = "${module.subnet.subnet_dmz_ids}"
}
