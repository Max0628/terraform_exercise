variable "project_name" {
  description = "專案名稱，用於資源命名"
  type        = string
  default     = "cloudfront-s3-static-maxchauo"
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-1"
}

variable "aws_profile" {
  description = "AWS CLI Profile"
  type        = string
  default     = "dev"
}

variable "enable_custom_domain" {
  description = "是否啟用自訂網域（需要 Route 53 和 ACM）"
  type        = bool
  default     = false
}

variable "custom_domain" {
  description = "自訂網域名稱（如果 enable_custom_domain = true）"
  type        = string
  default     = ""
}

variable "bucket_name" {
  description = "S3 Bucket 名稱"
  type        = string
  default     = "maxchauo-cloudfront-static-website"
}
