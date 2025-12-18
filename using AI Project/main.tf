provider "aws" {
  region = "us-east-1"
}

variable "key_name" {
  description = "Name of an existing EC2 KeyPair to enable SSH access to the instances."
  type        = string
}

data "aws_ssm_parameter" "latest_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "My-VPC"
  }
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "My-IGW"
  }
}

resource "aws_route_table" "my_public_rt" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "My-Public-RT"
  }
}

resource "aws_route" "my_default_public_route" {
  route_table_id         = aws_route_table.my_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_igw.id
}

resource "aws_subnet" "my_public_sn1" {
  vpc_id            = aws_vpc.my_vpc.id
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block        = "10.0.0.0/24"

  tags = {
    Name = "My-Public-SN-1"
  }
}

resource "aws_subnet" "my_public_sn2" {
  vpc_id            = aws_vpc.my_vpc.id
  availability_zone = data.aws_availability_zones.available.names[1]
  cidr_block        = "10.0.1.0/24"

  tags = {
    Name = "My-Public-SN-2"
  }
}

resource "aws_route_table_association" "my_public_sn_rta1" {
  subnet_id      = aws_subnet.my_public_sn1.id
  route_table_id = aws_route_table.my_public_rt.id
}

resource "aws_route_table_association" "my_public_sn_rta2" {
  subnet_id      = aws_subnet.my_public_sn2.id
  route_table_id = aws_route_table.my_public_rt.id
}

resource "aws_security_group" "websg" {
  name        = "WEBSG"
  description = "Enable HTTP access via port 80 and SSH access via port 22"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
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
    Name = "WEBSG"
  }
}

resource "aws_instance" "my_ec2_1" {
  ami                         = data.aws_ssm_parameter.latest_ami.value
  instance_type               = "t2.micro"
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.my_public_sn1.id
  vpc_security_group_ids      = [aws_security_group.websg.id]
  associate_public_ip_address = true

  tags = {
    Name = "EC2-1"
  }

  user_data = <<-EOF
    #!/bin/bash
    hostname EC2-1
    yum install httpd -y
    service httpd start
    chkconfig httpd on
    echo "<h1>CloudNet@ EC2-1 Web Server</h1>" > /var/www/html/index.html
  EOF
}

resource "aws_instance" "my_ec2_2" {
  ami                         = data.aws_ssm_parameter.latest_ami.value
  instance_type               = "t2.micro"
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.my_public_sn2.id
  vpc_security_group_ids      = [aws_security_group.websg.id]
  associate_public_ip_address = true

  tags = {
    Name = "EC2-2"
  }

  user_data = <<-EOF
    #!/bin/bash
    hostname ELB-EC2-2
    yum install httpd -y
    service httpd start
    chkconfig httpd on
    echo "<h1>CloudNet@ EC2-2 Web Server</h1>" > /var/www/html/index.html
  EOF
}

resource "aws_eip" "my_eip1" {
  domain = "vpc"
}

resource "aws_eip_association" "my_eip1_assoc" {
  instance_id   = aws_instance.my_ec2_1.id
  allocation_id = aws_eip.my_eip1.id
}

resource "aws_eip" "my_eip2" {
  domain = "vpc"
}

resource "aws_eip_association" "my_eip2_assoc" {
  instance_id   = aws_instance.my_ec2_2.id
  allocation_id = aws_eip.my_eip2.id
}

resource "aws_lb_target_group" "alb_target_group" {
  name     = "My-ALB-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id
}

resource "aws_lb_target_group_attachment" "tg_attach_1" {
  target_group_arn = aws_lb_target_group.alb_target_group.arn
  target_id        = aws_instance.my_ec2_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "tg_attach_2" {
  target_group_arn = aws_lb_target_group.alb_target_group.arn
  target_id        = aws_instance.my_ec2_2.id
  port             = 80
}

resource "aws_lb" "application_load_balancer" {
  name               = "My-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.websg.id]
  subnets            = [aws_subnet.my_public_sn1.id, aws_subnet.my_public_sn2.id]
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.application_load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }
}
