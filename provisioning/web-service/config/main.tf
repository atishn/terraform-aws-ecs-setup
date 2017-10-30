variable "vpc_id" {}

variable "public_subnet_ids" {
  type = "list"
}

variable "ecs_cluster_arn" {}

variable "ecs_service_role_arn" {}

output "config_map" {
  value = {
    vpc_id               = "${var.vpc_id}"
    public_subnet_ids    = "${join(",", var.public_subnet_ids)}"
    ecs_cluster_arn      = "${var.ecs_cluster_arn}"
    ecs_service_role_arn = "${var.ecs_service_role_arn}"
  }
}
