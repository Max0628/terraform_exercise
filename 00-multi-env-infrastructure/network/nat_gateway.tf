# -------- Elastic IP for NAT Gateway --------
# 建立一個 Elastic IP，給 NAT Gateway 使用
# NAT Gateway 需要一個固定的 Public IP 來做 SNAT
resource "aws_eip" "nat" {
  domain = "vpc" # 指定此 EIP 用於 VPC
  tags = {
    Name = "exercise-nat-eip" # EIP 名稱標籤
  }
}

# -------- NAT Gateway --------
# 建立 NAT Gateway，放在 Public Subnet 內
# 讓 Private Subnet 內的 EC2 可以透過它連外網
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id       # 綁定上面建立的 EIP
  subnet_id     = aws_subnet.public.id # 必須放在 Public Subnet

  tags = {
    Name = "exercise-natgw" # NAT Gateway 名稱標籤
  }

  # NAT Gateway 需要等 IGW 建立完才能運作
  depends_on = [aws_internet_gateway.igw]
}
