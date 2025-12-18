variable "dbuser" {
  description = "DB username(ex: dbuser)"
  type = string
  sensitive = true 
}

variable "dbpassword" {
  description = "DB password(ex: dbpassword)"
  type = string
  sensitive = true 
}