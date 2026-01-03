variable "aws_region" {
  description = "AWS 區域"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "專案名稱"
  type        = string
  default     = "nginx-log-athena"
}

variable "environment" {
  description = "環境名稱"
  type        = string
  default     = "dev"
}

variable "instance_type" {
  description = "EC2 實例類型"
  type        = string
  default     = "t3.micro"
}

variable "allowed_ssh_cidr" {
  description = "允許 SSH 連線的 CIDR"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "log_retention_hours" {
  description = "本地日誌保留時數"
  type        = number
  default     = 24
}

variable "s3_log_bucket_name" {
  description = "S3 日誌儲存桶名稱（必須全球唯一）"
  type        = string
}

variable "key_name" {
  description = "EC2 SSH Key Pair 名稱"
  type        = string
  default     = ""
}
