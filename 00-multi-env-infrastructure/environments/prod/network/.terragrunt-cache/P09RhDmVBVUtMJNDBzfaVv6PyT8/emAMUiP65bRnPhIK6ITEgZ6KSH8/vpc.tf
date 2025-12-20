# 建立一個 VPC（虛擬私有雲）
# var.vpc_cidr 由 variables.tf 設定，預設 10.0.0.0/16
# enable_dns_support/enable_dns_hostnames 讓 VPC 內資源可用 DNS 名稱
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "exercise-vpc" # VPC 名稱標籤
  }
}