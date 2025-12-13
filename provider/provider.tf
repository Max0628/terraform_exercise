
# 設定 AWS provider，讓 Terraform 知道要連接哪個 AWS 區域
# region 參數由變數 aws_region 決定，方便多環境切換
# profile 使用 dev，對應 ~/.aws/credentials 的 [dev] 設定
provider "aws" {
  region  = var.aws_region
  profile = "dev"
}

variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
}
