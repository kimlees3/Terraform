output "ALB_dns_name" {
  value = aws_lb.myALB.dns_name
}

output "ALB_URL" {
  value = "http://${aws_lb.myALB.dns_name}"
}

