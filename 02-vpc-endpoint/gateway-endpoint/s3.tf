# S3 Bucket - 測試用私有 Bucket
#
# 1. Bucket 設為 Private（禁止公開存取）
# 2. Bucket Policy 限制只能從 VPC Endpoint 存取

resource "aws_s3_bucket" "test_bucket" {
  bucket = "gateway-endpoint-exercise-maxchauo"
  
  force_destroy = true  # 刪除 Bucket 時同時刪除裡面的物件
  
  tags = {
    Name = "Gateway Endpoint Test Bucket"
  }
}

# 禁止公開存取
resource "aws_s3_bucket_public_access_block" "test_bucket" {
  bucket = aws_s3_bucket.test_bucket.id
  
  block_public_acls       = true # 禁止公開 ACL
  block_public_policy     = true # 禁止公開政策
  ignore_public_acls      = true # 忽略公開 ACL
  restrict_public_buckets = true # 限制公開 Bucket
}


# Bucket Policy - 只允許從 VPC Endpoint 存取
# 確保只有 VPC 內可以存取
# 即使有 IAM 權限，從外網也無法存取

resource "aws_s3_bucket_policy" "test_bucket" {
  bucket = aws_s3_bucket.test_bucket.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAccessFromVPCEndpointOnly"
        Effect = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          aws_s3_bucket.test_bucket.arn,
          "${aws_s3_bucket.test_bucket.arn}/*"
        ]
        
        # 關鍵條件：只允許從指定的 VPC Endpoint 存取
        Condition = {
          StringEquals = {
            "aws:SourceVpce" = aws_vpc_endpoint.s3_gateway.id
          }
        }
      }
    ]
  })
  
  # 確保 Public Access Block 先建立
  depends_on = [aws_s3_bucket_public_access_block.test_bucket]
}

