variable "name" {}

variable "ec2_instance_type" {}

variable "ec2_keyname" {}

variable "staff_cidrs" {
  description = "List of strings describing allowed staff networks."
  type        = "list"
}

variable "vpc_public_subnet_ids" {
  type = "list"
}

variable "vpc_vpc_id" {}

variable "vpc_http_s_access_sg_id" {}

variable "ssl_certificate_arn" {}

variable "ecr_hub-services_uri" {}

variable "ecr_hub-frontend_uri" {}

variable "sp_server_name" {}

variable "sp_server_port" {}

variable "morning_mail_base_url" {}

variable "morning_mail_bearer" {}

variable "bedework_base_url" {}

output "hub-frontend_url" {
  value = "${module.hub-frontend.alb_dns_name}"
}

module "ecs_cluster" {
  source        = "../ecs-cluster"
  name          = "workshop-${var.name}"
  admin_cidrs   = "${var.staff_cidrs}"
  keypair_name  = "${var.ec2_keyname}"
  vpc_id        = "${var.vpc_vpc_id}"
  subnet_ids    = "${var.vpc_public_subnet_ids}"
  instance_type = "${var.ec2_instance_type}"
}

module "service_config" {
  source               = "../web-service/config"
  vpc_id               = "${var.vpc_vpc_id}"
  public_subnet_ids    = "${var.vpc_public_subnet_ids}"
  ecs_cluster_arn      = "${module.ecs_cluster.cluster_arn}"
  ecs_service_role_arn = "${module.ecs_cluster.service_role_arn}"
}

resource "aws_security_group" "alb_sg" {
  description = "Controls access to ECS instances"
  vpc_id      = "${var.vpc_vpc_id}"
  name        = "${var.name}-alb-security-group"

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = ["${module.ecs_cluster.ecs_instance_security_group_id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "hub-services" {
  source            = "../web-service"
  name              = "hub-services-${var.name}"
  target_group_port = "8080"
  image_repo_url    = "${var.ecr_hub-services_uri}"

  security_groups = [
    "${var.vpc_http_s_access_sg_id}",
    "${module.ecs_cluster.cluster_access_security_group_id}",
  ]

  alb_stickiness_map = {
    type    = "lb_cookie"
    enabled = false
  }

  environment_variables = <<EOF
[
  { "name": "MORNING_MAIL_BASE_URL", "value": "${var.morning_mail_base_url}" },
  { "name": "MORNING_MAIL_BEARER", "value": "${var.morning_mail_bearer}" },
  { "name": "BEDEWORK_BASE_URL", "value": "${var.bedework_base_url}" }
]
EOF

  config_map = "${module.service_config.config_map}"
}

module "hub-services-internal" {
  source            = "../web-service"
  name              = "hub-services-internal-${var.name}"
  target_group_port = "8080"
  image_repo_url    = "${var.ecr_hub-services_uri}"

  security_groups = [
    "${aws_security_group.alb_sg.id}",
    "${module.ecs_cluster.cluster_access_security_group_id}",
  ]
  alb_internal = true

  alb_stickiness_map = {
    type    = "lb_cookie"
    enabled = false
  }
  config_map = "${module.service_config.config_map}"
}

module "hub-frontend" {
  source            = "../web-service"
  name              = "hub-frontend-${var.name}"
  target_group_port = "80"
  image_repo_url    = "${var.ecr_hub-frontend_uri}"

  security_groups = [
    "${var.vpc_http_s_access_sg_id}",
    "${module.ecs_cluster.cluster_access_security_group_id}",
  ]

  alb_stickiness_map = {
    type            = "lb_cookie"
    cookie_duration = 28800
    enabled         = true
  }

  environment_variables = <<EOF
[
  { "name": "DNS_SERVER", "value": "8.8.8.8" }
]
EOF

  config_map = "${module.service_config.config_map}"
}

resource "aws_alb_listener" "https_listener" {
  load_balancer_arn = "${module.hub-frontend.alb_arn}"
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = "${var.ssl_certificate_arn}"

  default_action {
    target_group_arn = "${module.hub-frontend.alb_target_group_arn}"
    type             = "forward"
  }

  lifecycle {
    create_before_destroy = true
  }
}
