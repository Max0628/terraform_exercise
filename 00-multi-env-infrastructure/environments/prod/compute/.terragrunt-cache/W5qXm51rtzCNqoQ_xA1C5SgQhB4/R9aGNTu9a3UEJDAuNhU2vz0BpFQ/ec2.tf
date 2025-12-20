# -------- Public EC2 Instance --------
# 建立一台 EC2 在 Public Subnet
# 這台 EC2 會有 public IP，可直接從外部 SSH 連線
resource "aws_instance" "public" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.public.id]
  key_name               = aws_key_pair.main.key_name

  # User data script：啟動時自動安裝 nginx（Ubuntu 版本）
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y nginx
              systemctl start nginx
              systemctl enable nginx
              EOF

  tags = {
    Name = "public-ec2"
  }
}

# -------- Private EC2 Instance --------
# 建立一台 EC2 在 Private Subnet
# 這台 EC2 沒有 public IP，只能透過 Public EC2 或 SSM 連線
# 可透過 NAT Gateway 連外網（例如 curl google.com）
resource "aws_instance" "private" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [aws_security_group.private.id]
  key_name               = aws_key_pair.main.key_name

  tags = {
    Name = "private-ec2"
  }
}
