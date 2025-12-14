# ============================================================
# Root Terragrunt Configuration
# ============================================================
# 這是所有環境共用的配置，定義：
# 1. Remote State Backend (S3 + DynamoDB)
# 2. Provider 配置
# 3. 共用的變數

# ============================================================
# Remote State Configuration
# ============================================================
# 所有環境的 state 都存在同一個 S3 bucket，但用不同的 key 區分
remote_state {
  backend = "s3"
  
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  
  config = {
    bucket         = "terraform-state-maxchauo-exercise"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "ap-northeast-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
    profile        = "dev"
  }
}

# ============================================================
# Provider Configuration
# ============================================================
# 自動產生 provider.tf，所有環境都會繼承這個配置
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region  = "ap-northeast-1"
  profile = "dev"
}
EOF
}

# ============================================================
# Common Inputs (所有環境共用的變數)
# ============================================================
inputs = {
  # 這裡可以放所有環境都一樣的變數
  # 例如：tags、命名規則等
}
