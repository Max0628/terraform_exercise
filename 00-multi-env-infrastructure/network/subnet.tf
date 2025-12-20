# -------- Public Subnet --------
# 建立一個 Public Subnet，位於第一個可用區（az1）
# vpc_id 連到上面建立的 VPC
# cidr_block 由 variables.tf 設定，預設 10.0.0.0/20
# map_public_ip_on_launch 設 true，讓 EC2 啟動時自動分配 public IP
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.az1
  map_public_ip_on_launch = true
  tags = {
    Name = "exercise-public-subnet" # Subnet 名稱標籤
  }
}

# -------- Private Subnet --------
# 建立一個 Private Subnet，位於第二個可用區（az2）
# 不自動分配 public IP，須透過 NAT Gateway 連外
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = var.az2
  map_public_ip_on_launch = false
  tags = {
    Name = "exercise-private-subnet" # Subnet 名稱標籤
  }
}
