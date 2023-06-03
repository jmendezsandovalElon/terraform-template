
provider "aws" {
  region = var.region
}

data "aws_ssm_parameter" "instance_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

data "aws_region" "current" {}

resource "aws_vpc" "terraform_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = "true"
  enable_dns_support   = "true"
  instance_tenancy     = "default"

  tags = {
    Name = "terraform_vpc"
  }
}

resource "aws_internet_gateway" "terraform_igw" {
  vpc_id = aws_vpc.terraform_vpc.id

  tags = {
    Name = "terraform_igw"
  }
}

resource "aws_subnet" "terraform_subnet_public" {
  vpc_id                  = aws_vpc.terraform_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "us-west-1b"

  tags = {
    Name = "Terraform_public_subnet"
  }
}

resource "aws_subnet" "terraform_subnet_private" {
  vpc_id                  = aws_vpc.terraform_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = "false"
  availability_zone       = "us-west-1c"

  tags = {
    Name = "Terraform_public_private"
  }
}

resource "aws_route_table" "terraform_public_routetable" {
  vpc_id = aws_vpc.terraform_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform_igw.id
  }
}

resource "aws_route_table_association" "terraform_rt_public_ass" {
  subnet_id      = aws_subnet.terraform_subnet_public.id
  route_table_id = aws_route_table.terraform_public_routetable.id
}

resource "aws_security_group" "terraform_sg" {
  name        = "terraform_sg"
  description = "allow incoming traffic"
  vpc_id      = aws_vpc.terraform_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    name = "terraform_sg"
  }
}

resource "aws_instance" "terraform_ec2" {
  instance_type   = var.instance_type
  ami             = data.aws_ssm_parameter.instance_ami.value
  key_name        = var.key_name
  security_groups = [aws_security_group.terraform_sg.id]
  user_data       = file("install_apache.sh")
  subnet_id       = aws_subnet.terraform_subnet_public.id
  count = 2
}

