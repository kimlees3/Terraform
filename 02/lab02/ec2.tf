###############################
# 1. provider
# 2. EC2
# - SG 생성
# - EC2(keypair)
###############################

###############################
# 1. provider
###############################
provider "aws" {
  region = "us-east-2"
}

###############################
# 2. EC2
###############################

data "aws_vpc" "default" {
  default = true
}


# SG 생성
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "mysg" {
  name        = "mysg"
  description = "Allow TLS inbound SSH traffic and all outbound traffic"
  vpc_id      = data.aws_vpc.default.id # <--

  tags = {
    Name = "mysg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.mysg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.mysg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# 키페어 생성
resource "aws_key_pair" "mykeypair" {
  key_name   = "mykeypair"
  public_key = file("~/.ssh/mykeypair.pub")

}

# EC2 생성
# * AMI ID 자동 선택하도록 data source를 사용
#   - Amazon linux 2023 ami
data "aws_ami" "amazon2023" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023.9.*-kernel-6.1-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] 
}

resource "aws_instance" "myInstance" {
  ami           = data.aws_ami.amazon2023.id
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.mysg.id]
  key_name = "mykeypair"

  tags = {
    Name = "myInstance"
  }
}

output "ami_id" {
  description = "AMI ID"
  value = aws_instance.myInstance.ami
}

output "myInstanceIP" {
  description = "EC2 Instance public IP"
  value = aws_instance.myInstance.public_ip
}

output "connectSSH" {
  description = "Connect URI"
  value = "ssh -i ~/.ssh/mykeypair ec2-user@${aws_instance.myInstance.public_ip}"
}

