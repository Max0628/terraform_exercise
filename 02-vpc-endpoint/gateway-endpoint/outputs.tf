output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "private_subnet_id" {
  description = "Private Subnet ID"
  value       = aws_subnet.private.id
}

output "s3_gateway_endpoint_id" {
  description = "S3 Gateway Endpoint ID"
  value       = aws_vpc_endpoint.s3_gateway.id
}

output "s3_bucket_name" {
  description = "測試用 S3 Bucket 名稱"
  value       = aws_s3_bucket.test_bucket.id
}

output "ec2_instance_id" {
  description = "Private EC2 Instance ID"
  value       = aws_instance.private_ec2.id
}

output "ec2_private_ip" {
  description = "EC2 Private IP"
  value       = aws_instance.private_ec2.private_ip
}

output "verification_commands" {
  description = "驗證指令"
  value       = <<-EOT
    ========================================
    驗證步驟
    ========================================
    
    1. 透過 SSM 連線到 EC2:
       aws ssm start-session --target ${aws_instance.private_ec2.id} --profile ${var.aws_profile}
    
    2. 測試 S3 存取（應該成功）:
       aws s3 ls s3://${aws_s3_bucket.test_bucket.id}
       echo "Test from Gateway Endpoint" > test.txt
       aws s3 cp test.txt s3://${aws_s3_bucket.test_bucket.id}/
    
    3. 測試外網存取（應該失敗）:
       curl -I https://www.google.com --max-time 10
       # 應該 timeout → 證明沒有 NAT Gateway
    
    4. 檢查路由:
       ip route show
       # 應該看不到 0.0.0.0/0 的預設路由
    
    ========================================
  EOT
}
