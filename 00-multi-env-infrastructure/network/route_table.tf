
# -------- Public Route Table --------
# 建立 Public Route Table，給 public subnet 用
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "exercise-public-rt" # 路由表名稱標籤
  }
}

# Public Route Table 新增一條預設路由，所有外部流量都導到 IGW
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Public Subnet 與 Public Route Table 做關聯
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# -------- Private Route Table --------
# 建立 Private Route Table，給 private subnet 用
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "exercise-private-rt" # 路由表名稱標籤
  }
}

# Private Route Table 新增一條預設路由，所有外部流量都導到 NAT Gateway
resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

# Private Subnet 與 Private Route Table 做關聯
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
