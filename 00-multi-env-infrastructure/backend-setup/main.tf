# ============================================================
# S3 Backend Setup - 建立 Remote State 所需的資源
# ============================================================
# 這個檔案用來建立：
# 1. S3 Bucket - 存放 Terraform state 檔案
# 2. DynamoDB Table - 用於 state locking，防止多人同時修改

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "ap-northeast-1"
  profile = "dev"
}

# ============================================================
# S3 Bucket for Terraform State
# ============================================================
resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-state-maxchauo-exercise"

  # 防止意外刪除（正式環境建議開啟）
  lifecycle {
    prevent_destroy = false  # 學習環境設為 false，正式環境改為 true
  }

  tags = {
    Name        = "Terraform State Bucket"
    Environment = "Shared"
    Purpose     = "Store Terraform remote state"
  }
}

# 啟用版本控制 - 可以追蹤 state 的歷史變更
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# 啟用伺服器端加密 - 保護敏感資訊
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 封鎖公開存取 - 確保安全性
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ============================================================
# DynamoDB Table for State Locking
# ============================================================
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"  # 按需付費，適合開發環境
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Lock Table"
    Environment = "Shared"
    Purpose     = "Prevent concurrent Terraform state modifications"
  }
}

# ============================================================
# Outputs
# ============================================================
output "s3_bucket_name" {
  description = "The name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.terraform_state.arn
}

output "dynamodb_table_name" {
  description = "The name of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "dynamodb_table_arn" {
  description = "The ARN of the DynamoDB table"
  value       = aws_dynamodb_table.terraform_locks.arn
}
