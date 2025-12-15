
# Terraform 配置
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"  # 使用 6.x 版本
    }
  }
}


# AWS Provider 配置
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
  
  default_tags {
    tags = {
      Project     = "S3-Lambda-Discord-Notification"
      Environment = "Exercise"
      ManagedBy   = "Terraform"
      Purpose     = "Learning"
    }
  }
}
