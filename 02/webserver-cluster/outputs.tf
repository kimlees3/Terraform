output "myalb_dnsname" {
  description = "My ALB DNS URL"
  value = aws_lb.myalb.dns_name

}

output "myalb_url" {
  description = "My ALB URL"
  value = "http://${aws_lb.myalb.dns_name}"
}