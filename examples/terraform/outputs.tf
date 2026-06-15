output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "instance_public_ip" {
  description = "アプリサーバーのパブリックIP"
  value       = aws_instance.app.public_ip
}

output "rds_endpoint" {
  description = "RDSインスタンスのエンドポイント"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}
