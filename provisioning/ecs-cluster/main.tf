variable "name" {}

variable "vpc_id" {}

variable "admin_cidrs" {
  type = "list"
}

variable "keypair_name" {}

variable "subnet_ids" {
  type = "list"
}

variable "instance_type" {}

variable "log_level" {
  description = "Logging level for CloudWatch logs.  [crit | error | warn | info | debug]."
  default     = "debug"
}

output "service_role_arn" {
  value = "${aws_iam_role.ecs_service_role.arn}"
}

output "cluster_arn" {
  value = "${aws_ecs_cluster.main.id}"
}

output "cluster_access_security_group_id" {
  value = "${aws_security_group.cluster_access.id}"
}

output "ecs_instance_security_group_id" {
  value = "${aws_security_group.ecs_instance_sg.id}"
}

data "aws_ami" "amazon_ecs_optimized" {
  most_recent = true

  filter {
    name   = "description"
    values = ["Amazon Linux AMI * ECS * GP2"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["591542846629"] # Amazon
}

resource "aws_ecs_cluster" "main" {
  name = "${var.name}"
}

resource "aws_security_group" "cluster_access" {
  name   = "${var.name}-cluster_access"
  vpc_id = "${var.vpc_id}"
}

resource "aws_security_group" "ecs_instance_sg" {
  description = "Controls access to ECS instances"
  vpc_id      = "${var.vpc_id}"
  name        = "${var.name}-ecs-instance-sg"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.admin_cidrs}"]
  }

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = ["${aws_security_group.cluster_access.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Support IAM support objects: policies, roles, EC2 instance profile

# Define an IAM role to allow the AWS ECS API to access this account's resources.
resource "aws_iam_role" "ecs_service_role" {
  name               = "${var.name}-ecs-service-role"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_service_role_policy.json}"
}

data "aws_iam_policy_document" "ecs_service_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Define the IAM permissions required by the AWS ECS API to act upon this account.
resource "aws_iam_role_policy_attachment" "ecs_service_role_permissions" {
  role       = "${aws_iam_role.ecs_service_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

# Define an IAM role to allow the AWS EC2 API to access this account's resources.
resource "aws_iam_role" "ecs_ec2_service_role" {
  name               = "${var.name}-ecs-ec2-service-role"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_ec2_service_role_policy.json}"
}

data "aws_iam_policy_document" "ecs_ec2_service_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Define the IAM permissions required by the AWS EC2 API to act upon this account.
resource "aws_iam_role_policy_attachment" "ecs_ec2_service_role_permissions" {
  role       = "${aws_iam_role.ecs_ec2_service_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# This policy permits EC2 instances to create log groups/streams and to
# write events to CloudWatch Logs.
resource "aws_iam_role_policy" "ecs_ec2_cloudwatchlogs_access" {
  name = "${var.name}-ecs-ec2-cloudwatchlogs-access"
  role = "${aws_iam_role.ecs_ec2_service_role.name}"

  policy = <<EOF
{
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    }
  ]
}
EOF
}

# Create an EC2 instance profile so EC2 instances can be used with ECS.
resource "aws_iam_instance_profile" "ecs_ec2_instance_profile" {
  name = "${var.name}-ecs-ec2-instance-profile"
  role = "${aws_iam_role.ecs_ec2_service_role.name}"
}

# EC2 resources that will support this ECS cluster

# The EC2 launch configuration.

resource "aws_launch_configuration" "lc" {
  name_prefix          = "${var.name}-ecs-lc-"
  key_name             = "${var.keypair_name}"
  image_id             = "${data.aws_ami.amazon_ecs_optimized.id}"
  instance_type        = "${var.instance_type}"
  iam_instance_profile = "${aws_iam_instance_profile.ecs_ec2_instance_profile.name}"

  security_groups = [
    "${aws_security_group.ecs_instance_sg.id}",
  ]

  user_data = <<DEFINITION
#!/bin/bash
cat <<'EOF' >> /etc/ecs/ecs.config
ECS_CLUSTER=${var.name}
ECS_LOGLEVEL=${var.log_level}
EOF
DEFINITION

  associate_public_ip_address = "true"

  root_block_device {
    volume_type = "gp2"
    volume_size = "50"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# The EC2 auto-scaling group
resource "aws_autoscaling_group" "asg" {
  name                      = "${var.name}-ecs-asg"
  vpc_zone_identifier       = ["${var.subnet_ids}"]
  min_size                  = "0"
  max_size                  = "4"
  desired_capacity          = "2"
  launch_configuration      = "${aws_launch_configuration.lc.name}"
  health_check_grace_period = 0
}
