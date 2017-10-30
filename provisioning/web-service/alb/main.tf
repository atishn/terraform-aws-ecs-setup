variable "alb_name" {}

variable "alb_vpc_id" {}

variable "alb_assigned_security_groups" {
  type = "list"
}

variable "alb_subnet_ids" {
  type = "list"
}

variable "alb_target_group_name" {}

variable "alb_target_group_port" {}

variable "alb_target_group_stickiness" {
  type = "map"
}

output "alb_arn" {
  value = "${aws_alb.main.arn}"
}

output "alb_dns_name" {
  value = "${aws_alb.main.dns_name}"
}

output "alb_target_group_arn" {
  value = "${aws_alb_target_group.target_group.arn}"
}

variable "internal" {
  type = "string"
}

resource "aws_alb" "main" {
  name            = "${var.alb_name}"
  security_groups = ["${var.alb_assigned_security_groups}"]
  subnets         = ["${var.alb_subnet_ids}"]
  internal        = "${var.internal}"
}

resource "aws_alb_target_group" "target_group" {
  name     = "${var.alb_target_group_name}"
  port     = "${var.alb_target_group_port}"
  protocol = "HTTP"
  vpc_id   = "${var.alb_vpc_id}"

  health_check {
    path = "/status"
  }

  lifecycle {
    create_before_destroy = true
  }

  stickiness = ["${var.alb_target_group_stickiness}"]

  depends_on = ["aws_alb.main"]
}

resource "aws_alb_listener" "listener" {
  load_balancer_arn = "${aws_alb.main.arn}"
  port              = "80"

  default_action {
    target_group_arn = "${aws_alb_target_group.target_group.arn}"
    type             = "forward"
  }

  lifecycle {
    create_before_destroy = true
  }
}
