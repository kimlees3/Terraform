provider "aws" {
    region = var.aws_region
}

module "my_vpc" {
  source = "../modules/vpc"

}

module "my_ec2" {
  source = "../modules/ec2"

  subnet_id = module.my_vpc.subnet_id
}


