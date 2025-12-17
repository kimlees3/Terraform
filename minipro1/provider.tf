terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# aws configure list 출력 결과로 확인한다.
provider "aws" {
  region                   = "us-east-2"
  profile = "myAWS"
}