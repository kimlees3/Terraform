####################################################
# 1. ALB
# * SG 생성
# * Target Group 생성
# * ALB 생성
# * ALB Listener 생성 
# * ALB Listener Rule 생성
# 2. ASG 
# * SG 생성
# * launch template 생성
# * ASG 생성
####################################################

# 0. infra
####################################################
data "aws_vpc" "default" {
  default = true
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

####################################################
# 1. ALB
# * SG 생성
# * Target Group 생성
# * ALB 생성
# * ALB Listener 생성 
# * ALB Listener Rule 생성
####################################################
# * SG 생성
# ingress: 80/tcp egress: all

resource "aws_security_group" "myalb_sg" {
  name        = "myalb_sg"
  description = "Allow HTTP inbound traffic and all outbound traffic"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "myalb_sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_80" {
  security_group_id = aws_security_group.myalb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all" {
  security_group_id = aws_security_group.myalb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


####################################################
# * Target Group 생성

resource "aws_lb_target_group" "myalb-tg" {
  name     = "myalb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
}

####################################################
# * ALB 생성
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb
####################################################
resource "aws_lb" "myalb" {
  name               = "myalb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.myalb_sg.id]
  subnets            = data.aws_subnets.default.ids

  tags = {
    Name = "myalb"
  }
}

####################################################
# * ALB Listener 생성 
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener


resource "aws_lb_listener" "myalb_listener" {
  load_balancer_arn = aws_lb.myalb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.myalb-tg.arn
  }
}

####################################################
# * ALB Listener Rule 생성
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule

resource "aws_lb_listener_rule" "myalb_listener_rule" {
  listener_arn = aws_lb_listener.myalb_listener.arn
  priority     = 99

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.myalb-tg.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}


####################################################
# 2. ASG 
# * SG 생성
# * launch template 생성
# * ASG 생성
####################################################

# * SG 생성

resource "aws_security_group" "myasg_sg" {
  name        = "myasg_sg"
  description = "Allow HTTP inbound traffic and all outbound traffic"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "myasg_sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_80_asg" {
  security_group_id = aws_security_group.myasg_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_asg" {
  security_group_id = aws_security_group.myasg_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}



# * launch template 생성 

# * ami id
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance

data "aws_ami" "amazonelinux2023" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023.9.*.0-kernel-6.1-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Canonical
}

# * launch template 생성
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template


resource "aws_launch_template" "mylt" {
  name                   = "mylt"
  image_id               = data.aws_ami.amazonelinux2023.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.myasg_sg.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "mylt"
    }
  }

  user_data = filebase64("./user_data.sh")
}

####################################################
# * ASG 생성
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#argument-reference
####################################################
# * target_group_arns
# * depends_on

resource "aws_autoscaling_group" "myasg" {
  vpc_zone_identifier = data.aws_subnets.default.ids
  desired_capacity    = 2
  max_size            = 2
  min_size            = 2

  target_group_arns = [aws_lb_target_group.myalb-tg.arn]
  depends_on        = [aws_lb_listener.myalb_listener]
  launch_template {
    id      = aws_launch_template.mylt.id
    version = "$Latest"
  }
}