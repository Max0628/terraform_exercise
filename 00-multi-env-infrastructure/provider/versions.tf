
# 指定 Terraform 及 provider 版本，確保專案相容性
terraform {
  # 限制 Terraform CLI 版本必須 >= 1.6.0
  required_version = ">= 1.6.0"

  # 指定 AWS provider 來源與版本
  required_providers {
    aws = {
      source  = "hashicorp/aws"  # 下載自官方 registry
      version = "~> 5.0"         # 允許 5.x 版本，避免重大不相容
    }
  }
}
