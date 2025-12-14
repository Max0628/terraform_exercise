# Terraform 升級指南：從 Local State 到 Remote State + Terragrunt

## 作業完成說明

這個專案展示了兩個進階主題：
1. **S3 Remote Backend**: 使用 S3 + DynamoDB 管理 Terraform State
2. **Terragrunt**: 簡化多環境管理，避免配置重複

## 專案架構

### 原始架構（保留作為參考）
```
root/               # 使用 local state
├── main.tf
├── terraform.tfstate  ← 存在本地
└── ...
```

### 新架構（使用 Terragrunt + Remote State）
```
terraform_exercise/
├── network/                    # 共用 modules（原本的）
├── compute/                    # 共用 modules（原本的）
├── provider/                   # 共用 modules（原本的）
│
├── backend-setup/              # 【作業 1】S3 Backend 設定
│   ├── main.tf                # 建立 S3 bucket 和 DynamoDB table
│   └── README.md
│
├── environments/               # 【作業 2】Terragrunt 多環境管理
│   ├── terragrunt.hcl         # Root: 共用配置（backend + provider）
│   ├── dev/                   # 開發環境
│   │   ├── terragrunt.hcl    # Dev 環境變數
│   │   ├── network/
│   │   │   └── terragrunt.hcl
│   │   └── compute/
│   │       └── terragrunt.hcl
│   └── prod/                  # 正式環境
│       ├── terragrunt.hcl    # Prod 環境變數
│       ├── network/
│       │   └── terragrunt.hcl
│       └── compute/
│           └── terragrunt.hcl
│
└── root/                       # 原本的配置（保留參考）
```

## 兩個作業的實作方式

### 作業 1: S3 Remote Backend

#### 為什麼需要？
- 團隊協作需要共享 state
- State locking 防止同時修改
- 版本控制追蹤歷史
- 加密存儲保護敏感資訊

#### 實作步驟
```bash
# 1. 建立 S3 和 DynamoDB（只需執行一次）
cd backend-setup
terraform init
terraform apply

# 2. 確認資源建立成功
aws s3 ls s3://terraform-state-maxchauo-exercise --profile dev
aws dynamodb describe-table --table-name terraform-state-lock --profile dev --region ap-northeast-1
```

#### 建立了什麼？
- **S3 Bucket**: `terraform-state-maxchauo-exercise`
  - 啟用版本控制（versioning）
  - 啟用加密（AES256）
  - 封鎖公開存取
- **DynamoDB Table**: `terraform-state-lock`
  - 用於 state locking
  - 按需付費模式

### 作業 2: Terragrunt 多環境管理

#### 為什麼需要？
- **避免重複**: 不用在每個環境複製 backend/provider 配置
- **多環境管理**: Dev/Prod 環境變數分離清楚
- **依賴管理**: 自動處理 network → compute 依賴
- **DRY 原則**: 共用配置定義一次，所有環境繼承

#### 實作步驟

##### 安裝 Terragrunt
```bash
brew install terragrunt
terragrunt --version
```

##### 部署 Dev 環境
```bash
cd environments/dev

# 初始化所有模組
terragrunt run-all init

# 查看執行計畫
terragrunt run-all plan

# 部署（network → compute 自動按順序）
terragrunt run-all apply
```

##### 部署 Prod 環境
```bash
cd environments/prod
terragrunt run-all init
terragrunt run-all plan
terragrunt run-all apply
```

## 🔑 關鍵技術說明

### 1. Terragrunt 的 Remote State 配置
在 `environments/terragrunt.hcl`:
```hcl
remote_state {
  backend = "s3"
  config = {
    bucket         = "terraform-state-maxchauo-exercise"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "ap-northeast-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```
- `${path_relative_to_include()}`: 自動產生不同的 state key
- 結果: `dev/network/terraform.tfstate`, `prod/compute/terraform.tfstate`

### 2. 自動產生 Provider
```hcl
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region  = var.aws_region
  profile = "dev"
}
EOF
}
```
- 每個模組自動產生 `provider.tf`
- 不用在每個環境重複寫

### 3. 模組依賴管理
在 `compute/terragrunt.hcl`:
```hcl
dependency "network" {
  config_path = "../network"
}

inputs = {
  vpc_id = dependency.network.outputs.vpc_id
}
```
- Compute 自動等待 Network 完成
- 直接讀取 Network 的 outputs

### 4. 環境變數繼承
```
Root (terragrunt.hcl)
  ├── 定義 backend、provider
  │
  ├─→ Dev (terragrunt.hcl)
  │   ├── 定義 dev 環境變數（VPC CIDR, instance type）
  │   ├─→ network/terragrunt.hcl
  │   └─→ compute/terragrunt.hcl
  │
  └─→ Prod (terragrunt.hcl)
      ├── 定義 prod 環境變數
      ├─→ network/terragrunt.hcl
      └─→ compute/terragrunt.hcl
```

## 📊 State 檔案組織

