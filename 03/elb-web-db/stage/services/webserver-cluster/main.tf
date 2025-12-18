

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.26.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

data "terraform_remote_state" "myremotestate" {
  backend = "s3"
  config = {
    bucket = "mykyh-9171"
    key    = "global/s3/terraform.tfstate"
    region = "us-east-2"
    use_lockfile = true 
    encrypt        = true

  }
}

####################################################
# 2. ASG
####################################################
# * default vpc
# * default subnets
# * SG
# * launch template
# * TG 
# * ASG


# * default vpc
data "aws_vpc" "default" {
  default = true
}

# * default subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# * SG - LT에서 사용할 SG
# * 80/tcp 

resource "aws_security_group" "myLTSG" {
  name        = "myLTSG"
  description = "Allow HTTP inbound traffic and all outbound traffic"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "myLTSG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "myLTSG-IN-80" {
  security_group_id = aws_security_group.myLTSG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "myLTSG-OUT-ALL" {
  security_group_id = aws_security_group.myLTSG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# * launch template
#   - aws_ami data source

data "aws_ami" "amazon2023" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023.9.*.0-kernel-6.1-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] 
}

resource "aws_launch_template" "myLT" {
  name = "myLT"
  image_id = data.aws_ami.amazon2023.id
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.myLTSG.id]

 user_data = base64encode(templatefile("${path.module}/user_data.sh", {
  dbaddress = data.terraform_remote_state.myremotestate.outputs.dbaddress
  dbport    = data.terraform_remote_state.myremotestate.outputs.dbport
  dbname    = data.terraform_remote_state.myremotestate.outputs.dbname
}))

}

# * TG 생성 

resource "aws_lb_target_group" "myALBTG" {
  name     = "myALBTG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
}

# ASG 
# * target_group_arns
# * depends_on

resource "aws_autoscaling_group" "myASG" {
  name                      = "myASG"
  desired_capacity          = 2
  max_size                  = 2
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  target_group_arns         = [aws_lb_target_group.myALBTG.arn]
  depends_on                = [aws_lb_target_group.myALBTG]
  force_delete              = true
  launch_template {
    id      = aws_launch_template.myLT.id
    version = "$Latest"
  }
  vpc_zone_identifier       = data.aws_subnets.default.ids


  tag {
    key                 = "Name"
    value               = "myASG"
    propagate_at_launch = false
  }
}

# * ALB 생성

# * SG - ALB를 위한 SG

resource "aws_security_group" "myALBSG" {
  name        = "myALBSG"
  description = "Allow HTTP inbound traffic and all outbound traffic"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "myALBSG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "myALBSG-IN-80" {
  security_group_id = aws_security_group.myALBSG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "myALBSG-OUT-ALL" {
  security_group_id = aws_security_group.myALBSG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# * ALB 생성

resource "aws_lb" "myALB" {
  name               = "myALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.myALBSG.id]
  subnets            = data.aws_subnets.default.ids

}

resource "aws_lb_listener" "myALBListener" {
  load_balancer_arn = aws_lb.myALB.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.myALBTG.arn
  }
}

# LB Listener Rule 


resource "aws_lb_listener_rule" "myALB-listener-rule" {
  listener_arn = aws_lb_listener.myALBListener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.myALBTG.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}


