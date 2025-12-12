#################################################
# 1. provider 
# 2. EC2 인스턴스 생성
#################################################

# 1. provider 설정

provider "aws" {
  region = "us-east-2"
}

# EC2 생성 
# * AMI ID 자동 선택하도록 data source 사용 
# - Amazon Linux 2023 AMI
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

  owners = ["137112412989"] # Amazon
}

resource "aws_instance" "myINSTANCE" {
  ami           = data.aws_ami.amazon2023.id
  instance_type = "t3.micro"

  tags = {
    Name = "myINSTANCE"
  }
}

output "ami_id" {
  description = "Amazon Linux 2023 AMI ID"
  value       = aws_instance.myINSTANCE.ami
}