### S3 Bucket 結構
```
terraform-state-maxchauo-exercise/
├── dev/
│   ├── network/
│   │   └── terraform.tfstate     # Dev network state
│   └── compute/
│       └── terraform.tfstate     # Dev compute state
│
└── prod/
    ├── network/
    │   └── terraform.tfstate     # Prod network state
    └── compute/
        └── terraform.tfstate     # Prod compute state
```

### DynamoDB Lock Table
```
LockID 範例:
- terraform-state-maxchauo-exercise/dev/network/terraform.tfstate-md5
- terraform-state-maxchauo-exercise/prod/compute/terraform.tfstate-md5
```

## 🎓 分享給同學的重點

### 1. S3 Remote Backend 的價值
展示前後對比：
```bash
# 之前：Local State
root/terraform.tfstate  ← 只能一個人用，容易衝突

# 之後：Remote State
S3 + DynamoDB  ← 多人協作，自動 locking
```

### 2. Terragrunt 解決的問題
**沒有 Terragrunt:**
```
dev/
├── backend.tf      # 重複配置
├── provider.tf     # 重複配置
└── main.tf

prod/
├── backend.tf      # 重複配置（複製貼上）
├── provider.tf     # 重複配置（複製貼上）
└── main.tf
```

**使用 Terragrunt:**
```
environments/terragrunt.hcl    # 定義一次
├── dev/terragrunt.hcl        # 只有變數
└── prod/terragrunt.hcl       # 只有變數
```

### 3. 實際操作展示
```bash
# 展示 1: State 在 S3 上
aws s3 ls s3://terraform-state-maxchauo-exercise/dev/network/ --profile dev

# 展示 2: 自動產生的檔案
cd environments/dev/network
terragrunt init
cat backend.tf    # 自動產生！
cat provider.tf   # 自動產生！

# 展示 3: 依賴管理
cd ../compute
terragrunt plan   # 自動讀取 network outputs
```

### 4. Dev vs Prod 差異
展示如何用同一份 code 管理不同環境：
```bash
# Dev: 小 instance, 小 VPC
cd environments/dev
cat terragrunt.hcl  # instance_type = "t2.micro"

# Prod: 大 instance, 不同 VPC
cd environments/prod
cat terragrunt.hcl  # instance_type = "t3.small"
```

## ⚠️ 注意事項

### 部署前必須修改
在 `environments/dev/terragrunt.hcl` 和 `environments/prod/terragrunt.hcl`:
```hcl
key_name = "your-key-name"  # ← 改成你的 AWS Key Pair
my_ip    = "0.0.0.0/0"      # ← 改成你的 IP（安全起見）
```

### 清理順序很重要
```bash
# 正確順序：
1. 刪除 compute (依賴 network)
2. 刪除 network
3. 最後刪除 backend-setup（如果需要）

# 指令：
cd environments/dev
terragrunt run-all destroy  # 自動處理順序

# 或手動：
cd compute && terragrunt destroy
cd ../network && terragrunt destroy
```

## 🚀 進階玩法

### 1. 查看所有環境的 State
```bash
# Dev
aws s3 ls s3://terraform-state-maxchauo-exercise/dev/ --recursive --profile dev

# Prod
aws s3 ls s3://terraform-state-maxchauo-exercise/prod/ --recursive --profile dev
```

### 2. 驗證 State Locking
開兩個 terminal 同時執行：
```bash
# Terminal 1
cd environments/dev/network
terragrunt apply

# Terminal 2（會被 lock 住）
cd environments/dev/network
terragrunt apply  # 會等待，直到 Terminal 1 完成
```

### 3. State 版本控制
```bash
# 查看 S3 版本
aws s3api list-object-versions \
  --bucket terraform-state-maxchauo-exercise \
  --prefix dev/network/terraform.tfstate \
  --profile dev

# 回復到舊版本（如果不小心 destroy 了）
aws s3api get-object \
  --bucket terraform-state-maxchauo-exercise \
  --key dev/network/terraform.tfstate \
  --version-id <VERSION_ID> \
  terraform.tfstate.backup \
  --profile dev
```

## 📝 作業檢查清單

- [ ] Backend Setup 完成
  - [ ] S3 bucket 建立成功
  - [ ] DynamoDB table 建立成功
  - [ ] 測試 state 存取

- [ ] Dev 環境部署
  - [ ] Network 模組部署成功
  - [ ] Compute 模組部署成功
  - [ ] State 存在 S3 上
  - [ ] 可以 SSH 到 EC2

- [ ] Prod 環境部署
  - [ ] Network 模組部署成功
  - [ ] Compute 模組部署成功
  - [ ] 與 Dev 環境 State 分離
  - [ ] 配置不同（不同 VPC CIDR、instance type）

- [ ] 驗證 Terragrunt 功能
  - [ ] 自動產生 backend.tf
  - [ ] 自動產生 provider.tf
  - [ ] 模組依賴正確運作
  - [ ] run-all 指令正常

## 🎉 完成！

你現在擁有：
1. 完整的 S3 Remote Backend 設定
2. Terragrunt 多環境管理
3. Dev/Prod 環境分離
4. 可展示給同學的範例

Good luck with your presentation! 🚀
