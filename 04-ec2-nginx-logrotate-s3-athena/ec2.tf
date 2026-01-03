# VPC - 使用預設 VPC
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security Group
resource "aws_security_group" "nginx" {
  name        = "${var.project_name}-nginx-sg"
  description = "Security group for Nginx server"
  vpc_id      = data.aws_vpc.default.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
    description = "SSH access"
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  # 出站流量
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "${var.project_name}-nginx-sg"
  }
}

# EC2 實例
resource "aws_instance" "nginx_server" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  iam_instance_profile   = aws_iam_instance_profile.ec2_nginx.name
  vpc_security_group_ids = [aws_security_group.nginx.id]
  key_name               = var.key_name != "" ? var.key_name : null

  user_data = templatefile("${path.module}/scripts/user-data.sh", {
    s3_bucket           = aws_s3_bucket.nginx_logs.id
    log_retention_hours = var.log_retention_hours
    aws_region          = var.aws_region
  })

  tags = {
    Name = "${var.project_name}-nginx-server"
  }
}
