# Route Table - Private Subnet 路由表
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  
  # 沒有 0.0.0.0/0 → NAT Gateway 的路由
  
  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

# 將 Route Table 關聯到 Private Subnet
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
