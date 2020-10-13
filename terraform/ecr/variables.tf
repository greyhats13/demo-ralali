variable "ecr_name" {
  type = list(string)
  default = [
    "go-demo"
  ]
  description = "Name of the ECR"
}

variable "image_tag" {
  type        = string
  default     = "MUTABLE"
  description = "Tag of the images"
}
