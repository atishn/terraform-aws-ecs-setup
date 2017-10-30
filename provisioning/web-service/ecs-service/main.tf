variable "alb_target_group_arn" {}

variable "ecs_cluster_arn" {}

variable "ecs_service_role_arn" {}

variable "image_repo_url" {}

variable "container_name" {}

variable "container_port" {}

variable "environment_variables" {}

variable "service_name" {}

variable "taskdef_family" {}

variable "service_log_group_name" {
  description = "Name of CloudWatch log group that will receive log events."
  default     = "logs"
}

resource "aws_ecs_task_definition" "taskdef" {
  family = "${var.taskdef_family}"

  container_definitions = <<EOF
[
  {
    "name": "${var.container_name}",
    "image": "${var.image_repo_url}",
    "cpu": 0,
    "memory": 128,
    "essential": true,
    "portMappings": [
      {
        "containerPort": ${var.container_port}
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.logs.name}",
        "awslogs-region": "us-east-1"
      }
    },
    "environment": ${var.environment_variables}
  }
]
EOF

  lifecycle {
    ignore_changes = ["container_definitions"]
  }
}

resource "aws_ecs_service" "service" {
  name            = "${var.service_name}"
  cluster         = "${var.ecs_cluster_arn}"
  task_definition = "${aws_ecs_task_definition.taskdef.arn}"
  desired_count   = "2"
  iam_role        = "${var.ecs_service_role_arn}"

  load_balancer {
    target_group_arn = "${var.alb_target_group_arn}"
    container_name   = "${var.service_name}"
    container_port   = "${var.container_port}"
  }

  lifecycle {
    ignore_changes = ["*"]
  }
}

resource "aws_cloudwatch_log_group" "logs" {
  name = "${var.service_log_group_name}"
}
