
# 變數定義
#
# 學習重點：
# 1. 變數讓 Terraform 程式碼可重複使用
# 2. 敏感資訊（如 Discord Webhook）應透過變數注入，不寫死在程式碼
# 3. 提供 description 和 type 是最佳實踐


variable "aws_region" {
  description = "AWS Region to deploy resources"
  type        = string
  default     = "ap-northeast-1"  # 東京
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "專案名稱，用於資源命名"
  type        = string
  default     = "receipt-notification"
}


# Discord Webhook URL
# 
#   安全注意：
# - 這是敏感資訊，不應直接寫在程式碼中
# - 應該透過 terraform.tfvars 或環境變數傳入
# - 生產環境建議使用 AWS Secrets Manager


variable "discord_webhook_url" {
  description = "Discord Webhook URL for sending notifications"
  type        = string
  sensitive   = true  # 標記為敏感，terraform plan/apply 時不會顯示
  
  # 沒有 default，強制使用者提供
  # 使用方式：在 terraform.tfvars 中設定，或用 -var 參數
}


# S3 Bucket 配置


variable "s3_bucket_name" {
  description = "S3 bucket name (固定名稱)"
  type        = string
  default     = "s3-bucket-maxchauo-dc-lambda-exercise"
}

variable "allowed_file_types" {
  description = "允許上傳的檔案類型（MIME types）"
  type        = list(string)
  default     = ["image/jpeg", "image/jpg", "image/png", "image/gif", "application/pdf"]
}


# Lambda 配置


variable "lambda_function_name" {
  description = "Lambda function 名稱"
  type        = string
  default     = "discord-notifier"
}

variable "lambda_runtime" {
  description = "Lambda runtime environment"
  type        = string
  default     = "nodejs20.x"  # Node.js 20
}

variable "lambda_timeout" {
  description = "Lambda 執行逾時時間（秒）"
  type        = number
  default     = 5  # Discord webhook 呼叫應該很快，30秒足夠
  
  # 為什麼不設太長？
  # - 逾時越長，萬一卡住會消耗更多費用
  # - Webhook 呼叫通常 < 5 秒
}

variable "lambda_memory_size" {
  description = "Lambda 記憶體大小（MB）- 影響 CPU 性能和費用"
  type        = number
  default     = 128  # 最小配置，webhook 呼叫不需要太多資源
  
  # Lambda 計費邏輯：
  # - 按「GB-秒」計費
  # - 記憶體越大，CPU 越快，但費用也越高
  # - 簡單的 HTTP 請求用 128MB 即可
}
