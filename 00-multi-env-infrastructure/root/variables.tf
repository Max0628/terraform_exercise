# ============================================================
# Root Module Variables - User Configuration Interface
# ============================================================
# 所有預設值集中在此管理，這是業界最佳實踐
# 使用者可以透過修改這些 default 值或建立 terraform.tfvars 來客製化

# AWS Region 設定（東京）
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-northeast-1" # Tokyo
}

# VPC CIDR
variable "vpc_cidr" {
  description = "CIDR for VPC"
  type        = string
  default     = "10.0.0.0/18"
}

# Public Subnet CIDR
variable "public_subnet_cidr" {
  description = "CIDR for public subnet"
  type        = string
  default     = "10.0.0.0/20"
}

# Private Subnet CIDR
variable "private_subnet_cidr" {
  description = "CIDR for private subnet"
  type        = string
  default     = "10.0.16.0/20"
}

# 第一個可用區
variable "az1" {
  description = "First Availability Zone"
  type        = string
  default     = "ap-northeast-1a"
}

# 第二個可用區
variable "az2" {
  description = "Second Availability Zone"
  type        = string
  default     = "ap-northeast-1c"
}

# EC2 Instance Type
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

# EC2 AMI ID
variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "ami-0d49f1fe982e06148" # Ubuntu 22.04 LTS (ap-northeast-1, 2025-12-12)
}

# SSH Key Pair 名稱
variable "key_name" {
  description = "SSH key pair name for EC2 access"
  type        = string
  default     = "exercise-key"
}

# 你的 laptop 公網 IP（安全性建議：限制為特定 IP）
variable "my_ip" {
  description = "Your public IP address for SSH access (CIDR format)"
  type        = string
  default     = "123.194.156.5/32"
  
  validation {
    condition     = can(cidrhost(var.my_ip, 0))
    error_message = "my_ip must be a valid CIDR block (e.g., 1.2.3.4/32 or 0.0.0.0/0)."
  }
}
