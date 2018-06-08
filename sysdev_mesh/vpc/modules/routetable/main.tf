resource "aws_route_table" "routetable_dmz" {
  vpc_id = "${var.vpc_id}"

  tags {
    Name = "routetable_dmz-sysdev-mesh"
  }
}

resource "aws_route_table" "routetable_app" {
  vpc_id = "${var.vpc_id}"

  tags {
    Name = "routetable_app-sysdev-mesh"
  }
}

resource "aws_route_table" "routetable_data" {
  vpc_id = "${var.vpc_id}"

  tags {
    Name = "routetable_data-sysdev-mesh"
  }
}

resource "aws_route" "route_dmz_routetable" {
  route_table_id         = "${aws_route_table.routetable_dmz.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${var.igw_id}"
}
