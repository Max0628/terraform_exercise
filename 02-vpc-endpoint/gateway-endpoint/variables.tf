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

variable "project_name" {
  description = "專案名稱前綴"
  type        = string
  default     = "gateway-endpoint-demo"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidr" {
  description = "Private Subnet CIDR"
  type        = string
  default     = "10.0.16.0/20"
}

variable "availability_zone" {
  description = "Availability Zone"
  type        = string
  default     = "ap-northeast-1c"
}

variable "my_ip" {
  description = "你的公網 IP（用於 SSM 驗證，非必要）"
  type        = string
  default     = "0.0.0.0/0"
}
