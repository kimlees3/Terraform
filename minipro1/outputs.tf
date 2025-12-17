output "myEC2IP" {
  value = aws_instance.myEC2.public_ip
}

output "myECU2URL" {
  value = "ssh -i ~/.ssh/mykeypair ubuntu@${aws_instance.myEC2.public_ip}"
}