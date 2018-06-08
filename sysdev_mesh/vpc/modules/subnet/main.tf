resource "aws_subnet" "subnet_dmz" {
  count             = "${length(var.region_config_map["amazon_zones"])}"
  vpc_id            = "${var.vpc_id}"
  cidr_block        = "${element(var.region_config_map["subnets_dmz"], count.index)}"
  availability_zone = "${element(var.region_config_map["amazon_zones"], count.index)}"

  tags {
    Name = "subnet_dmz_${substr(element(var.region_config_map["amazon_zones"], count.index), -2, -1)}"
  }
}

resource "aws_route_table_association" "route_dmz" {
  count          = "${length(var.region_config_map["amazon_zones"])}"
  subnet_id      = "${element(aws_subnet.subnet_dmz.*.id, count.index)}"
  route_table_id = "${var.rt_dmz_id}"
}

resource "aws_subnet" "subnet_app" {
  count             = "${length(var.region_config_map["amazon_zones"])}"
  vpc_id            = "${var.vpc_id}"
  cidr_block        = "${element(var.region_config_map["subnets_app"], count.index)}"
  availability_zone = "${element(var.region_config_map["amazon_zones"], count.index)}"

  tags {
    Name = "subnet_app_${substr(element(var.region_config_map["amazon_zones"], count.index), -2, -1)}"
  }
}

resource "aws_route_table_association" "route_app" {
  count          = "${length(var.region_config_map["amazon_zones"])}"
  subnet_id      = "${element(aws_subnet.subnet_app.*.id, count.index)}"
  route_table_id = "${var.rt_app_id}"
}

resource "aws_subnet" "subnet_sys" {
  count             = "${length(var.region_config_map["amazon_zones"])}"
  vpc_id            = "${var.vpc_id}"
  cidr_block        = "${element(var.region_config_map["subnets_sys"], count.index)}"
  availability_zone = "${element(var.region_config_map["amazon_zones"], count.index)}"

  tags {
    Name = "subnet_sys_${substr(element(var.region_config_map["amazon_zones"], count.index), -2, -1)}"
  }
}

resource "aws_route_table_association" "route_sys" {
  count          = "${length(var.region_config_map["amazon_zones"])}"
  subnet_id      = "${element(aws_subnet.subnet_sys.*.id, count.index)}"
  route_table_id = "${var.rt_app_id}"
}

resource "aws_subnet" "subnet_data" {
  count             = "${length(var.region_config_map["amazon_zones"])}"
  vpc_id            = "${var.vpc_id}"
  cidr_block        = "${element(var.region_config_map["subnets_data"], count.index)}"
  availability_zone = "${element(var.region_config_map["amazon_zones"], count.index)}"

  tags {
    Name = "subnet_data_${substr(element(var.region_config_map["amazon_zones"], count.index), -2, -1)}"
  }
}

resource "aws_route_table_association" "route_data" {
  count          = "${length(var.region_config_map["amazon_zones"])}"
  subnet_id      = "${element(aws_subnet.subnet_data.*.id, count.index)}"
  route_table_id = "${var.rt_data_id}"
}
