output "registry_id" {
  value = [aws_ecr_repository.ecr-demo.*.registry_id]
}

output "registry_name" {
  value = [aws_ecr_repository.ecr-demo.*.name]
}
