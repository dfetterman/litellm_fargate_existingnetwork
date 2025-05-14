locals {
  # Use existing VPC ID if create_vpc is false, otherwise use the created VPC ID
  vpc_id = var.create_vpc ? module.vpc[0].vpc_id : var.existing_vpc_id
  
  # Use existing subnet IDs if create_vpc is false, otherwise use the created subnet IDs
  private_subnets = var.create_vpc ? module.vpc[0].private_subnets : var.existing_private_subnet_ids
  public_subnets = var.create_vpc ? module.vpc[0].public_subnets : var.existing_public_subnet_ids
  database_subnets = var.create_vpc ? module.vpc[0].database_subnets : var.existing_database_subnet_ids
  database_subnet_group_name = var.create_vpc ? module.vpc[0].database_subnet_group_name : var.existing_database_subnet_group_name
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.19.0"
  count   = var.create_vpc ? 1 : 0

  name = var.name
  cidr = var.vpc_cidr

  azs              = var.azs
  private_subnets  = [for i, az in var.azs : cidrsubnet(var.vpc_cidr, 8, i)]
  public_subnets   = [for i, az in var.azs : cidrsubnet(var.vpc_cidr, 8, i + 2 * length(var.azs))]
  database_subnets = [for i, az in var.azs : cidrsubnet(var.vpc_cidr, 8, i + length(var.azs))]

  create_database_subnet_group = true
  enable_dns_hostnames         = true
  enable_dns_support           = true
  
  enable_nat_gateway = true
  single_nat_gateway = var.environment == "dev" ? true : false

  tags = var.tags
}

# Internal Application Load Balancer for HTTP termination
resource "aws_lb" "alb" {
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = local.public_subnets
  security_groups    = [aws_security_group.alb.id]

  enable_deletion_protection = false

  tags = var.tags
}

# ALB Target Group for ECS service
resource "aws_lb_target_group" "alb" {
  name        = "${var.name}-alb-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "ip"

  health_check {
    protocol            = "HTTP"
    path                = "/health/liveliness"
    port                = tostring(var.container_port)
    matcher             = "200"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = var.tags
}

# ALB - Port 80 listener for health checks and HTTP traffic
resource "aws_lb_listener" "alb" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb.arn
  }

  tags = var.tags
}

# ALB - Port 4000 listener for direct LiteLLM API access
resource "aws_lb_listener" "alb_4000" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 4000
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb.arn
  }

  tags = var.tags
}

# VPC Endpoints for AWS services
# These have been removed in favor of using the existing Transit Gateway for AWS service access
# The Transit Gateway should be configured to allow traffic to AWS service public endpoints
# This approach reduces costs by leveraging existing infrastructure

# Security - ALB security group allowing HTTP traffic on ports 80 and 4000
resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "Security group for the Application Load Balancer"
  vpc_id      = local.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic from anywhere (including Verified Access endpoints)"
  }

  ingress {
    from_port   = 4000
    to_port     = 4000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow traffic on port 4000 from anywhere"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(var.tags, { Name = "${var.name}-alb-sg" })
}

# Security - ECS tasks security group allowing traffic to container port
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.name}-ecs-tasks-sg"
  description = "Security group for the ECS tasks"
  vpc_id      = local.vpc_id

  ingress {
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow traffic from anywhere to container port"
  }

  # Add ingress rule for health check port
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow health check traffic from anywhere"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-ecs-tasks-sg" })
}

# Security - Database security group restricted to ECS tasks on port 5432
resource "aws_security_group" "database" {
  name        = "${var.name}-database-sg"
  description = "Security group for the database"
  vpc_id      = local.vpc_id

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
