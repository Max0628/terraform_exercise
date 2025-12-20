
# VPC - Interface Endpoint 專用

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  # - enable_dns_support：啟用 DNS 解析（必須為 true）
  # - enable_dns_hostnames：啟用 DNS 主機名稱（必須為 true）
  
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "${var.project_name}-vpc"
  }
}


# Private Subnet
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = false  # EC2 在 private subnet 啟動時，不要配置 public IP
  
  tags = {
    Name = "${var.project_name}-private-subnet"
    Type = "Private"
  }
}

