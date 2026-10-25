resource "aws_db_subnet_group" "rds_subnet_group" {
  name        = "default_subnet_group"
  description = "The default subnet group for all DBs in this architecture"

  subnet_ids = var.private_subnet_ids

    tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-rds-subnet-group"
    }
  )
}

resource "aws_db_parameter_group" "log_db_parameter" {
  name   = "rds-logs"
  family = "postgres17"

  parameter {
    value = "1"
    name  = "log_connections"
  }

   tags = merge(
        var.tags,
        {
            Name = "${var.name_prefix}-rds-parameter-group"
        }
    )
}


resource "aws_db_instance" "rds_master_db" {
  username                = "arunards"
  skip_final_snapshot     = true
  publicly_accessible     = false
  password                = var.db_password
  parameter_group_name    = aws_db_parameter_group.log_db_parameter.name
  instance_class          = var.instance_class
  engine_version          = "17.9"
  db_name                 = "rag_db"
  engine                  = "postgres"
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name
  backup_retention_period = 1
  allocated_storage       = 50
  multi_az                = true

    tags = merge(
        var.tags,
        {
            Name = "${var.name_prefix}-rds-parameter-group"
        }
    )

  vpc_security_group_ids = [
    aws_security_group.rds_sg.id
  ]
}

resource "aws_security_group" "rds_sg" {
  name        = "db_sg"
  description = "Default sg for the database"
  vpc_id      = var.vpc_id

     tags = merge(
        var.tags,
        {
            Name = "${var.name_prefix}-rds_sg"
        }
    )
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.rds_sg.id
  referenced_security_group_id        = var.rds_bastion_sg_id
  from_port                = 5432
  ip_protocol              = "tcp"
  to_port                  = 5432
}

resource "aws_vpc_security_group_egress_rule" "allow_tls_eg" {
  security_group_id = aws_security_group.rds_sg.id
  referenced_security_group_id        = var.rds_bastion_sg_id
  from_port   = 0
  ip_protocol = "tcp"
  to_port     = 65535
}

resource "aws_db_instance" "rds_db_replica" {
  skip_final_snapshot     = true
  replicate_source_db     = aws_db_instance.rds_master_db.identifier
  publicly_accessible     = false
  parameter_group_name    = aws_db_parameter_group.log_db_parameter.name
  instance_class          = var.instance_class
  identifier              = "rds-db-replica"
  backup_retention_period = 7
  apply_immediately       = true

     tags = merge(
        var.tags,
        {
            Name = "${var.name_prefix}-rds-db-replica"
        }
    )

  vpc_security_group_ids = [
    aws_security_group.rds_sg.id,
  ]
}
