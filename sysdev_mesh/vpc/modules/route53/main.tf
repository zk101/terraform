data "aws_route53_zone" "exos_external_zone" {
  name         = "exos.fm"
  private_zone = false
}

resource "aws_route53_zone" "external_zone" {
  name          = "${format("%s.%s", var.region, var.zone_name)}"
  force_destroy = true
}

resource "aws_route53_zone" "internal_zone" {
  name          = "${format("%s.%s", var.region, var.zone_name)}"
  vpc_id        = "${var.vpc_id}"
  force_destroy = true
}

resource "aws_route53_record" "bastion" {
  zone_id = "${data.aws_route53_zone.exos_external_zone.zone_id}"
  name    = "${format("%s.%s", var.region, var.zone_name)}"
  type    = "NS"
  ttl     = "300"
  records = ["${aws_route53_zone.external_zone.name_servers}"]
}
