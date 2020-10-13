variable "profile" {
  description = "AWS User account Profile"
  default     = "ralali-dev"
}

variable "region" {
  default = "ap-southeast-2"
}

variable "aws_credentials" {
  description = "aws credentials"
  default     = "./.aws/credentials"
}

# variable "access_key" {
#   description = "aws access key"
# }

# variable "secret_key" {
#   description = "aws secret key"
# }
