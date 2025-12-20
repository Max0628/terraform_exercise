
# EC2 Instance - Private Subnet 測試機器
#
# 學習重點：
# 1. 完全在 Private Subnet，沒有公網 IP
# 2. 透過 Instance Profile 獲得 S3 權限
# 3. 透過 Systems Manager Session Manager 連線（不需要 SSH）


# 取得最新的 Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "private_ec2" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t2.micro"  # Free tier
  
  subnet_id                   = aws_subnet.private.id
  vpc_security_group_ids      = [aws_security_group.private_ec2.id]
  associate_public_ip_address = false  # 不要公網 IP
  
  # 附加 IAM Role（可以存取 S3 和 SSM）
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  
  
  # User Data - 初始化腳本
  # 
  # 學習重點：
  # - 安裝 AWS CLI（用於測試 S3）
  # - 安裝 SSM Agent（用於 Session Manager 連線）
  
  user_data = <<-EOF
              #!/bin/bash
              # 更新系統
              yum update -y
              
              # 安裝 AWS CLI v2
              yum install -y aws-cli
              
              # 安裝 SSM Agent（Amazon Linux 2023 預設已安裝）
              systemctl enable amazon-ssm-agent
              systemctl start amazon-ssm-agent
              
              # 建立測試腳本
              cat > /home/ec2-user/test-gateway-endpoint.sh << 'SCRIPT'
              #!/bin/bash
              echo "=========================================="
              echo "Gateway Endpoint 驗證測試"
              echo "=========================================="
              echo ""
              
              echo "1. 測試 S3 存取（應該成功）..."
              aws s3 ls 2>&1 && echo "S3 存取成功" || echo "S3 存取失敗"
              echo ""
              
              echo "2. 測試外網存取（應該失敗）..."
              timeout 5 curl -I https://www.google.com 2>&1 && echo "外網可以存取（不正常）" || echo "外網無法存取（正常）"
              echo ""
              
              echo "3. 檢查路由表..."
              ip route show
              echo ""
              
              echo "=========================================="
              SCRIPT
              
              chmod +x /home/ec2-user/test-gateway-endpoint.sh
              chown ec2-user:ec2-user /home/ec2-user/test-gateway-endpoint.sh
              EOF
  
  tags = {
    Name = "${var.project_name}-private-ec2"
  }
}
