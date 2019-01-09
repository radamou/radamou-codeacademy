
variable "aws_access_key" {
  description = "aws acces key"
  default = "AKIAIX2UVKLEVENCBUKA"
}

variable "aws_secret_key" {
  description = "aws secret key"
  default = "IeCKaNSD71vKqbBq+oL2yGJLboGkrJW7NQ7FiELi"
}

variable "server_port" {
  default=8080
}

variable "protocol" {
  default="tcp"
}

variable "http_port" {
  default=80
}

