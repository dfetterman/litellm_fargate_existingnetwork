# Terraform Modules Documentation

This document provides an overview of the Terraform modules used in the LiteLLM AWS Fargate deployment.

## Module Structure

The project is organized into the following modules:

```
modules/
├── client_vpn/       # AWS Client VPN endpoint configuration
├── container/        # Container image and ECR repository
├── database/         # Aurora PostgreSQL database
├── fargate/          # ECS Fargate service and task definition
├── iam/              # IAM roles and policies
├── logging/          # CloudWatch logs and S3 bucket for logs
└── networking/       # VPC, subnets, security groups, and ALB
```

## Networking Module

**Purpose**: Sets up the VPC, subnets, security groups, and internal Application Load Balancer.

**Key Resources**:
- VPC with public and private subnets
- Internet Gateway and NAT Gateway
- Security groups for ALB, ECS tasks, and database
- Internal Application Load Balancer
- Target group for the Fargate service

**Inputs**:
- `name`: Name prefix for resources
- `vpc_cidr`: CIDR block for the VPC
- `azs`: List of availability zones
- `container_port`: Port the container listens on
- `on_premises_cidr_blocks`: CIDR blocks for on-premises networks
- `aws_region`: AWS region
- `log_bucket_id`: S3 bucket ID for ALB access logs
- `tags`: Resource tags

**Outputs**:
- `vpc_id`: ID of the created VPC
- `private_subnets`: List of private subnet IDs
- `database_subnet_group_name`: Name of the database subnet group
- `alb_security_group_id`: ID of the ALB security group
- `ecs_tasks_security_group_id`: ID of the ECS tasks security group
- `database_security_group_id`: ID of the database security group
- `alb_target_group_arn`: ARN of the ALB target group
- `alb_dns_name`: DNS name of the internal ALB
- `alb_arn`: ARN of the internal ALB

## Database Module

**Purpose**: Creates an Aurora PostgreSQL Serverless v2 database for LiteLLM.

**Key Resources**:
- Aurora PostgreSQL cluster
- Database instance
- Parameter group
- Subnet group

**Inputs**:
- `name`: Name prefix for resources
- `db_name`: Database name
- `db_username`: Database username
- `db_password`: Database password
- `db_subnet_group_name`: Name of the database subnet group
- `security_group_id`: ID of the database security group
- `min_capacity`: Minimum capacity in ACUs
- `max_capacity`: Maximum capacity in ACUs
- `engine`: Database engine type
- `engine_mode`: Database engine mode
- `engine_version`: Database engine version
- `deletion_protection`: Whether to enable deletion protection
- `tags`: Resource tags

**Outputs**:
- `endpoint`: Database endpoint
- `port`: Database port
- `name`: Database name

## Container Module

**Purpose**: Creates an ECR repository and builds/pushes the LiteLLM container image.

**Key Resources**:
- ECR repository
- Container image build script

**Inputs**:
- `aws_region`: AWS region
- `repository_name`: Name of the ECR repository
- `tags`: Resource tags

**Outputs**:
- `repository_url`: URL of the ECR repository
- `image_uri`: URI of the container image

## Fargate Module

**Purpose**: Sets up the ECS cluster, service, and task definition for running LiteLLM.

**Key Resources**:
- ECS cluster
- ECS service
- Task definition
- CloudWatch log group
- Autoscaling configuration

**Inputs**:
- `name`: Name prefix for resources
- `vpc_id`: ID of the VPC
- `private_subnets`: List of private subnet IDs
- `alb_security_group_id`: ID of the ALB security group
- `ecs_tasks_security_group_id`: ID of the ECS tasks security group
- `azs`: List of availability zones
- `vpc_cidr`: CIDR block for the VPC
- `alb_target_group_arn`: ARN of the ALB target group
- `alb_dns_name`: DNS name of the internal ALB
- `alb_arn`: ARN of the internal ALB
- `dockerfile_path`: Path to the Dockerfile
- `container_port`: Port the container listens on
- `cpu`: CPU units for the Fargate task
- `memory`: Memory for the Fargate task
- `desired_count`: Desired number of tasks
- `max_capacity`: Maximum number of tasks for autoscaling
- `database_url`: Database connection URL
- `litellm_master_key`: LiteLLM master key
- `litellm_salt_key`: LiteLLM salt key
- `aws_region`: AWS region
- `log_bucket_id`: S3 bucket ID for logs
- `log_retention_days`: Number of days to retain logs
- `container_health_check_start_period`: Grace period for container health checks
- `container_health_check_path`: Path for container health checks
- `autoscaling_cpu_target`: Target CPU utilization for autoscaling
- `autoscaling_memory_target`: Target memory utilization for autoscaling
- `tags`: Resource tags
- `task_execution_role_arn`: ARN of the task execution role
- `task_role_arn`: ARN of the task role
- `container_image_uri`: URI of the container image

**Outputs**:
- `cluster_id`: ID of the ECS cluster
- `service_id`: ID of the ECS service
- `task_definition_arn`: ARN of the task definition
- `cloudwatch_log_group_name`: Name of the CloudWatch log group

## IAM Module

**Purpose**: Creates IAM roles and policies for the Fargate tasks.

**Key Resources**:
- Task execution role
- Task role
- IAM policies

**Inputs**:
- `name`: Name prefix for resources
- `tags`: Resource tags

**Outputs**:
- `task_execution_role_arn`: ARN of the task execution role
- `task_role_arn`: ARN of the task role

## Logging Module

**Purpose**: Sets up CloudWatch logs and an S3 bucket for logging.

**Key Resources**:
- S3 bucket for logs
- Bucket policy

**Inputs**:
- `name`: Name prefix for resources
- `tags`: Resource tags

**Outputs**:
- `bucket_id`: ID of the S3 bucket

## Client VPN Module

**Purpose**: Creates an AWS Client VPN endpoint for secure access to the LiteLLM service.

**Key Resources**:
- Client VPN endpoint
- VPN route
- VPN authorization rule

**Inputs**:
- `name`: Name prefix for resources
- `vpc_id`: ID of the VPC
- `private_subnets`: List of private subnet IDs
- `client_cidr_block`: CIDR block for VPN client IP assignments
- `server_certificate_arn`: ARN of the server certificate
- `client_certificate_arn`: ARN of the client certificate
- `vpc_cidr`: CIDR block for the VPC
- `tags`: Resource tags

**Outputs**:
- `endpoint_id`: ID of the Client VPN endpoint
- `endpoint_dns_name`: DNS name of the Client VPN endpoint
- `self_service_portal_url`: URL of the self-service portal
