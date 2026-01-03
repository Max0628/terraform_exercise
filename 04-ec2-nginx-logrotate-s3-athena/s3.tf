# S3 儲存桶 - 存放 Nginx 日誌
resource "aws_s3_bucket" "nginx_logs" {
  bucket = var.s3_log_bucket_name

  tags = {
    Name = "${var.project_name}-logs"
  }
}

# 啟用版本控制
resource "aws_s3_bucket_versioning" "nginx_logs" {
  bucket = aws_s3_bucket.nginx_logs.id

  versioning_configuration {
    status = "Disabled"
  }
}

# 封鎖公開存取
resource "aws_s3_bucket_public_access_block" "nginx_logs" {
  bucket = aws_s3_bucket.nginx_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 生命週期規則 - 自動轉換到 Glacier
resource "aws_s3_bucket_lifecycle_configuration" "nginx_logs" {
  bucket = aws_s3_bucket.nginx_logs.id

  rule {
    id     = "archive-old-logs"
    status = "Enabled"

    filter {}

    # 30 天後轉到 Glacier
    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    # 90 天後刪除
    expiration {
      days = 90
    }
  }
}

# S3 儲存桶 - Athena 查詢結果
resource "aws_s3_bucket" "athena_results" {
  bucket = "${var.s3_log_bucket_name}-athena-results"

  tags = {
    Name = "${var.project_name}-athena-results"
  }
}

resource "aws_s3_bucket_public_access_block" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Athena 查詢結果自動清理
resource "aws_s3_bucket_lifecycle_configuration" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id

  rule {
    id     = "cleanup-query-results"
    status = "Enabled"

    filter {}

    expiration {
      days = 7
    }
  }
}
