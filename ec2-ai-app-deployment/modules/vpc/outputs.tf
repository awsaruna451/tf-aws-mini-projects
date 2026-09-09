output "vpc_id" {
  value = aws_vpc.ai_app.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "azs" {
  value = local.azs
}
