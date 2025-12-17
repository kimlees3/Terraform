################################################
# 1. S3 버킷 생성 
# 2. DynamoDB 테이블 생성
################################################

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket

resource "aws_s3_bucket" "my_tfstate" {
  bucket = "kyh-9171"

  tags = {
    Name        = "kyh-9171"
  }
}


# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table

resource "aws_dynamodb_table" "my_tflocks" {
  name           = "my_tflocks"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"


  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "my_tflocks"
  }
}