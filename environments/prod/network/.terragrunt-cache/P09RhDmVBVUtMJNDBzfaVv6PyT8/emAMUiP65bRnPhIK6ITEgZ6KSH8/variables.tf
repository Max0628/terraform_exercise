# ============================================================
# Network Module Variables
# ============================================================
# 此模組不設定 default 值，所有參數必須由呼叫者提供
# 這是業界最佳實踐：模組層保持通用性，預設值集中在 root 層管理

# AWS Region
variable "aws_region" {
  description = "AWS Region to deploy resources"
  type        = string
}

# VPC CIDR Block
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

# Public Subnet CIDR
variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
}

# Private Subnet CIDR
variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
}

# Availability Zone 1
variable "az1" {
  description = "First Availability Zone for public subnet"
  type        = string
}

# Availability Zone 2
variable "az2" {
  description = "Second Availability Zone for private subnet"
  type        = string
}
