output "rt_dmz_id" {
  value = "${aws_route_table.routetable_dmz.id}"
}

output "rt_app_id" {
  value = "${aws_route_table.routetable_app.id}"
}

output "rt_data_id" {
  value = "${aws_route_table.routetable_data.id}"
}
