# S3 Gateway Endpoint - 核心資源

# 取得 S3 服務的 Prefix List（S3 的 IP 範圍列表）
data "aws_vpc_endpoint_service" "s3" {
  service      = "s3"
  service_type = "Gateway"
}

resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id       = aws_vpc.main.id
  service_name = data.aws_vpc_endpoint_service.s3.service_name
  
  # Gateway Endpoint 類型
  vpc_endpoint_type = "Gateway"
  
  # 關聯到 Private Subnet 的 Route Table
  route_table_ids = [
    aws_route_table.private.id
  ]
  
  
  # Policy - 控制可以存取哪些 S3 資源
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"  # VPC 內的所有資源
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.test_bucket.arn}",
          "${aws_s3_bucket.test_bucket.arn}/*"
        ]
      }
    ]
  })
  
  tags = {
    Name = "${var.project_name}-s3-gateway-endpoint"
    Type = "Gateway"
    Cost = "Free"  # 提醒：Gateway Endpoint 完全免費！
  }
}