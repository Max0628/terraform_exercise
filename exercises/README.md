# AWS Terraform 練習作業

本目錄包含三個獨立的 AWS 服務實作練習，每個作業專注於不同的核心概念。

## 📚 作業列表

### [01 - S3 Lambda Discord 通知](./01-s3-lambda-discord/)
**核心學習目標**：
- ✅ Event-driven 架構：AWS 服務之間的事件驅動整合
- ✅ Lambda Serverless 實作：無伺服器運算
- ✅ IAM 權限最佳實踐：最小權限原則
- ✅ 第三方服務整合：Discord Webhook

**使用場景**：會計系統自動通知 - 當員工上傳單據到 S3 時，自動通知會計人員處理

---

### [02 - VPC Endpoint](./02-vpc-endpoint/)
**核心學習目標**：
- ✅ 私有網路架構：不走公網存取 AWS 服務
- ✅ 成本優化：避免 NAT Gateway 費用 ($0.045/hour + $0.01/GB)
- ✅ Gateway vs Interface Endpoint：兩種 Endpoint 的技術差異
- ✅ 網路流量驗證：如何證明流量走私有網路

**子作業**：
- `gateway-endpoint/` - S3 Gateway Endpoint 實作
- `interface-endpoint/` - SQS Interface Endpoint 實作

---

### [03 - CloudFront + S3 靜態網站](./03-cloudfront-s3-static/)
**核心學習目標**：
- ✅ CDN 最佳實踐：CloudFront + Private S3
- ✅ 安全配置：OAC (Origin Access Control) 取代舊的 OAI
- ✅ Bucket Policy vs ACL：權限控管方式的差異
- ✅ CI/CD 自動部署：GitHub Actions 整合

**使用場景**：企業官網部署 - 全球使用者快速存取，S3 保持私有

---

## 🎯 為什麼不用 Remote State？

這些練習作業使用 **local state**，原因：
1. **單人練習**：不需要團隊協作
2. **短期資源**：測試完立即刪除
3. **獨立專案**：各作業之間沒有資源依賴

**注意**：Remote state 的學習已經在主專案的 `environments/` 中完成（Terragrunt + S3 + DynamoDB）

---

## 📖 使用方式

每個作業目錄都是獨立的 Terraform 專案：

```bash
# 進入作業目錄
cd exercises/01-s3-lambda-discord/

# 初始化 Terraform
terraform init

# 查看要建立的資源
terraform plan

# 部署
terraform apply

# 測試驗證
# （參考各作業的 README.md）

# 清理資源（重要！避免費用）
terraform destroy
```

---

## ⚠️ 成本注意事項

| 作業 | 主要費用來源 | 預估成本/小時 |
|------|------------|-------------|
| 01 - S3 Lambda | Lambda 執行、S3 儲存 | < $0.01 |
| 02 - VPC Endpoint | VPC Endpoint (Interface) | $0.01 |
| 03 - CloudFront | CloudFront 請求數、資料傳輸 | < $0.01 |

**💡 建議**：測試完立即執行 `terraform destroy`，避免不必要的費用！

---

## 📚 參考資源

- [AWS Lambda 定價](https://aws.amazon.com/lambda/pricing/)
- [VPC Endpoints 說明](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints.html)
- [CloudFront OAC 文件](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html)
