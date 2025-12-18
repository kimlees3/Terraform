######################################################
# 1. provider 설정
# 2. DB(MySQL) 생성
######################################################

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.26.0"
    }
  }
  backend "s3" {
    bucket       = "mykyh-9171"
    key          = "global/s3/terraform.tfstate"
    region       = "us-east-2"
    use_lockfile = true
  }
}

provider "aws" {
  region = "us-east-2"
}


######################################################
# 2. DB(MySQL) 생성
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance
# * username/password 
# * DB name 
resource "aws_db_instance" "default" {
  allocated_storage = 10
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "${var.dbuser}"
  password             = "${var.dbpassword}"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
}