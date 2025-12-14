# 輸出 VPC ID，方便其他 module 或 root module 取用
output "vpc_id" {
  value = aws_vpc.main.id
  description = "VPC ID"
}

# 輸出 Public Subnet ID，方便後續建立 EC2、ELB 等資源時引用
output "public_subnet_id" {
  value = aws_subnet.public.id
  description = "Public Subnet ID"
}

# 輸出 Private Subnet ID，方便後續建立 EC2 等資源時引用
output "private_subnet_id" {
  value = aws_subnet.private.id
  description = "Private Subnet ID"
}

# 輸出 Public Subnet CIDR，用於驗證
output "public_subnet_cidr" {
  value = aws_subnet.public.cidr_block
  description = "Public Subnet CIDR"
}

# 輸出 Private Subnet CIDR，用於驗證
output "private_subnet_cidr" {
  value = aws_subnet.private.cidr_block
  description = "Private Subnet CIDR"
}
