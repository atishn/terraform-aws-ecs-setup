terraform {
  backend "s3" {
    bucket = "workshop-terraform"
    key    = "deploy/terraform.tfstate"
    region = "us-east-1"

    dynamodb_table = "workshop-terraform-lock"
  }
}

provider "aws" {
  region = "${var.aws_region}"
}

module "vpc" {
  source      = "./vpc"
  name        = "vpc_workshop"
  staff_cidrs = "${var.staff_cidrs}"
}

module "ecr_hub-services" {
  source        = "./ecr-repo"
  ecr_repo_name = "hub-services"
}

module "ecr_hub-frontend" {
  source        = "./ecr-repo"
  ecr_repo_name = "hub-frontend"
}

variable "morning_mail_qa_bearer" {}

variable "morning_mail_prod_bearer" {}

# SSH public key used to access EC2 hosts.
resource "aws_key_pair" "ec2_keypair" {
  key_name   = "workshop-key"
  public_key = "${file("./ssh-keys/workshop-key.pub")}"
}

module "dev" {
  source = "./environment"

  name              = "dev"
  ec2_instance_type = "t2.nano"
  ec2_keyname       = "${aws_key_pair.ec2_keypair.key_name}"

  staff_cidrs             = "${var.staff_cidrs}"
  vpc_public_subnet_ids   = "${module.vpc.public_subnet_ids}"
  vpc_vpc_id              = "${module.vpc.vpc_id}"
  vpc_http_s_access_sg_id = "${module.vpc.http_s_access_sg_id}"
  ssl_certificate_arn     = "arn:aws:acm:us-east-1:876208251118:certificate/36c4d4ce-a442-42b4-99ca-f828f94c11bb"

  ecr_hub-services_uri = "${module.ecr_hub-services.uri}"
  ecr_hub-frontend_uri = "${module.ecr_hub-frontend.uri}"
}

module "qa" {
  source = "./environment"

  name              = "qa"
  ec2_instance_type = "t2.small"
  ec2_keyname       = "${aws_key_pair.ec2_keypair.key_name}"

  staff_cidrs             = "${var.staff_cidrs}"
  vpc_public_subnet_ids   = "${module.vpc.public_subnet_ids}"
  vpc_vpc_id              = "${module.vpc.vpc_id}"
  vpc_http_s_access_sg_id = "${module.vpc.http_s_access_sg_id}"
  ssl_certificate_arn     = "arn:aws:acm:us-east-1:876208251118:certificate/466c3295-a409-45d9-85e3-726af4e0f3bd"

  ecr_hub-services_uri = "${module.ecr_hub-services.uri}"
  ecr_hub-frontend_uri = "${module.ecr_hub-frontend.uri}"
}

module "staging" {
  source = "./environment"

  name              = "staging"
  ec2_instance_type = "t2.medium"
  ec2_keyname       = "${aws_key_pair.ec2_keypair.key_name}"

  staff_cidrs             = "${var.staff_cidrs}"
  vpc_public_subnet_ids   = "${module.vpc.public_subnet_ids}"
  vpc_vpc_id              = "${module.vpc.vpc_id}"
  vpc_http_s_access_sg_id = "${module.vpc.http_s_access_sg_id}"
  ssl_certificate_arn     = "arn:aws:acm:us-east-1:876208251118:certificate/aafe3f16-5f95-4c41-884b-997097e7a7d7"

  ecr_hub-services_uri = "${module.ecr_hub-services.uri}"
  ecr_hub-frontend_uri = "${module.ecr_hub-frontend.uri}"
}

module "prod" {
  source = "./environment"

  name              = "prod"
  ec2_instance_type = "t2.medium"
  ec2_keyname       = "${aws_key_pair.ec2_keypair.key_name}"

  staff_cidrs             = "${var.staff_cidrs}"
  vpc_public_subnet_ids   = "${module.vpc.public_subnet_ids}"
  vpc_vpc_id              = "${module.vpc.vpc_id}"
  vpc_http_s_access_sg_id = "${module.vpc.http_s_access_sg_id}"
  ssl_certificate_arn     = "arn:aws:acm:us-east-1:876208251118:certificate/f1d03cf1-a5a0-4275-bb08-1b0376f0d2fb"

  ecr_hub-services_uri = "${module.ecr_hub-services.uri}"
  ecr_hub-frontend_uri = "${module.ecr_hub-frontend.uri}"
}
