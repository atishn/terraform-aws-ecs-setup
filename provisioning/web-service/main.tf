variable "name" {}

variable "target_group_port" {}

variable "config_map" {
  type = "map"
}

variable "image_repo_url" {}

variable "environment_variables" {
  default = "[]"
}

variable "alb_stickiness_map" {
  type = "map"
}

variable "alb_internal" {
  type    = "string"
  default = false
}

variable "security_groups" {
  type = "list"
}

output "alb_arn" {
  value = "${module.alb.alb_arn}"
}

output "alb_dns_name" {
  value = "${module.alb.alb_dns_name}"
}

output "alb_target_group_arn" {
  value = "${module.alb.alb_target_group_arn}"
}

module "alb" {
  source                       = "./alb"
  alb_name                     = "${var.name}"
  alb_vpc_id                   = "${lookup(var.config_map, "vpc_id")}"
  alb_subnet_ids               = "${split(",", lookup(var.config_map, "public_subnet_ids"))}"
  alb_target_group_name        = "tg-${var.name}"
  alb_target_group_port        = "${var.target_group_port}"
  alb_target_group_stickiness  = "${var.alb_stickiness_map}"
  alb_assigned_security_groups = "${var.security_groups}"
  internal                     = "${var.alb_internal}"
}

module "ecs-service" {
  source                 = "./ecs-service"
  alb_target_group_arn   = "${module.alb.alb_target_group_arn}"
  ecs_cluster_arn        = "${lookup(var.config_map, "ecs_cluster_arn")}"
  ecs_service_role_arn   = "${lookup(var.config_map, "ecs_service_role_arn")}"
  image_repo_url         = "${var.image_repo_url}"
  container_name         = "${var.name}"
  container_port         = "${var.target_group_port}"
  environment_variables  = "${var.environment_variables}"
  service_log_group_name = "${var.name}/logs"
  service_name           = "${var.name}"
  taskdef_family         = "${var.name}"
}
