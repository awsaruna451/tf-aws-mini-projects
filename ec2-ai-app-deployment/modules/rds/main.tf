resource "aws_db_subnet_group" "ai_app_db_subnet_group" {
  name       = "${var.name_prefix}-db-subnets"
  subnet_ids = var.private_subnet_ids
  tags       = var.tags
}

resource "aws_db_instance" "ai_app_db" {
  identifier     = "${var.name_prefix}-postgres"
  engine         = "postgres"
  engine_version = "16"

  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.ai_app_db_subnet_group.name
  vpc_security_group_ids = [var.rds_sg_id]

  multi_az                = false
  backup_retention_period = var.backup_retention_days
  deletion_protection     = var.deletion_protection
  skip_final_snapshot     = false
  final_snapshot_identifier = "${var.name_prefix}-postgres-final"

  auto_minor_version_upgrade = true

  tags = merge(var.tags, { Name = "${var.name_prefix}-postgres" })
}
