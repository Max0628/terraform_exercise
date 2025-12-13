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
