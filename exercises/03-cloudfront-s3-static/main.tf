terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  
  # Local state（練習用）
  backend "local" {}
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "learning"
      ManagedBy   = "terraform"
      Exercise    = "cloudfront-s3-static"
    }
  }
}

# CloudFront 的 ACM 憑證必須在 us-east-1 region
provider "aws" {
  alias   = "us_east_1"
  region  = "us-east-1"
  profile = var.aws_profile
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "learning"
      ManagedBy   = "terraform"
      Exercise    = "cloudfront-s3-static"
    }
  }
}
