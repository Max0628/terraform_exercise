
# S3 Bucket - 私有靜態網站儲存

resource "aws_s3_bucket" "website" {
  bucket = var.bucket_name
  
  force_destroy = true
  
  tags = {
    Name        = "CloudFront Static Website"
    Project     = var.project_name
    Environment = "Production"
  }
}

resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id
  
  block_public_acls       = true  # 阻擋公開 ACL
  block_public_policy     = true  # 阻擋公開 Bucket Policy
  ignore_public_acls      = true  # 忽略公開 ACL
  restrict_public_buckets = true  # 限制公開 Bucket
}


# Bucket Versioning - 版本控制
resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id
  
  versioning_configuration {
    status = "Enabled"
  }
}


# Server-Side Encryption - 預設加密

resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
  bucket = aws_s3_bucket.website.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"  # 或 "aws:kms" 使用 KMS
    }
    bucket_key_enabled = false  # 減少 KMS 請求次數（如果用 KMS）
  }
}


# Bucket Policy - 只允許 CloudFront OAC 存取

resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontOAC" // 允許 CloudFront OAC 存取
        Effect = "Allow" // 允許
        Principal = {
          Service = "cloudfront.amazonaws.com" // cloudfront 服務可以進行：
        }
        Action   = "s3:GetObject" // 只能讀取物件
        Resource = "${aws_s3_bucket.website.arn}/*" // 指定 Bucket 下的所有物件
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.website.arn // 限制特定 Distribution
          }
        }
      }
    ]
  })
  
  # 確保 Public Access Block 先建立
  depends_on = [aws_s3_bucket_public_access_block.website]
}