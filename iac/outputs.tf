output "alb_dns_name" {
  description = "Public URL of the application (http://<this>)"
  value       = aws_lb.app.dns_name
}

output "rds_endpoint" {
  description = "RDS MySQL endpoint (private; reachable only from the app tier)"
  value       = aws_db_instance.mysql_db.address
}

output "s3_bucket" {
  description = "Application/backup S3 bucket name"
  value       = aws_s3_bucket.app_bucket.bucket
}

output "vpc_id" {
  value = aws_vpc.main.id
}
