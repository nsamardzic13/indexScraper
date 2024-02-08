variable "availability_zones" {
  type    = list(string)
  default = ["eu-central-1a", "eu-central-1b"]
}

resource "aws_vpc" "tf_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "public_subnet" {
  count               = 2
  vpc_id              = aws_vpc.tf_vpc.id
  cidr_block          = "10.0.${count.index + 1}.0/24"
  availability_zone   = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_subnet" {
  count               = 2
  vpc_id              = aws_vpc.tf_vpc.id
  cidr_block          = "10.0.${count.index + 3}.0/24"
  availability_zone   = element(var.availability_zones, count.index)
}

resource "aws_internet_gateway" "tf_igw" {
  vpc_id = aws_vpc.tf_vpc.id
}

resource "aws_route_table" "tf_public_route_table" {
  vpc_id = aws_vpc.tf_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tf_igw.id
  }
}

resource "aws_route_table_association" "tf_public_subnet_association" {
  count = 2

  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.tf_public_route_table.id
}

resource "aws_security_group" "tf_ecs_security_group" {
  name        = "tf-ecs-security-group"
  description = "Security group for ECS instances"
  vpc_id      = aws_vpc.tf_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_nat_gateway" "tf_nat_gateway" {
  count = 2

  allocation_id = aws_eip.tf_eip[count.index].id
  subnet_id     = aws_subnet.public_subnet[count.index].id
}

resource "aws_eip" "tf_eip" {
  count = 2
}

resource "aws_route_table" "tf_private_route_table" {
  count = 2
  vpc_id = aws_vpc.tf_vpc.id
}

resource "aws_route" "tf_nat_gateway_route" {
  count = 2

  route_table_id         = aws_route_table.tf_private_route_table[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.tf_nat_gateway[count.index].id
}

resource "aws_route_table_association" "tf_private_subnet_association" {
  count = 2

  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.tf_private_route_table[count.index].id
}