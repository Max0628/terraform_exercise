output "ec2_public_ip" {
  description = "EC2 公開 IP"
  value       = aws_instance.nginx_server.public_ip
}

output "ec2_instance_id" {
  description = "EC2 實例 ID"
  value       = aws_instance.nginx_server.id
}

output "s3_bucket_name" {
  description = "S3 日誌儲存桶名稱"
  value       = aws_s3_bucket.nginx_logs.id
}

output "s3_bucket_arn" {
  description = "S3 日誌儲存桶 ARN"
  value       = aws_s3_bucket.nginx_logs.arn
}

output "athena_database" {
  description = "Athena 資料庫名稱"
  value       = aws_athena_database.nginx_logs.name
}

output "athena_workgroup" {
  description = "Athena Workgroup 名稱"
  value       = aws_athena_workgroup.nginx_logs.name
}

output "ssh_command" {
  description = "SSH 連線命令"
  value       = var.key_name != "" ? "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${aws_instance.nginx_server.public_ip}" : "請先設定 key_name 變數"
}

output "nginx_url" {
  description = "Nginx 網址"
  value       = "http://${aws_instance.nginx_server.public_ip}"
}
