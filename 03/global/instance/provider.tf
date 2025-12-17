terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.26.0"
    }
  }

  backend "s3" {
  bucket = "kyh-9171"
  key    = "global/s3/terraform.tfstate"
  region = "us-east-2"
  dynamodb_table = "my_tflocks"
  }
}

provider "aws" {
  region = "us-east-2"
}