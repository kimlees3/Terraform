########################################
# 1. 인프라 구성
# * VPC 생성
# * IGW 생성 및 연결
# * Public Subnet 생성
# * Routing Table 생성 및 연결
# 2. EC2 인스턴스 생성
# * Security Group 생성 
# * Key Pair 생성
# * EC2 인스턴스 생성
#   - User_Data(docker CMD)
#   - EC2 인스턴스에 Security Group 연결 및 Key Pair 연결
########################################

# 1. 인프라 구성
########################################
# * VPC 생성
# * DNS hostname enable
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc

resource "aws_vpc" "myVPC" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true # DNS hostname enable
  tags = {
    Name = "myVPC"
  }
}
########################################
# * IGW 생성 및 연결
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway

resource "aws_internet_gateway" "myIGW" {
  vpc_id = aws_vpc.myVPC.id

  tags = {
    Name = "myIGW"
  }
}

########################################
# * Public Subnet 생성
# * 공인 IP 할당
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet

resource "aws_subnet" "myPubSN" {
  vpc_id     = aws_vpc.myVPC.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true # 공인 IP 할당
  tags = {
    Name = "myPubSN"
  }
}
########################################
# * Routing Table 생성 및 연결
# * myIGW -> default route
# * myPubSN -> routing table 연결 
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table

resource "aws_route_table" "myPubRT" {
  vpc_id = aws_vpc.myVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myIGW.id
  }

  tags = {
    Name = "myPubRT"
  }
}
resource "aws_route_table_association" "myPubRTassoc" {
  subnet_id      = aws_subnet.myPubSN.id
  route_table_id = aws_route_table.myPubRT.id
}
########################################
# 2. EC2 인스턴스 생성
########################################
# * Security Group 생성 
#  - ingress/egress 생성
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "mySG" {
  name        = "mySG"
  description = "Allow all inbound traffic and outbound traffic"
  vpc_id      = aws_vpc.myVPC.id

  tags = {
    Name = "mySG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "mySG_in" {
  security_group_id = aws_security_group.mySG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "mySG_" {
  security_group_id = aws_security_group.mySG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
########################################
# * Key Pair 생성
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair
# * ssh-keygen -t rsa -N "" -f ~/.ssh/mykeypair
#     -> ~/.ssh/mykeypair.pub ~/.ssh/mykeypair

resource "aws_key_pair" "mykeypair" {
  key_name   = "mykeypair"
  public_key = file("~/.ssh/mykeypair.pub")
}

########################################
# * EC2 인스턴스 생성
#   - User_Data(docker CMD)
#   - EC2 인스턴스에 Security Group 연결 및 Key Pair 연결
#   - 새로 생성한 public subnet(myPubSN)에 EC2 생성
#   - key_name(mykeypair) 연결
# ami: Ubuntu 24.04 LTS
# * User_Data(docker 설치)
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] 
}

resource "aws_instance" "myEC2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id   = aws_subnet.myPubSN.id
  vpc_security_group_ids = [aws_security_group.mySG.id]
  key_name = aws_key_pair.mykeypair.key_name
  user_data_replace_on_change = true
  user_data_base64 = filebase64("user_data.sh")
  
  # https://developer.hashicorp.com/terraform/language/resources/provisioners/syntax
  provisioner "local-exec" {
  command = templatefile("make_config.sh", {
    hostname = self.public_ip,
    user = "ubuntu",
    identity_file = "~/.ssh/mykeypair"
  } )
  interpreter = [ "/bin/bash", "-c" ]
}


  tags = {
    Name = "myEC2"
  }
}
