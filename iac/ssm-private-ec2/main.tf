terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "ap-northeast-2"
}

resource "aws_vpc" "private_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "private_vpc"
  }
}

resource "aws_subnet" "private_subnet_apne2a" {
  vpc_id            = aws_vpc.private_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "private_subnet_apne2a"
  }
}

resource "aws_subnet" "private_subnet_apne2c" {
  vpc_id            = aws_vpc.private_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "private_subnet_apne2c"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.private_vpc.id

  tags = {
    Name = "private_route_table"
  }
}

resource "aws_main_route_table_association" "private_route_table_association" {
  vpc_id         = aws_vpc.private_vpc.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.private_subnet_apne2a.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "c" {
  subnet_id      = aws_subnet.private_subnet_apne2c.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_security_group" "allow_https" {
  name        = "allow_https"
  description = "Allow https inbound traffic"
  vpc_id      = aws_vpc.private_vpc.id

  ingress {
    description      = "https from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.private_vpc.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_https"
  }
}

resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  })
}

data "aws_iam_policy" "amazon_ssm_managed_instance_core" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2_role_policy_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = data.aws_iam_policy.amazon_ssm_managed_instance_core.arn
}

# https://skundunotes.com/2021/11/16/attach-iam-role-to-aws-ec2-instance-using-terraform/
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "app_server" {
  ami           = "ami-01711d925a1e4cc3a"
  instance_type = "t2.micro"
  
  vpc_security_group_ids = [ aws_security_group.allow_https.id ]
  subnet_id              = aws_subnet.private_subnet_apne2a.id

  iam_instance_profile =  aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "app_server"
  }
}

# https://dev.classmethod.jp/articles/access-private-ec2-with-session-manager/
# VPC 생성
# 서브넷 생성
# 라우팅 테이블 생성
# EC2 인스턴스 생성
# SSM Role 생성

# TODO 
# 엔드포인트 생성
# Session Manager로 Private EC2 인스턴스에 접속


