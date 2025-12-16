
# Terraform 配置 - Gateway Endpoint 實作

# 1. 這個專案完全不需要 NAT Gateway
# 2. EC2 透過 Gateway Endpoint 存取 S3
# 3. 驗證流量不走公網


terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
  
  default_tags {
    tags = {
      Project     = "VPC-Endpoint-Gateway"
      Exercise    = "02-vpc-endpoint"
      Type        = "Gateway-Endpoint"
      ManagedBy   = "Terraform"
    }
  }
}
