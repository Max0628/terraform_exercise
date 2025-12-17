
# EC2 Instance - Private Subnet 測試機器

resource "aws_instance" "private_ec2" {
  ami           = "ami-0d49f1fe982e06148"
  instance_type = "t2.micro"
  
  subnet_id                   = aws_subnet.private.id
  vpc_security_group_ids      = [aws_security_group.private_ec2.id]
  associate_public_ip_address = false  # 不要公網 IP
  
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  
  
  # User Data - 初始化腳本
  
  user_data = <<-EOF
              #!/bin/bash
              # 更新系統
              yum update -y
              
              # 安裝 AWS CLI（Amazon Linux 2023 預設已安裝）
              yum install -y aws-cli
              
              # 確保 SSM Agent 運行
              systemctl enable amazon-ssm-agent
              systemctl start amazon-ssm-agent
              
              # 建立測試腳本
              cat > /home/ec2-user/test-interface-endpoint.sh << 'SCRIPT'
              #!/bin/bash
              echo "=========================================="
              echo "Interface Endpoint 驗證測試"
              echo "=========================================="
              echo ""
              
              QUEUE_URL="${aws_sqs_queue.test_queue.url}"
              
              echo "1. 測試 DNS 解析（應該回應私有 IP）..."
              echo "查詢：sqs.${var.aws_region}.amazonaws.com"
              nslookup sqs.${var.aws_region}.amazonaws.com
              echo ""
              
              echo "2. 發送 SQS 訊息..."
              aws sqs send-message \
                --queue-url "$QUEUE_URL" \
                --message-body "Test from Interface Endpoint at $(date)" \
                && echo " 發送成功" || echo " 發送失敗"
              echo ""
              
              echo "3. 接收 SQS 訊息..."
              aws sqs receive-message \
                --queue-url "$QUEUE_URL" \
                --max-number-of-messages 1 \
                && echo " 接收成功" || echo " 接收失敗"
              echo ""
              
              echo "4. 測試外網存取（應該失敗）..."
              timeout 5 curl -I https://www.google.com 2>&1 && echo " 外網可存取（異常）" || echo " 外網無法存取（正常）"
              echo ""
              
              echo "5. 檢查路由表（應該只有 local 路由）..."
              ip route show
              echo ""
              
              echo "=========================================="
              SCRIPT
              
              chmod +x /home/ec2-user/test-interface-endpoint.sh
              chown ec2-user:ec2-user /home/ec2-user/test-interface-endpoint.sh
              
              echo " 初始化完成" > /home/ec2-user/init-complete.txt
              EOF
  
  tags = {
    Name = "${var.project_name}-private-ec2"
  }
}
