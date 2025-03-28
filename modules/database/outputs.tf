output "endpoint" {
  description = "Endpoint of the Aurora database"
  value       = aws_rds_cluster.aurora.endpoint
}

output "reader_endpoint" {
  description = "Reader endpoint of the Aurora database"
  value       = aws_rds_cluster.aurora.reader_endpoint
}

output "port" {
  description = "Port of the Aurora database"
  value       = aws_rds_cluster.aurora.port
}

output "cluster_id" {
  description = "ID of the Aurora cluster"
  value       = aws_rds_cluster.aurora.id
}

output "cluster_resource_id" {
  description = "Resource ID of the Aurora cluster"
  value       = aws_rds_cluster.aurora.cluster_resource_id
}
