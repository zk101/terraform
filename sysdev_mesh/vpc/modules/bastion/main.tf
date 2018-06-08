data "aws_ami" "centos7" {
  most_recent = true

  filter {
    name   = "name"
    values = ["CentOS Linux 7*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["679593333241"] # CentOS
}

data "template_file" "cloud_init" {
  template = "${file("${path.module}/scripts/cloud-init.tpl")}"

  vars {
    vpc_supernet  = "${var.vpc_cidr_block}"
    external_ip   = "${aws_eip.bastion.public_ip}"
    mesh_ip_octet = "${var.tinc_mesh_ip_octet}"
    region        = "${replace(var.region, "-", "_")}"
  }
}

data "aws_iam_instance_profile" "bastion" {
  name = "tinc-hosts-sysdev-mesh"
}

resource "aws_eip" "bastion" {
  vpc = true
}

resource "aws_key_pair" "bastion" {
  key_name   = "sysdev-mesh-bastion"
  public_key = "${var.instance_key_pair}"
}

resource "aws_security_group" "bastion" {
  name        = "Bastion sysdev_mesh"
  description = "Bastion"
  vpc_id      = "${var.vpc_id}"

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Tinc
  ingress {
    from_port   = 655
    to_port     = 655
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All Outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "Bastion sysdev-mesh"
  }
}

resource "aws_instance" "bastion" {
  ami                    = "${data.aws_ami.centos7.id}"
  instance_type          = "t2.micro"
  subnet_id              = "${var.subnet_dmz_ids[0]}"
  user_data              = "${data.template_file.cloud_init.rendered}"
  vpc_security_group_ids = ["${aws_security_group.bastion.id}"]
  key_name               = "sysdev-mesh-bastion"
  iam_instance_profile   = "${data.aws_iam_instance_profile.bastion.name}"

  tags {
    Name = "Bastion sysdev-mesh"
  }
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = "${aws_instance.bastion.id}"
  allocation_id = "${aws_eip.bastion.id}"
}

resource "aws_route53_record" "bastion" {
  zone_id = "${var.route53_external_zone_id}"
  name    = "${format("bastion.%s.%s", var.region, var.zone_name)}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_eip.bastion.public_ip}"]
}

resource "aws_route" "bastion_app" {
  route_table_id         = "${var.rt_app_id}"
  destination_cidr_block = "${var.global_supernet}"
  instance_id            = "${aws_instance.bastion.id}"
}

resource "aws_route" "bastion_dmz" {
  route_table_id         = "${var.rt_dmz_id}"
  destination_cidr_block = "${var.global_supernet}"
  instance_id            = "${aws_instance.bastion.id}"
}
