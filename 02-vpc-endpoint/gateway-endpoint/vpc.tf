resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  # Gateway Endpoint 需要這兩個設定
  enable_dns_support   = true  # 允許 vpc 內的機器查詢域名對應IP(DNS)
  enable_dns_hostnames = true  # 允許 vpc 內的機器有 public hostname，而不是只有 ip
  
  tags = {
    Name = "${var.project_name}-vpc"
  }
}


# Subnet - 只有 Private Subnet

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.availability_zone
  
  # 不分配公網 IP（Private Subnet）
  map_public_ip_on_launch = false
  
  tags = {
    Name = "${var.project_name}-private-subnet"
    Type = "Private"
  }
}
