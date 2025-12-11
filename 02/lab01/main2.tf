################################################################
# 1. SG 생성
# 2. EC2 생성 
################################################################

# 1. SG 생성 
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group

resource "aws_security_group" "mySG" {
  name        = "mySG"
  description = "Allow TLS inbound traffic 80/tpc, 443/tcp  and all outbound traffic"
  vpc_id      = aws_vpc.myVPC.id

  tags = {
    Name = "mySG"
  }
}

# 인그레스 룰 80/tcp 생성
resource "aws_vpc_security_group_ingress_rule" "mySG_80" {
  security_group_id = aws_security_group.mySG.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80
}

# 인그레스 룰 22/tcp 생성
resource "aws_vpc_security_group_ingress_rule" "mySG_22" {
  security_group_id = aws_security_group.mySG.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}

# 이그레스 룰 생성
resource "aws_vpc_security_group_egress_rule" "mySG_egress" {
  security_group_id = aws_security_group.mySG.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

}
# 인그레스 룰 443/tcp 생성
resource "aws_vpc_security_group_ingress_rule" "mySG_443" {
  security_group_id = aws_security_group.mySG.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  ip_protocol = "tcp"
  to_port     = 443
}
# 키페어 생성 
# EC2 생성 
# Public Subnet에 연결 
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance

# ssh-keygen -t rsa -N "" -f ~/.ssh/mykeypair
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair#key_type-1
# https://developer.hashicorp.com/terraform/language/functions/file
resource "aws_key_pair" "mykeypair" {
  key_name   = "mykeypair"
  public_key = file("~/.ssh/mykeypair.pub")
}


resource "aws_instance" "myEC2" {
  ami                         = "ami-00e428798e77d38d9"
  instance_type               = "t3.micro"
  vpc_security_group_ids      = [aws_security_group.mySG.id]
  user_data_replace_on_change = true
  subnet_id                   = aws_subnet.myPubSN.id
  key_name                    = "mykeypair"
  user_data                   = <<EOF
#!/bin/bash
dnf -y install httpd mod_ssl
echo "MyWEB" > /var/www/html/index.html
systemctl enable --now httpd
EOF

  tags = {
    Name = "myEC2"
  }
}