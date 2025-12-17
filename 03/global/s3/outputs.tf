output "mybucket_arn" {
  value = aws_s3_bucket.my_tfstate.arn
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.my_tflocks.name 
}