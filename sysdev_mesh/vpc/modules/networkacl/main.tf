resource "aws_network_acl" "networkacl_dmz" {
  vpc_id     = "${var.vpc_id}"
  subnet_ids = ["${var.subnet_dmz_ids}"]

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "deny"
    cidr_block = "${var.supernet_config_map["data"]}"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = "-1"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags {
    Name = "networkacl_dmz-sysdev-mesh"
  }
}

resource "aws_network_acl" "networkacl_app" {
  vpc_id     = "${var.vpc_id}"
  subnet_ids = ["${concat(var.subnet_app_ids, var.subnet_sys_ids)}"]

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags {
    Name = "networkacl_app-sysdev-mesh"
  }
}

resource "aws_network_acl" "networkacl_data" {
  vpc_id     = "${var.vpc_id}"
  subnet_ids = ["${var.subnet_data_ids}"]

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "${var.supernet_config_map["app"]}"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "${var.supernet_config_map["app"]}"
    from_port  = 0
    to_port    = 0
  }

  tags {
    Name = "networkacl_data-sysdev-mesh"
  }
}
