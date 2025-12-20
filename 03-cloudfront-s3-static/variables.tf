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

variable "custom_domain" {
  description = "自訂網域名稱（留空則使用 CloudFront 預設網域，建議配置）"
  type        = string
  default     = ""
  
  validation {
    condition = (
      var.custom_domain == "" || 
      can(regex("^[a-z0-9.-]+\\.[a-z]{2,}$", var.custom_domain))
    )
    error_message = "網域格式不正確（範例：www.example.com）"
  }
}

variable "bucket_name" {
  description = "S3 Bucket 名稱"
  type        = string
  default     = "maxchauo-cloudfront-static-website"
}
