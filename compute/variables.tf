# 宣告從 network module 傳入的 VPC ID
variable "vpc_id" {
  description = "VPC ID from network module"
  type        = string
}

# 宣告從 network module 傳入的 Public Subnet ID
variable "public_subnet_id" {
  description = "Public Subnet ID from network module"
  type        = string
}

# 宣告從 network module 傳入的 Private Subnet ID
variable "private_subnet_id" {
  description = "Private Subnet ID from network module"
  type        = string
}

# EC2 Instance Type
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

# EC2 AMI ID
variable "ami_id" {
  description = "AMI ID for EC2 instances (e.g., Amazon Linux 2)"
  type        = string
}

# SSH Key Pair Name
variable "key_name" {
  description = "SSH key pair name for EC2 access"
  type        = string
}

# Allowed IP for SSH Access
variable "my_ip" {
  description = "Your public IP address for SSH access (CIDR format, e.g., 1.2.3.4/32)"
  type        = string
}
