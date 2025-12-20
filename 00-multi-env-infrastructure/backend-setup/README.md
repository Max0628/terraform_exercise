# S3 Backend Setup

## 目的
建立 Terraform Remote State 所需的 AWS 資源：
- **S3 Bucket**: 存放 terraform state 檔案
- **DynamoDB Table**: 用於 state locking，防止多人同時修改

## 為什麼需要這個？
- **團隊協作**: 多人可以共用同一個 state
- **State Locking**: 防止同時修改造成衝突
- **版本控制**: S3 versioning 可以追蹤 state 歷史
- **安全性**: 加密存儲，不用把 state 提交到 Git

## 使用步驟

### 1. 初始化並建立資源
```bash
cd backend-setup
terraform init
terraform plan
terraform apply
```

### 2. 記錄輸出資訊
Apply 完成後，會顯示：
- S3 bucket 名稱
- DynamoDB table 名稱

這些資訊會用在後續的 Terragrunt 配置中。

### 3. 驗證資源建立成功
```bash
# 檢查 S3 bucket
aws s3 ls s3://terraform-state-maxchauo-exercise --profile dev

# 檢查 DynamoDB table
aws dynamodb describe-table --table-name terraform-state-lock --profile dev --region ap-northeast-1
```

## 注意事項
⚠️ **這個設定只需要執行一次**，之後所有環境（dev/prod）都會使用這些資源。

⚠️ **刪除前請確認**: 刪除 S3 bucket 會導致所有環境的 state 遺失！

## 清理資源（如果需要）
```bash
terraform destroy
```
