
# SQS Interface Endpoint - 核心資源

# 取得 SQS 服務資訊
data "aws_vpc_endpoint_service" "sqs" {
  service      = "sqs"
  service_type = "Interface"
}

resource "aws_vpc_endpoint" "sqs_interface" {
  vpc_id            = aws_vpc.main.id
  service_name      = data.aws_vpc_endpoint_service.sqs.service_name
  vpc_endpoint_type = "Interface"
  
  
  # Subnet 設定 - ENI 會建立在這些 Subnet
  subnet_ids = [
    aws_subnet.private.id
  ]
  
  
  # Security Group - 控制存取
  
  security_group_ids = [
    aws_security_group.interface_endpoint.id
  ]
  
  private_dns_enabled = true
  
  tags = {
    Name = "${var.project_name}-sqs-interface-endpoint"
    Type = "Interface"
    Cost = "$0.01/hour"  # 提醒：Interface Endpoint 要收費！
  }
}