# Terragrunt Multi-Environment Setup

## 架構說明

這個架構使用 **Terragrunt** 來管理多環境（dev/prod）的 Infrastructure as Code，解決了：
1. **DRY 原則**: 避免重複的 backend/provider 配置
2. **Remote State**: 自動使用 S3 + DynamoDB
3. **多環境管理**: dev/prod 環境配置清晰
4. **模組依賴**: 自動處理 network → compute 的依賴關係

## 目錄結構

```
environments/
├── terragrunt.hcl           # Root 配置（所有環境共用）
│   ├── Remote State (S3 + DynamoDB)
│   ├── Provider 配置
│   └── 共用變數
│
├── dev/                     # 開發環境
│   ├── terragrunt.hcl      # Dev 環境變數
│   ├── network/
│   │   └── terragrunt.hcl  # Dev Network 配置
│   └── compute/
│       └── terragrunt.hcl  # Dev Compute 配置
│
└── prod/                    # 正式環境
    ├── terragrunt.hcl      # Prod 環境變數
    ├── network/
    │   └── terragrunt.hcl  # Prod Network 配置
    └── compute/
        └── terragrunt.hcl  # Prod Compute 配置
```

## 前置作業

### 1. 安裝 Terragrunt
```bash
# macOS
brew install terragrunt

# 驗證安裝
terragrunt --version
```

### 2. 建立 S3 Backend（只需執行一次）
```bash
cd ../backend-setup
terraform init
terraform apply
```

### 3. 更新配置
編輯環境配置檔，修改：
- `key_name`: 你的 AWS Key Pair 名稱
- `my_ip`: 你的 IP 地址（用於 SSH 存取）

## 使用方式

### Dev 環境部署

#### 方法 1: 部署整個環境（推薦）
```bash
cd environments/dev
terragrunt run-all init
terragrunt run-all plan
terragrunt run-all apply
```

#### 方法 2: 分別部署各模組
```bash
# 1. 先部署 network
cd environments/dev/network
terragrunt init
terragrunt plan
terragrunt apply

# 2. 再部署 compute（會自動讀取 network 的 outputs）
cd ../compute
terragrunt init
terragrunt plan
terragrunt apply
```

### Prod 環境部署

```bash
cd environments/prod
terragrunt run-all init
terragrunt run-all plan
terragrunt run-all apply
```

## Terragrunt 關鍵功能展示

### 1. 自動產生 Backend 配置
每個模組會自動產生 `backend.tf`，內容類似：
```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-maxchauo-exercise"
    key            = "dev/network/terraform.tfstate"
    region         = "ap-northeast-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
    profile        = "dev"
  }
}
```

### 2. State 檔案組織
```
S3 Bucket: terraform-state-maxchauo-exercise
├── dev/
│   ├── network/terraform.tfstate
│   └── compute/terraform.tfstate
└── prod/
    ├── network/terraform.tfstate
    └── compute/terraform.tfstate
```

### 3. 模組依賴管理
Compute 模組自動等待 Network 模組完成，並讀取其 outputs：
```hcl
dependency "network" {
  config_path = "../network"
}

inputs = {
  vpc_id = dependency.network.outputs.vpc_id
  # ...
}
```

## 常用指令

### 查看執行計畫
```bash
# 查看所有模組
terragrunt run-all plan

# 查看特定模組
cd network
terragrunt plan
```

### 查看 State
```bash
# 列出所有資源
terragrunt state list

# 查看特定資源
terragrunt state show aws_vpc.main
```

### 清理環境
```bash
# 刪除整個環境
cd environments/dev
terragrunt run-all destroy

# 刪除特定模組（注意順序：先 compute 後 network）
cd compute
terragrunt destroy
cd ../network
terragrunt destroy
```

## Dev vs Prod 差異

| 項目 | Dev | Prod |
|------|-----|------|
| VPC CIDR | 10.0.0.0/18 | 10.1.0.0/18 |
| Instance Type | t2.micro | t3.small |
| State Key | dev/*/terraform.tfstate | prod/*/terraform.tfstate |

## 優勢總結

### vs 純 Terraform
- ❌ Terraform: 每個環境都要複製 backend 配置
- Terragrunt: 在 root 定義一次，所有環境繼承

### vs Local State
- ❌ Local State: 無法多人協作，容易衝突
- Remote State: S3 + DynamoDB 提供 locking 機制

### 多環境管理
- ❌ 傳統做法: 用 workspace 或複製資料夾
- Terragrunt: 清晰的目錄結構，變數集中管理

## 疑難排解

### 問題 1: State Locking 錯誤
```bash
# 手動釋放鎖定（確認沒有其他人在執行）
terragrunt force-unlock <LOCK_ID>
```

### 問題 2: 找不到 dependency outputs
```bash
# 確認 network 模組已經 apply
cd ../network
terragrunt apply
```

### 問題 3: Backend 初始化失敗
```bash
# 確認 S3 bucket 和 DynamoDB table 已建立
aws s3 ls s3://terraform-state-maxchauo-exercise --profile dev
aws dynamodb describe-table --table-name terraform-state-lock --profile dev --region ap-northeast-1
```

## 下一步

1. 完成 S3 Backend setup
2. 部署 Dev 環境測試
3. 部署 Prod 環境
4. 📝 分享給同學：展示 Terragrunt 如何簡化多環境管理
