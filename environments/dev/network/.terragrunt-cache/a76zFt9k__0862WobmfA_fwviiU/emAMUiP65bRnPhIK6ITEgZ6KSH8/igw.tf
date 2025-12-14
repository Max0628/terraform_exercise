# 建立 Internet Gateway（IGW），讓 VPC 內資源可連外網
# vpc_id 連到上面建立的 VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "exercise-igw" # IGW 名稱標籤
  }
}
