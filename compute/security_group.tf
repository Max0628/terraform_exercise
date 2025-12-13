# -------- Public EC2 Security Group --------
# 建立 Public EC2 的 Security Group
# 允許：SSH (22)、HTTP (80)、所有 outbound
resource "aws_security_group" "public" {
  name        = "public-ec2-sg"
  description = "Security group for public EC2"
  vpc_id      = var.vpc_id

  # 允許 SSH 連線（從你的 laptop IP）
  ingress {
    description = "SSH from my laptop"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # 允許 HTTP 連線（從任何地方，供 nginx 測試用）
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 允許所有 outbound 流量
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "public-ec2-sg"
  }
}

# -------- Private EC2 Security Group --------
# 建立 Private EC2 的 Security Group
# 允許：SSH (22) 從 Public Subnet、所有 outbound
resource "aws_security_group" "private" {
  name        = "private-ec2-sg"
  description = "Security group for private EC2"
  vpc_id      = var.vpc_id

  # 允許 SSH 連線（從 Public EC2 或你的 laptop）
  ingress {
    description = "SSH from public subnet or my laptop"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip, "10.0.0.0/20"] # Public Subnet CIDR
  }

  # 允許所有 outbound 流量（透過 NAT Gateway 連外）
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private-ec2-sg"
  }
}
