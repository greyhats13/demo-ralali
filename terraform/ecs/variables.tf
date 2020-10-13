variable "vpc_id" {
  description = "VPC ID for node"
}

variable "public_subnet" {
  type        = list(string)
  description = "public subnet"
}

variable "vpc_zone_identifier" {
  type        = list(string)
  description = "vpc zone identifier"
}
