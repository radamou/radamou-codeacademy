output "public_ip" {
  value = "${aws_instance.aptus.public_ip}"
}

output "elb_dns_name" {
  value = "${aws_elb.aptus-elb.dns_name}"
}