variable "aws_region" {
  default = "us-east-1"
}

variable "staff_cidrs" {
  description = "List of networks from which staff will access the AWS resources."

  default = [
    "0.0.0.0/0"
  ]
}
