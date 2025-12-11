###############################################
# 1. provider 설정                                            
# 2. vpc 생성                                          
# 3. IGW 생성 및 연결
# 4. Public Subnet 생성 및 연결
# 5. Private Subnet 생성 및 연결                                     
###############################################

# 1. provider 설정

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.26.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

# vpc 생성
# * dns 호스트 이름 활성화 
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc#enable_dns_hostnames-1

resource "aws_vpc" "myVPC" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "myVPC"
  }
}

# IGW 생성
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway
resource "aws_internet_gateway" "myIGW" {
  vpc_id = aws_vpc.myVPC.id

  tags = {
    Name = "myIGW"
  }
}

# 4. Public Subnet 생성 및 연결
# * 공인 IP 활성화 : map_public_ip_on_launch = true
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet

resource "aws_subnet" "myPubSN" {
  vpc_id     = aws_vpc.myVPC.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "myPubSN"
  }
}

# 5. PubSN-RT 생성 및 연결
# * default route 
# * myPubSN 에 연결
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
resource "aws_route_table" "myPubSN-RT" {
  vpc_id = aws_vpc.myVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myIGW.id
  }

  tags = {
    Name = "myPubSN-RT"
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
resource "aws_route_table_association" "myPubSN-RT-Association" {
  subnet_id      = aws_subnet.myPubSN.id
  route_table_id = aws_route_table.myPubSN-RT.id
}

