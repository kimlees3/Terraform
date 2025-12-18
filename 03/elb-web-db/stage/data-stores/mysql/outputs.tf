output "dbaddress" {
  value = aws_db_instance.default.address
}

output "dbport" {
  value = aws_db_instance.default.port
}

output "dbname" {
  value = aws_db_instance.default.db_name
}