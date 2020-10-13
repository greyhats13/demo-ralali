
variable "vpc_id" {
  description = "VPC ID for node"
}

variable "instance_type" {
  default     = "t2.micro"
  description = "t2 micro for Bastion"
}

variable "instance_ami" {
  default     = "ami-0f96495a064477ffb" # AMI of Singapore Region
  description = "Instance AMI for Amazon Linux"
}

# variable "nodes_subnet" {
#   type        = list(string)
#   description = "node subnet"
# }

variable "public_subnet" {
  type        = list(string)
  description = "public subnet"
}

variable "server_name" {
  default = "Bastion host"
}
