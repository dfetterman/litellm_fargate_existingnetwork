# Cost Optimization for LiteLLM on AWS Fargate

This document provides guidance on optimizing costs for the LiteLLM AWS Fargate deployment.

## Cost Components

The deployment includes several AWS services that contribute to the overall cost:

1. **AWS Fargate**: Compute resources for running the LiteLLM container
2. **Aurora PostgreSQL**: Database for storing LiteLLM configuration and usage data
3. **Client VPN**: VPN endpoint for secure access
4. **Application Load Balancer**: Internal ALB for routing traffic
5. **NAT Gateway**: For outbound internet access from private subnets
6. **CloudWatch Logs**: For storing container and VPN logs
7. **S3**: For storing ALB access logs
8. **ECR**: For storing container images

## Cost Breakdown

Here's an approximate monthly cost breakdown for a typical deployment in the US East (N. Virginia) region:

| Service | Configuration | Estimated Monthly Cost |
|---------|--------------|------------------------|
| AWS Fargate | 1 vCPU, 2 GB RAM, 1 task | $30-40 |
| Aurora PostgreSQL | Serverless v2, 0.5-4 ACUs | $40-100 |
| Client VPN | 1 endpoint, 5 connections | $20-30 |
| Application Load Balancer | Internal ALB | $20-25 |
| NAT Gateway | 1 gateway | $30-40 |
| CloudWatch Logs | Standard logging | $5-10 |
| S3 | ALB access logs | $1-2 |
| ECR | Container images | $1-2 |
| **Total** | | **$147-249** |

