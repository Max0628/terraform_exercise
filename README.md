# Terraform AWS 學習專案

本專案包含四個獨立的 Terraform AWS 實作作業，每個作業專注於不同的核心技術與架構模式。

## 📚 作業列表

### [00 - Multi-Environment Infrastructure](./00-multi-env-infrastructure/)
**核心技術**：
- Multi-environment setup with Terragrunt (Dev/Prod)
- Reusable Terraform modules
- Remote state management (S3 + DynamoDB)
- VPC 完整網路架構 (Public/Private Subnet, NAT Gateway, IGW)
- EC2 運算資源部署

**使用場景**：企業級多環境基礎設施管理

---

### [01 - S3 Lambda Discord 通知](./01-s3-lambda-discord/)
**核心技術**：
- Event-driven 架構
- AWS Lambda Serverless 運算
- IAM 權限最佳實踐
- S3 事件觸發機制
- 第三方服務整合 (Discord Webhook)

**使用場景**：會計系統自動通知 - S3 單據上傳自動通知會計人員

---

### [02 - VPC Endpoint](./02-vpc-endpoint/)
**核心技術**：
- 私有網路架構設計
- Gateway Endpoint (S3)
- Interface Endpoint (SQS)
- 成本優化策略
- 網路流量驗證

**使用場景**：高安全性需求系統 - 私有網路存取 AWS 服務，避免公網流量

**子作業**：
- `gateway-endpoint/` - S3 Gateway Endpoint 實作
- `interface-endpoint/` - SQS Interface Endpoint 實作

---

### [03 - CloudFront + S3 靜態網站](./03-cloudfront-s3-static/)
**核心技術**：
- CloudFront CDN 全球加速
- OAC (Origin Access Control) 安全配置
- Private S3 Bucket Policy
- 靜態網站部署最佳實踐
- CI/CD 整合 (GitHub Actions)

**使用場景**：企業官網部署 - 全球使用者快速存取，S3 保持私有

---

## 🚀 快速開始

每個作業都是獨立的 Terraform 專案，請進入對應資料夾查看詳細的 README。

## 📁 專案架構

```
terraform_exercise/
├── 00-multi-env-infrastructure/  # 多環境基礎設施
├── 01-s3-lambda-discord/         # Lambda 事件驅動
├── 02-vpc-endpoint/              # VPC Endpoint 實作
└── 03-cloudfront-s3-static/      # CloudFront CDN
```

## 🛠️ 技術棧

- **IaC 工具**：Terraform, Terragrunt
- **雲端平台**：AWS (ap-northeast-1 東京)
- **核心服務**：VPC, EC2, S3, Lambda, CloudFront, VPC Endpoint
- **版本控制**：Git, GitHub

---

> 💡 **學習提示**：建議按照 00 → 01 → 02 → 03 的順序學習，循序漸進掌握 Terraform 與 AWS 架構設計。
