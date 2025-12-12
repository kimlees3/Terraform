# [입력변수]

variable "security_group_name" {
    description = "Security group name for My-First-Instance"
    type = string
    default = "allow_8080"
}

variable "server_port" {
    description = "Server port for My-First-Instance"
    type = number
    default = 8080
}
