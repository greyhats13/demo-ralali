variable "vpc_id" {
  description = "VPC ID for node"
}

variable "public_subnet" {
  type        = list(string)
  description = "public subnet"
}

variable "nodes_subnet" {
  type        = list(string)
  description = "nodes subnet"
}
