# ============================================================
# Terraform Configuration
# ============================================================
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ============================================================
# Provider Configuration
# ============================================================
provider "aws" {
  region  = var.aws_region
  profile = "dev"
}

# ============================================================
# Network Module
# ============================================================
# 引用 network module，建立 VPC、Subnet、IGW、NAT Gateway、Route Table
module "network" {
  source = "../network"

  aws_region           = var.aws_region
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidr   = var.public_subnet_cidr
  private_subnet_cidr  = var.private_subnet_cidr
  az1                  = var.az1
  az2                  = var.az2
}

# -------- Compute Module --------
# 引用 compute module，建立 EC2、Security Group、Key Pair
module "compute" {
  source = "../compute"

  vpc_id             = module.network.vpc_id
  public_subnet_id   = module.network.public_subnet_id
  private_subnet_id  = module.network.private_subnet_id
  instance_type      = var.instance_type
  ami_id             = var.ami_id
  key_name           = var.key_name
  my_ip              = var.my_ip
  public_subnet_cidr = var.public_subnet_cidr
}
