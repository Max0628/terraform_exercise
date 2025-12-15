# S3 Bucket - 單據上傳儲存

# S3 Event Notification - 觸發 Lambda
resource "aws_s3_bucket_notification" "receipt_uploads" {
  bucket = aws_s3_bucket.receipt_uploads.id
  
  # 依賴 Lambda Permission，確保權限先建立
  depends_on = [aws_lambda_permission.allow_s3_invoke]
  
  lambda_function {
    lambda_function_arn = aws_lambda_function.discord_notifier.arn
    events              = ["s3:ObjectCreated:*"]  # 所有建立事件
  }
}


# Lambda Permission - 允許 S3 調用 Lambda (Lambda 預設不允許被其他服務調用，需要明確授權)
resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.discord_notifier.function_name
  principal     = "s3.amazonaws.com"
  
  # 限制：只有這個特定 bucket 可以調用
  source_arn = aws_s3_bucket.receipt_uploads.arn
}

# s3 bucket 本身的設定
resource "aws_s3_bucket" "receipt_uploads" {
  bucket = var.s3_bucket_name

  # - true: terraform destroy 時即使 bucket 內有檔案也會刪除
  force_destroy = true
  
  tags = {
    Name        = "Receipt Uploads Bucket"
    Purpose     = "Store employee receipt images"
    AutoCleanup = "true"
  }
}

# S3 Bucket Versioning - 啟用版本控制
resource "aws_s3_bucket_versioning" "receipt_uploads" {
  bucket = aws_s3_bucket.receipt_uploads.id
  
  versioning_configuration {
    status = "Enabled"
  }
}


# S3 Bucket Public Access Block - 禁止公開存取 (S3 預設不會完全阻擋公開存取，需要明確設定)
resource "aws_s3_bucket_public_access_block" "receipt_uploads" {
  bucket = aws_s3_bucket.receipt_uploads.id
  
  # 阻擋所有公開的 ACL（Access Control List）
  block_public_acls       = true
  
  # 阻擋所有公開的 Bucket Policy
  block_public_policy     = true
  
  # 忽略所有公開的 ACL（即使設定了也不生效）
  ignore_public_acls      = true
  
  # 限制跨帳號存取（只能同帳號存取）
  restrict_public_buckets = true
}


# S3 Bucket Encryption - 啟用加密

resource "aws_s3_bucket_server_side_encryption_configuration" "receipt_uploads" {
  bucket = aws_s3_bucket.receipt_uploads.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"  # AWS S3 managed keys
    }
  }
}


# S3 Lifecycle Rule - 自動清理舊檔案（節省成本）
resource "aws_s3_bucket_lifecycle_configuration" "receipt_uploads" {
  bucket = aws_s3_bucket.receipt_uploads.id
  
  rule {
    id     = "delete-old-receipts"
    status = "Enabled"
    
    # 1 天後自動刪除（可依業務需求調整）
    expiration {
      days = 1
    }
  }
  
  # 清理舊版本（versioning 啟用時會產生）
  rule {
    id     = "delete-old-versions"
    status = "Enabled"
    
    noncurrent_version_expiration {
      noncurrent_days = 2  # 2 天後刪除舊版本
    }
  }
}

