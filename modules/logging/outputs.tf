output "bucket_id" {
  description = "ID of the log bucket"
  value       = aws_s3_bucket.log_bucket.id
}

output "bucket_arn" {
  description = "ARN of the log bucket"
  value       = aws_s3_bucket.log_bucket.arn
}
