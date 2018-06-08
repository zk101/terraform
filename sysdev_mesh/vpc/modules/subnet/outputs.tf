output "subnet_dmz_ids" {
  value = ["${aws_subnet.subnet_dmz.*.id}"]
}

output "subnet_app_ids" {
  value = ["${aws_subnet.subnet_app.*.id}"]
}

output "subnet_sys_ids" {
  value = ["${aws_subnet.subnet_sys.*.id}"]
}

output "subnet_data_ids" {
  value = ["${aws_subnet.subnet_data.*.id}"]
}
