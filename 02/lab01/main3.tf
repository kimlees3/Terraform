###################################################################
# 1. NAT Gateway 생성 -> Public Subnet에 연결
# 2. Private Subnet 생성
# 3. Private Routing Table 생성 및 연결 
# 4. SG 그룹 생성 
# 5. EC2 인스턴스 생성
###################################################################

# 1. NAT Gateway 생성 -> Public Subnet에 연결 
# * EIP 생성된 상태에서 작업
# * NAT Gateway를 PubSN에 생성

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip
resource "aws_eip" "myEIP" {
  domain = "vpc"
  tags = {
    Name = "myEIP"
  }

}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway
resource "aws_nat_gateway" "myNAT-GW" {
  allocation_id = aws_eip.myEIP.id
  subnet_id     = aws_subnet.myPubSN.id

  tags = {
    Name = "myNAT-GW"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.myIGW]
}

# 2. Private Subnet 생성
resource "aws_subnet" "myPriSN" {
  vpc_id     = aws_vpc.myVPC.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "myPriSN"
  }
}

# 3. Private Routing Table 생성 및 연결 
resource "aws_route_table" "myPriSN-RT" {
  vpc_id = aws_vpc.myVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.myNAT-GW.id
  }

  tags = {
    Name = "myPriSN-RT"
  }
}
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
resource "aws_route_table_association" "myPriSN-RT-AS" {
  subnet_id      = aws_subnet.myPriSN.id
  route_table_id = aws_route_table.myPriSN-RT.id
}

# 4. SG 그룹 생성 
# * myEC2-2가 사용할 SG 
# * - 22/tcp, 80/tcp, 443/tcp

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "mySG2" {
  name        = "mySG2"
  description = "Allow TLS inbound 22/TCP, 80/TCP, 443/TCP traffic and all outbound traffic"
  vpc_id      = aws_vpc.myVPC.id

  tags = {
    Name = "mySG2"
  }
}

resource "aws_vpc_security_group_ingress_rule" "mySG2_22" {
  security_group_id = aws_security_group.mySG2.id
  cidr_ipv4         = aws_vpc.myVPC.cidr_block
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "mySG2_80" {
  security_group_id = aws_security_group.mySG2.id
  cidr_ipv4         = aws_vpc.myVPC.cidr_block
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "mySG2_443" {
  security_group_id = aws_security_group.mySG2.id
  cidr_ipv4         = aws_vpc.myVPC.cidr_block
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}
resource "aws_vpc_security_group_egress_rule" "mySG2_egress" {
  security_group_id = aws_security_group.mySG2.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# 5. EC2 인스턴스 생성
# * mySG2를 사용
# * myPriSN에 연결
# * user_data(WEB Server, SSH Server)
#   - user_data가 변경되었을떄 EC2를 재 생성하도록 설정
# * mykeypair EC2 인스턴스에 연결   



# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
resource "aws_instance" "myEC2-2" {
  ami                         = "ami-00e428798e77d38d9"
  instance_type               = "t3.micro"
  vpc_security_group_ids      = [aws_security_group.mySG2.id]
  subnet_id                   = aws_subnet.myPriSN.id
  key_name                    = "mykeypair"
  user_data_replace_on_change = true
  user_data                   = <<EOF
#!/bin/bash
dnf -y install httpd mod_ssl
echo "MyWEB Server2" > /var/www/html/index.html
systemctl enable --now httpd
EOF

  tags = {
    Name = "myEC2-2"
  }
}

