# Database - Aurora Serverless v2 PostgreSQL cluster for LiteLLM
resource "aws_rds_cluster" "aurora" {
  cluster_identifier      = var.name
  engine                  = var.engine
  engine_mode             = var.engine_mode
  engine_version          = var.engine_version
  database_name           = var.db_name
  master_username         = var.db_username
  master_password         = var.db_password
  db_subnet_group_name    = var.db_subnet_group_name
  vpc_security_group_ids  = [var.security_group_id]
  skip_final_snapshot     = true
  deletion_protection     = var.deletion_protection
  backup_retention_period = 1 # Minimum backup retention period (1 day)

  serverlessv2_scaling_configuration {
    min_capacity = var.min_capacity
    max_capacity = var.max_capacity
  }

  tags = var.tags
}

# Database - Aurora Serverless instance with auto-scaling
resource "aws_rds_cluster_instance" "aurora_instances" {
  identifier         = "${var.name}-instance"
  cluster_identifier = aws_rds_cluster.aurora.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.aurora.engine
  engine_version     = aws_rds_cluster.aurora.engine_version

  tags = var.tags
}
