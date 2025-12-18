############################################
# 1. provider 설정
# 2. S3 버킷 생성
############################################
provider "aws" {
  region = "us-east-2"
}

# S3 버킷 생성
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket

resource "aws_s3_bucket" "mytfstate" {
  bucket = "mykyh-9171"

  tags = {
    Name        = "mytfstate"
  }
}

