# ECR Module
module "ecr" {
  source = "./ecr"

  aws_region      = var.aws_region
  repository_name = "${var.name}-proxy"
  tags            = var.tags
}

# IAM Module
module "iam" {
  source = "./iam"

  name                  = var.name
  litellm_secrets_arn   = var.litellm_secrets_arn
  # Using consolidated secret for master key
  master_key_secret_arn = var.litellm_secrets_arn
  tags                  = var.tags
}

# ECS Cluster
module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5.12.0"

  cluster_name = var.name

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.ecs.name
      }
    }
  }

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 100
      }
    }
  }

  tags = var.tags
}

# CloudWatch Log Group with explicit retention
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# Enable Container Insights
resource "aws_ecs_cluster_capacity_providers" "insights" {
  cluster_name = var.name  # Use the cluster name instead of the full ARN

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

# Task Definition
resource "aws_ecs_task_definition" "litellm" {
  family                   = "${var.name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = module.iam.task_execution_role_arn
  task_role_arn            = module.iam.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "${var.name}-container"
      image     = module.ecr.image_uri
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        },
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "DB_HOST"
          value = var.db_host
        },
        {
          name  = "DB_PORT"
          value = tostring(var.db_port)
        },
        {
          name  = "DB_NAME"
          value = var.db_name
        },
        {
          name  = "DB_USER"
          value = var.db_username
        },
        {
          name  = "STORE_MODEL_IN_DB"
          value = "True"
        },
        {
          name  = "AWS_REGION"
          value = var.aws_region
        },
        {
          name  = "AWS_REGION_NAME"
          value = var.aws_region
        },
        {
          name  = "PORT"
          value = tostring(var.container_port)
        },
        # CONFIG_SECRET_ID removed - using local config file instead
      ],

      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = "${var.litellm_secrets_arn}:db_password::"
        },
        {
          name      = "DATABASE_URL"
          valueFrom = "${var.litellm_secrets_arn}:db_connection_string::"
        },
        {
          name      = "LITELLM_MASTER_KEY"
          valueFrom = "${var.litellm_secrets_arn}:litellm_master_key::"
        }
      ],

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      # Enhanced health check using dedicated endpoint
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8080/health/readiness || exit 1"]
        startPeriod = 120  # Increase grace period to give container more time to start
        interval    = 30
        timeout     = 5
        retries     = 3
      }
    }
  ])

  tags = var.tags
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.name}-alb"
  internal           = true  # Always internal
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.private_subnets  # Always use private subnets

  enable_deletion_protection = false

  # Add access logs configuration
  access_logs {
    bucket  = var.log_bucket_id
    prefix  = "alb-access-logs"
    enabled = true
  }

  tags = var.tags
}

# Associate WAF with ALB
resource "aws_wafv2_web_acl_association" "main" {
  resource_arn = aws_lb.main.arn
  web_acl_arn  = var.web_acl_arn
}

# ALB Target Group
resource "aws_lb_target_group" "main" {
  name        = "${var.name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  # Enhanced health check with dedicated endpoint
  health_check {
    path                = "/health/liveliness"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = var.tags
}

# HTTP Listener - Direct forward to target group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  tags = var.tags
}

# ECS Service
resource "aws_ecs_service" "litellm" {
  name                              = "${var.name}-service"
  cluster                           = module.ecs.cluster_id
  task_definition                   = aws_ecs_task_definition.litellm.arn
  desired_count                     = var.desired_count
  launch_type                       = "FARGATE"
  scheduling_strategy               = "REPLICA"
  health_check_grace_period_seconds = 60
  force_new_deployment              = true

  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [var.ecs_tasks_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "${var.name}-container"
    container_port   = var.container_port
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = var.tags
}

# Auto Scaling
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = var.max_capacity
  min_capacity       = var.desired_count
  resource_id        = "service/${module.ecs.cluster_id}/${aws_ecs_service.litellm.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# CPU-based auto-scaling
resource "aws_appautoscaling_policy" "ecs_cpu_policy" {
  name               = "${var.name}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# Memory-based auto-scaling
resource "aws_appautoscaling_policy" "ecs_memory_policy" {
  name               = "${var.name}-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = 70  # Target 70% memory utilization
    scale_in_cooldown  = 300 # Wait 5 minutes before scaling in
    scale_out_cooldown = 60  # Wait 1 minute before scaling out
  }
}
