# ============================================================
# Production Network Module Configuration
# ============================================================

# 引用 root 配置
include "root" {
  path = "${get_terragrunt_dir()}/../../terragrunt.hcl"
}

# 引用 environment 配置
include "env" {
  path   = "${get_terragrunt_dir()}/../terragrunt.hcl"
  expose = true
}

# ============================================================
# Terraform Module Source
# ============================================================
terraform {
  source = "../../../network"
}

# ============================================================
# Module Inputs
# ============================================================
inputs = {
  # 從 environment 層級繼承變數
  aws_region           = include.env.inputs.aws_region
  vpc_cidr             = include.env.inputs.vpc_cidr
  public_subnet_cidr   = include.env.inputs.public_subnet_cidr
  private_subnet_cidr  = include.env.inputs.private_subnet_cidr
  az1                  = include.env.inputs.az1
  az2                  = include.env.inputs.az2
}
