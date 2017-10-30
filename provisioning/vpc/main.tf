variable "staff_cidrs" {
  description = "List of strings describing allowed staff networks."
  type        = "list"
}

variable "name" {}

output "vpc_id" {
  value = "${aws_vpc.main.id}"
}

output "public_subnet_ids" {
  value = "${aws_subnet.public.*.id}"
}

output "http_s_access_sg_id" {
  value = "${aws_security_group.http_s_access.id}"
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    Name = "${var.name}"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "${var.name} Internet gateway"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.internet_gateway.id}"
  }

  tags {
    Name = "${var.name} public route table"
  }
}

resource "aws_default_route_table" "default_route_table" {
  default_route_table_id = "${aws_vpc.main.default_route_table_id}"

  tags {
    Name = "${var.name} default route table"
  }
}

resource "aws_security_group" "staff_access" {
  name        = "staff_access"
  description = "Permits all access to resources from staff networks."

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.staff_cidrs}"]
  }

  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "${var.name} staff_access"
  }
}

resource "aws_security_group" "http_s_access" {
  name        = "http_s_access"
  description = "Permits open HTTP/S access to resources."

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "${var.name} http_s_access"
  }
}

### Public subnets
variable "public_subnet_cidr_blocks" {
  type    = "list"
  default = ["10.10.0.0/24", "10.10.1.0/24"]
}

resource "aws_subnet" "public" {
  count                   = "${length(var.public_subnet_cidr_blocks)}"
  cidr_block              = "${element(var.public_subnet_cidr_blocks, count.index)}"
  availability_zone       = "${element(data.aws_availability_zones.available.names, count.index)}"
  vpc_id                  = "${aws_vpc.main.id}"
  map_public_ip_on_launch = true

  tags {
    Name = "${var.name} ${element(data.aws_availability_zones.available.names, count.index)} public subnet"
  }
}

resource "aws_route_table_association" "public_rtb_assoc" {
  count          = "${length(var.public_subnet_cidr_blocks)}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public_route_table.id}"
}

resource "aws_eip" "nat_gateway_eip" {
  vpc = true
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = "${aws_eip.nat_gateway_eip.id}"
  subnet_id     = "${element(aws_subnet.public.*.id, 0)}"
}

resource "aws_route_table" "nat_gateway_route_table" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.nat_gateway.id}"
  }

  tags {
    Name = "${var.name} NAT gateway route table"
  }
}
