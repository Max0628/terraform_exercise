# 輸出 Public EC2 的 Public IP
output "public_ec2_ip" {
  value       = aws_instance.public.public_ip
  description = "Public EC2 public IP address"
}

# 輸出 Private EC2 的 Private IP
output "private_ec2_ip" {
  value       = aws_instance.private.private_ip
  description = "Private EC2 private IP address"
}

# 輸出 Public EC2 的 Instance ID
output "public_ec2_id" {
  value       = aws_instance.public.id
  description = "Public EC2 instance ID"
}

# 輸出 Private EC2 的 Instance ID
output "private_ec2_id" {
  value       = aws_instance.private.id
  description = "Private EC2 instance ID"
}

# 輸出 SSH 連線指令（Public EC2）
output "ssh_command_public" {
  value       = "ssh -i ~/.ssh/id_rsa ubuntu@${aws_instance.public.public_ip}"
  description = "SSH command to connect to public EC2"
}

# 輸出從 Public EC2 連到 Private EC2 的 SSH 指令
output "ssh_command_private" {
  value       = "ssh -i ~/.ssh/id_rsa ubuntu@${aws_instance.private.private_ip}"
  description = "SSH command to connect to private EC2 from public EC2"
}

# 輸出 ProxyJump 連線指令（直接連到 Private EC2）
output "ssh_command_private_proxyjump" {
  value       = "ssh -i ~/.ssh/id_rsa -J ubuntu@${aws_instance.public.public_ip} ubuntu@${aws_instance.private.private_ip}"
  description = "SSH command to connect to private EC2 using ProxyJump"
}

# 輸出測試步驟
output "test_instructions" {
  value = <<-EOT
  
  ========================================
  測試步驟：
  ========================================
  
  1. 測試 Nginx（Public EC2）:
     瀏覽器訪問: http://${aws_instance.public.public_ip}
  
  2. SSH 連入 Public EC2:
     ${aws_instance.public.public_ip != "" ? "ssh -i ~/.ssh/id_rsa ubuntu@${aws_instance.public.public_ip}" : "等待 Public IP 分配..."}
  
  3. SSH 連入 Private EC2（通過 ProxyJump）:
     ${aws_instance.public.public_ip != "" ? "ssh -i ~/.ssh/id_rsa -J ubuntu@${aws_instance.public.public_ip} ubuntu@${aws_instance.private.private_ip}" : "等待 Public IP 分配..."}
  
  4. 在 Private EC2 測試 NAT Gateway:
     連入後執行: curl -I google.com
  
  ========================================
  EOT
  description = "Step-by-step testing instructions"
}