> **Note**: These are approximate costs and may vary based on usage, region, and specific configuration. Use the [AWS Pricing Calculator](https://calculator.aws.amazon.com/) for more accurate estimates.

## Cost Optimization Strategies

### 1. Right-size Fargate Tasks

Fargate pricing is based on the vCPU and memory resources allocated to your tasks. Right-sizing these resources can significantly reduce costs.

**Default Configuration**:
```hcl
variable "cpu" {
  description = "CPU units for the Fargate task"
  type        = number
  default     = 1024 # 1 vCPU
}

variable "memory" {
  description = "Memory for the Fargate task in MiB"
  type        = number
  default     = 2048 # 2 GB
}
```

**Optimization**:
- Monitor CPU and memory utilization using CloudWatch metrics
- Adjust resources based on actual usage
- Consider using smaller task sizes for development environments

### 2. Optimize Aurora PostgreSQL Costs

Aurora Serverless v2 costs are based on the ACU (Aurora Capacity Units) range and actual usage.

**Default Configuration**:
```hcl
variable "db_min_capacity" {
  description = "Minimum capacity for Aurora Serverless v2 in ACUs"
  type        = number
  default     = 0.5 # Minimum value for Aurora Serverless v2
}

variable "db_max_capacity" {
  description = "Maximum capacity for Aurora Serverless v2 in ACUs"
  type        = number
  default     = 4.0 # Adjust based on expected workload
}
```

**Optimization**:
- Set appropriate min/max capacity based on actual usage
- Monitor ACU consumption using CloudWatch metrics
- Consider using a smaller instance class for development environments
- Implement automated snapshots and cleanup to reduce storage costs

### 3. Reduce Client VPN Costs

Client VPN endpoints incur charges per hour of operation and per client connection.

**Optimization**:
- Disable the Client VPN endpoint when not in use:
  ```bash
  aws ec2 modify-client-vpn-endpoint \
    --client-vpn-endpoint-id <endpoint-id> \
    --vpc-id <vpc-id> \
    --server-certificate-arn <certificate-arn> \
    --connection-log-options Enabled=false
  ```
- Create a schedule to automatically enable/disable the VPN endpoint:
  ```bash
  # Create a Lambda function to toggle the VPN endpoint
  # Schedule it using EventBridge rules
  ```

### 4. Optimize NAT Gateway Usage

NAT Gateways incur hourly charges and data processing fees.

**Optimization**:
- Use a single NAT Gateway instead of one per AZ for non-production environments
- For development environments, consider using NAT Instances instead of NAT Gateways
- Implement VPC endpoints for AWS services to reduce NAT Gateway traffic

**Example VPC Endpoint Configuration**:
```hcl
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id            = module.networking.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type = "Interface"
  subnet_ids        = module.networking.private_subnets
  security_group_ids = [
    module.networking.ecs_tasks_security_group_id
  ]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id            = module.networking.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type = "Interface"
  subnet_ids        = module.networking.private_subnets
  security_group_ids = [
    module.networking.ecs_tasks_security_group_id
  ]
  private_dns_enabled = true
}
```

### 5. Implement Autoscaling with Scheduled Actions

Use scheduled scaling to reduce capacity during off-hours.

**Example Scheduled Scaling Configuration**:
```hcl
resource "aws_appautoscaling_scheduled_action" "scale_down" {
  name               = "${var.project_name}-scale-down"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  schedule           = "cron(0 20 * * ? *)"  # 8 PM UTC
  
  scalable_target_action {
    min_capacity = 0
    max_capacity = 0
  }
}

resource "aws_appautoscaling_scheduled_action" "scale_up" {
  name               = "${var.project_name}-scale-up"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  schedule           = "cron(0 8 * * ? *)"  # 8 AM UTC
  
  scalable_target_action {
    min_capacity = 1
    max_capacity = ${var.fargate_max_capacity}
  }
}
```

### 6. Optimize CloudWatch Logs

CloudWatch Logs costs are based on data ingestion and storage.

**Optimization**:
- Set appropriate log retention periods:
  ```hcl
  variable "log_retention_days" {
    description = "Number of days to retain CloudWatch logs"
    type        = number
    default     = 30  # Reduced from 90
  }
  ```
- Filter logs to reduce the volume of data sent to CloudWatch
- Use log insights queries efficiently

### 7. Use Spot Capacity for Non-Production Workloads

Fargate Spot provides up to 70% cost savings compared to on-demand pricing.

**Example Spot Configuration**:
```hcl
resource "aws_ecs_task_definition" "main" {
  # ... existing configuration ...
  
  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
    base              = 0
  }
}
```

### 8. Implement Cost Allocation Tags

Use cost allocation tags to track and attribute costs to specific projects or teams.

**Example Tag Configuration**:
```hcl
locals {
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    CostCenter  = var.cost_center
    Team        = var.team
  }
}
```

### 9. Set Up Budget Alerts

Create AWS Budgets to monitor and alert on costs.

**Example Budget Configuration**:
```hcl
resource "aws_budgets_budget" "monthly" {
  name              = "${var.project_name}-monthly-budget"
  budget_type       = "COST"
  time_unit         = "MONTHLY"
  time_period_start = "2023-01-01_00:00"
  
  limit_amount      = "200"
  limit_unit        = "USD"
  
  notification {
    comparison_operator = "GREATER_THAN"
    threshold           = 80
    threshold_type      = "PERCENTAGE"
    notification_type   = "ACTUAL"
    subscriber_email_addresses = ["your-email@example.com"]
  }
}
```

## Environment-Specific Optimizations

### Development Environment

For development environments, consider these cost-saving measures:

1. **Use a single AZ** instead of multiple AZs
2. **Reduce database capacity** to minimum values
3. **Use smaller Fargate task sizes**
4. **Implement aggressive scaling schedules** to shut down resources outside of working hours
5. **Use NAT Instances** instead of NAT Gateways
6. **Reduce log retention** periods
7. **Use Fargate Spot** for all tasks

### Staging Environment

For staging environments, balance cost and reliability:

1. **Use two AZs** for moderate redundancy
2. **Set moderate database capacity** limits
3. **Implement scaling schedules** aligned with testing periods
4. **Use a mix of on-demand and spot capacity**

### Production Environment

For production environments, prioritize reliability while still optimizing costs:

1. **Use multiple AZs** for high availability
2. **Set appropriate database capacity** based on workload
3. **Implement autoscaling** based on actual usage patterns
4. **Use reserved instances or savings plans** for predictable workloads
5. **Implement comprehensive monitoring** to identify cost optimization opportunities

## Monitoring and Optimization Tools

### AWS Cost Explorer

Use AWS Cost Explorer to analyze costs and identify optimization opportunities:

1. View costs by service, region, and tag
2. Analyze usage patterns and trends
3. Identify underutilized resources
4. Generate savings recommendations

### AWS Trusted Advisor

AWS Trusted Advisor provides recommendations for cost optimization:

1. Identify idle or underutilized resources
2. Suggest right-sizing opportunities
3. Recommend reserved capacity purchases

### CloudWatch Metrics

Monitor key metrics to identify optimization opportunities:

1. **Fargate CPU and memory utilization**
2. **Aurora ACU consumption**
3. **NAT Gateway data transfer**
4. **ALB request count**
5. **Client VPN connection count**

## Conclusion

By implementing these cost optimization strategies, you can significantly reduce the cost of running LiteLLM on AWS Fargate while maintaining the required performance and reliability. Regularly review your AWS costs and usage patterns to identify new optimization opportunities.
