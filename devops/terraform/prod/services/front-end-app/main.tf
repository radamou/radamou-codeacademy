provider "aws" {
  region = "us-east-1"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
}

resource "aws_instance" "aptus" {
  ami = "ami-2d39803a"
  instance_type = "t2.micro"

   user_data = <<-EOF
      #!/bin/bash
      echo "Hello, World" > index.html
      nohup busybox httpd -f -p "${var.server_port}" &
      EOF
  
  vpc_security_group_ids = ["${aws_security_group.aptus-security-group.id}"]

  tags {
    Name = "terraform-aptus"
  }
}

resource "aws_security_group" "aptus-security-group" {
  name = "terraform-aptus-security-group"
  ingress {
    from_port = "${var.server_port}"
    to_port = "${var.server_port}"
    protocol = "${var.protocol}"
    cidr_blocks = ["0.0.0.0/0"]
  }

   lifecycle {
    create_before_destroy = true
  }
}

#configuration for asg
resource "aws_launch_configuration" "aptus-conf" {
  image_id = "ami-2d39803a"
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.aptus-security-group.id}"]
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF
  lifecycle {
    create_before_destroy = true
  }
}

data "aws_availability_zones" "all" {}

#elb for aptus
resource "aws_elb" "aptus-elb" {
  name="terraform-aptus-elb"
  availability_zones=["${data.aws_availability_zones.all.names}"]
  security_groups=["${aws_security_group.aptus-elb-security-group.id}"]

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:${var.server_port}/"
  }

  listener {
    lb_port = "${var.http_port}"
    lb_protocol = "http"
    instance_port = "${var.server_port}"
    instance_protocol = "http"
  }
}

#elb security group for 80 port
resource "aws_security_group" "aptus-elb-security-group" {
  name = "terraform-aptus-elb-security-group"

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = "${var.http_port}"
    to_port = "${var.http_port}"
    protocol = "${var.protocol}"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#asg for aptus test
resource "aws_autoscaling_group" "aptus-asg" {
  launch_configuration = "${aws_launch_configuration.aptus-conf.id}"
  availability_zones= ["${data.aws_availability_zones.all.names}"]

  load_balancers=["${aws_elb.aptus-elb.name}"]
  health_check_type="ELB"

  min_size = 2
  max_size = 5

  tag {
    key = "Name"
    value = "terraform-aptus-asg"
    propagate_at_launch = true
  }
}
