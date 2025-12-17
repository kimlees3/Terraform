

resource "aws_instance" "myEC2" {
  ami           = "ami-0f5fcdfbd140e4ab7"
  instance_type = "t3.micro"

  tags = {
    Name = "myEC2"
  }
}

