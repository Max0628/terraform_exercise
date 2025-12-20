# ============================================================
# Production Environment Configuration
# ============================================================
# 正式環境的特定配置
# 注意：此檔案只定義變數，不包含 include 區塊
# include 由各個 module 層負責

# ============================================================
# Production Environment Variables
# ============================================================
inputs = {
  # AWS 基本設定
  aws_region = "ap-northeast-1"
  
  # 環境標記
  environment = "prod"
  
  # Network 配置（正式環境用較大的 CIDR）
  vpc_cidr             = "10.1.0.0/18"
  public_subnet_cidr   = "10.1.0.0/20"
  private_subnet_cidr  = "10.1.16.0/20"
  az1                  = "ap-northeast-1a"
  az2                  = "ap-northeast-1c"
  
  # Compute 配置（正式環境用較大的 instance）
  instance_type = "t3.small"
  ami_id        = "ami-0d49f1fe982e06148"  # Ubuntu 22.04 LTS (ap-northeast-1, 2025-12-12)
  key_name      = "my-keypair-prod"
  my_ip         = "223.140.203.8/32"
}
