terraform {
  backend "s3" {
    bucket = "workshop-terraform"
    key    = "init/terraform.tfstate"
    region = "us-east-1"

    dynamodb_table = "workshop-terraform-lock"
  }
}

provider "aws" {
  region = "us-east-1"
}
