output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}

output "nodes_subnet" {
  value = [aws_subnet.nodes_subnet.*.id]
}

output "public_subnet" {
  value = [aws_subnet.public_subnet.*.id]
}
