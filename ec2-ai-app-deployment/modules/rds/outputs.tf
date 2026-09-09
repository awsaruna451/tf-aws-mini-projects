output "endpoint" {
  value = aws_db_instance.ai_app_db.address
}

output "port" {
  value = aws_db_instance.ai_app_db.port
}

output "db_name" {
  value = aws_db_instance.ai_app_db.db_name
}
