resource "aws_ecr_repository" "ecr-demo" {
  count                = length(var.ecr_name)
  name                 = element(var.ecr_name, count.index)
  image_tag_mutability = var.image_tag
}

resource "aws_ecr_lifecycle_policy" "ecr-policy-demo" {
  count      = length(aws_ecr_repository.ecr-demo)
  repository = element(aws_ecr_repository.ecr-demo.*.name, count.index)

  policy = <<EOF
{
  "rules": [
    {
      "action": {
        "type": "expire"
      },
      "selection": {
        "countType": "imageCountMoreThan",
        "countNumber": 5,
        "tagStatus": "any"
      },
      "description": "remove image more than 5",
      "rulePriority": 1
    }
  ]
}
EOF
}
