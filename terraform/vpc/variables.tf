variable "profile" {
  description = "AWS User account Profile"
  default     = "staging"
}

variable "region" {
  default = "ap-southeast-2"
}

variable "vpc-cidr-block" {
  default = "10.43.192.128/25"
}

variable "nodes_subnet_cidr" {
  default = ["10.43.192.128/28", "10.43.192.144/28", "10.43.192.160/28"]
}

variable "public_subnet_cidr" {
  default = ["10.43.192.176/28", "10.43.192.192/28", "10.43.192.208/28"]
}

variable "vpc_name" {
  description = "VPC name"
  default     = "Demo-VPC"
}
