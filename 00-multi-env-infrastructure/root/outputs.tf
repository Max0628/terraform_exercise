# -------- Network Outputs --------
output "vpc_id" {
  value       = module.network.vpc_id
  description = "VPC ID"
}

output "public_subnet_id" {
  value       = module.network.public_subnet_id
  description = "Public Subnet ID"
}

output "private_subnet_id" {
  value       = module.network.private_subnet_id
  description = "Private Subnet ID"
}

output "public_subnet_cidr" {
  value       = module.network.public_subnet_cidr
  description = "Public Subnet CIDR (10.0.0.0/20)"
}

output "private_subnet_cidr" {
  value       = module.network.private_subnet_cidr
  description = "Private Subnet CIDR (10.0.16.0/20)"
}

# -------- Compute Outputs --------
output "public_ec2_ip" {
  value       = module.compute.public_ec2_ip
  description = "Public EC2 public IP address"
}

output "private_ec2_ip" {
  value       = module.compute.private_ec2_ip
  description = "Private EC2 private IP address"
}

output "ssh_command_public" {
  value       = module.compute.ssh_command_public
  description = "SSH command to connect to public EC2"
}

output "ssh_command_private" {
  value       = module.compute.ssh_command_private
  description = "SSH command to connect to private EC2 from public EC2"
}

# -------- 使用說明 --------
output "instructions" {
  value = <<-EOT
    作業完成步驟：
    
    1. SSH 連入 Public EC2：
       ${module.compute.ssh_command_public}
    
    2. 在瀏覽器開啟 nginx 頁面：
       http://${module.compute.public_ec2_ip}
    
    3. 從 Public EC2 SSH 連入 Private EC2：
       ${module.compute.ssh_command_private}
    
    4. 在 Private EC2 上測試 NAT Gateway：
       curl google.com
  EOT
  description = "作業完成步驟說明"
}