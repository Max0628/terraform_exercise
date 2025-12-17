
# Security Groups

# Interface Endpoint Security Group
resource "aws_security_group" "interface_endpoint" {
  name        = "${var.project_name}-interface-endpoint-sg"
  description = "Security group for Interface Endpoint"
  vpc_id      = aws_vpc.main.id
  
  # 只允許 ec2 的 request 入站
  ingress {
    description     = "HTTPS from EC2"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.private_ec2.id]
  }
  
  tags = {
    Name = "${var.project_name}-interface-endpoint-sg"
  }
}


# EC2 Security Group
resource "aws_security_group" "private_ec2" {
  name        = "${var.project_name}-private-ec2-sg"
  description = "Security group for private EC2"
  vpc_id      = aws_vpc.main.id
  
  # 允許 request 從 ec2 出站
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.project_name}-private-ec2-sg"
  }
}
