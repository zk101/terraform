resource "aws_eip" "eip_nat" {
  vpc = true
}

resource "aws_nat_gateway" "natgw" {
  allocation_id = "${aws_eip.eip_nat.id}"
  subnet_id     = "${var.subnet_dmz_ids[0]}"

  tags {
    Name = "netgw-sysdev-mesh"
  }
}

resource "aws_route" "route_app_natgw" {
  route_table_id         = "${var.rt_app_id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.natgw.id}"
}
