module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.19.0"

  name = var.name
  cidr = var.vpc_cidr

  azs              = var.azs
  private_subnets  = [for i, az in var.azs : cidrsubnet(var.vpc_cidr, 8, i)]
  database_subnets = [for i, az in var.azs : cidrsubnet(var.vpc_cidr, 8, i + length(var.azs))]
  # Removed public subnets since ALB is internal only

  create_database_subnet_group = true
  # Removed NAT gateway since no public subnets are needed
  enable_dns_hostnames         = true
  enable_dns_support           = true

  tags = var.tags
}

# VPC Endpoints for AWS services
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.name}-vpc-endpoints-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = merge(var.tags, { Name = "${var.name}-vpc-endpoints-sg" })
}

# Secrets Manager VPC Endpoint
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id             = module.vpc.vpc_id
  service_name       = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.tags, { Name = "${var.name}-secretsmanager-endpoint" })
}

# ECR API VPC Endpoint
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id             = module.vpc.vpc_id
  service_name       = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.tags, { Name = "${var.name}-ecr-api-endpoint" })
}

# ECR Docker VPC Endpoint
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id             = module.vpc.vpc_id
  service_name       = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.tags, { Name = "${var.name}-ecr-dkr-endpoint" })
}

# CloudWatch Logs VPC Endpoint
resource "aws_vpc_endpoint" "logs" {
  vpc_id             = module.vpc.vpc_id
  service_name       = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.tags, { Name = "${var.name}-logs-endpoint" })
}

# S3 VPC Endpoint (Gateway type)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc.private_route_table_ids

  tags = merge(var.tags, { Name = "${var.name}-s3-endpoint" })
}

# Security Groups
resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "Security group for the internal application load balancer"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = concat([var.vpc_cidr], var.on_premises_cidr_blocks)
  }

  # HTTPS ingress removed - using internal ALB with HTTP only

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-alb-sg" })
}

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.name}-ecs-tasks-sg"
  description = "Security group for the ECS tasks"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-ecs-tasks-sg" })
}

resource "aws_security_group" "database" {
  name        = "${var.name}-database-sg"
  description = "Security group for the database"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-database-sg" })
}
