# [출력변수]
output "public_ip" {
    description = "Public IP of My-First-Instance"
    value = aws_instance.myinstance.public_ip
}

output "public_dns" {
    description = "Public DNS of My-First-Instance"
    value = aws_instance.myinstance.public_dns
}