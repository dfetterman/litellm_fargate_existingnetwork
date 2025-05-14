output "vpc_id" {
  description = "The ID of the VPC"
  value       = local.vpc_id
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = local.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = local.public_subnets
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = local.database_subnets
}

output "database_subnet_group_name" {
  description = "Name of database subnet group"
  value       = local.database_subnet_group_name
}

output "alb_target_group_arn" {
  description = "ARN of the ALB target group"
  value       = aws_lb_target_group.alb.arn
}

output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.alb.dns_name
}

output "alb_arn" {
  description = "ARN of the internal Application Load Balancer"
  value       = aws_lb.alb.arn
}

output "alb_name" {
  description = "Name of the internal Application Load Balancer"
  value       = aws_lb.alb.name
}

output "ecs_tasks_security_group_id" {
  description = "ID of the ECS tasks security group"
  value       = aws_security_group.ecs_tasks.id
}

output "database_security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.database.id
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}
