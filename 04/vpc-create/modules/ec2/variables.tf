variable "instance_type" {
  default = "t3.micro"
}


variable "subnet_id" {
    description = "VPC_Subnet_ID"
    type = string
}

variable "ec2_tags" {
  default = {
    Name = "example"
  }
}