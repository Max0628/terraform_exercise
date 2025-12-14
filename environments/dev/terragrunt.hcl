# ============================================================
# Dev Environment Configuration
# ============================================================
# 開發環境的特定配置
# 注意：此檔案只定義變數，不包含 include 區塊
# include 由各個 module 層負責

# ============================================================
# Dev Environment Variables
# ============================================================
inputs = {
  # AWS 基本設定
  aws_region = "ap-northeast-1"
  
  # 環境標記
  environment = "dev"
  
  # Network 配置（開發環境用較小的 CIDR）
  vpc_cidr             = "10.0.0.0/18"
  public_subnet_cidr   = "10.0.0.0/20"
  private_subnet_cidr  = "10.0.16.0/20"
  az1                  = "ap-northeast-1a"
  az2                  = "ap-northeast-1c"
  
  # Compute 配置（開發環境用較小的 instance）
  instance_type = "t2.micro"
  ami_id        = "ami-0d49f1fe982e06148"  # Ubuntu 22.04 LTS (ap-northeast-1, 2025-12-12)
  key_name      = "my-keypair"
  my_ip         = "223.140.203.8/32"
}
