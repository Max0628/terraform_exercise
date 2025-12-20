
# Route Table - Private（無外網路由）
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  
  # 只有 local 路由（AWS 自動添加）
  # 10.0.0.0/16 → local
  
  tags = {
    Name = "${var.project_name}-private-rt"
    Type = "Private"
  }
}

# 關聯到 Private Subnet
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}