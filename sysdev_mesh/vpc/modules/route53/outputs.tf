output "external_zone_id" {
  value = "${aws_route53_zone.external_zone.zone_id}"
}

output "internal_zone_id" {
  value = "${aws_route53_zone.internal_zone.zone_id}"
}
