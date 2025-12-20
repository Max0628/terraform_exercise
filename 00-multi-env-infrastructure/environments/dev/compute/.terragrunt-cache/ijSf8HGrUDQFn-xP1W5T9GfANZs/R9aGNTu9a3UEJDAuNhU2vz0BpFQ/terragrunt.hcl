# ============================================================
# Dev Compute Module Configuration
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
# Module Dependencies
# ============================================================
# Compute 模組依賴 Network 模組的輸出
dependency "network" {
  config_path = "../network"
  
  # Mock outputs for plan (避免 plan 時必須先 apply network)
  mock_outputs = {
    vpc_id            = "vpc-mock-id"
    public_subnet_id  = "subnet-mock-public"
    private_subnet_id = "subnet-mock-private"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

# ============================================================
# Terraform Module Source
# ============================================================
terraform {
  source = "../../../compute"
}

# ============================================================
# Module Inputs
# ============================================================
inputs = {
  # 從 network 模組取得的值
  vpc_id            = dependency.network.outputs.vpc_id
  public_subnet_id  = dependency.network.outputs.public_subnet_id
  private_subnet_id = dependency.network.outputs.private_subnet_id
  
  # 從 environment 層級繼承的變數
  instance_type      = include.env.inputs.instance_type
  ami_id             = include.env.inputs.ami_id
  key_name           = include.env.inputs.key_name
  my_ip              = include.env.inputs.my_ip
  public_subnet_cidr = include.env.inputs.public_subnet_cidr
}
