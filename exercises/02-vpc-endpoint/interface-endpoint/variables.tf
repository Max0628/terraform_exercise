variable "project_name" {
  description = "專案名稱，用於資源命名"
  type        = string
  default     = "interface-endpoint"
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

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidr" {
  description = "Private subnet CIDR"
  type        = string
  default     = "10.0.16.0/20"
}

variable "availability_zone" {
  description = "可用區"
  type        = string
  default     = "ap-northeast-1c"
}

variable "my_ip" {
  description = "你的公網 IP（用於 Systems Manager 存取控制，可選）"
  type        = string
  default     = "0.0.0.0/0"
}
