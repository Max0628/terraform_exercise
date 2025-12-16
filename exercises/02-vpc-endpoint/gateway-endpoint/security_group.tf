# Security Group - EC2 安全群組
# private ec2 呼叫 s3 是使用 https (443 port)

resource "aws_security_group" "private_ec2" {
  name        = "${var.project_name}-private-ec2-sg"
  description = "Security group for private EC2"
  vpc_id      = aws_vpc.main.id
  
  # Egress Rules - 出站規則，沒有任何限制（但沒有路由到外網，所以實際上只能存取 VPC Endpoint）
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ingress 規則 - 不允許任何入站流量，利用 SG 是 stateful 的特性，只讓 EC2 打出去 request 的 response 能回來
  
  tags = {
    Name = "${var.project_name}-private-ec2-sg"
  }
}