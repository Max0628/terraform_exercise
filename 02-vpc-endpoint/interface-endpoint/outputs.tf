output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "Private Subnet ID"
  value       = aws_subnet.private.id
}

output "interface_endpoint_id" {
  description = "Interface Endpoint ID"
  value       = aws_vpc_endpoint.sqs_interface.id
}

output "interface_endpoint_eni_ips" {
  description = "Interface Endpoint ENI Private IPs"
  value       = aws_vpc_endpoint.sqs_interface.network_interface_ids
}

output "sqs_queue_url" {
  description = "SQS Queue URL"
  value       = aws_sqs_queue.test_queue.url
}

output "sqs_queue_arn" {
  description = "SQS Queue ARN"
  value       = aws_sqs_queue.test_queue.arn
}

output "ec2_instance_id" {
  description = "EC2 Instance ID（用於 SSM 連線）"
  value       = aws_instance.private_ec2.id
}

output "verification_commands" {
  description = "驗證指令"
  value = <<-EOF
    
    驗證步驟：
    
    1. 連線到 EC2：
       aws ssm start-session --target ${aws_instance.private_ec2.id} --profile dev
    
    2. 測試 DNS 解析（應該回應私有 IP）：
       nslookup sqs.${var.aws_region}.amazonaws.com
    
    3. 發送 SQS 訊息：
       aws sqs send-message --queue-url ${aws_sqs_queue.test_queue.url} --message-body "Test from Interface Endpoint"
    
    4. 接收 SQS 訊息：
       aws sqs receive-message --queue-url ${aws_sqs_queue.test_queue.url}
    
    5. 測試外網（應該失敗）：
       curl -I https://www.google.com
    
    6. 檢查 Endpoint ENI：
       aws ec2 describe-network-interfaces --network-interface-ids ${join(" ", aws_vpc_endpoint.sqs_interface.network_interface_ids)} --profile dev
    
    或使用自動驗證腳本：
       cd test-scripts && chmod +x verify-interface-endpoint.sh && ./verify-interface-endpoint.sh
    
  EOF
}
