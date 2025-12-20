# S3 檔案上傳通知推播（Discord Webhook）

## 🎯 作業目標

實作一個事件驅動的通知系統：當圖片上傳到 S3 bucket 時，自動透過 Lambda 函數發送通知到 Discord 頻道，通知會計人員有新單據需要處理。

---

## 📚 核心學習重點

### 1. **Event-Driven Architecture（事件驅動架構）**
- **什麼是事件驅動**？
  - 當某個事件發生（如檔案上傳）時，自動觸發後續動作
  - 不需要輪詢（polling），節省資源
  - AWS 服務之間透過事件自動串接

- **S3 Event Notification 原理**：
  ```
  檔案上傳到 S3 
    → S3 產生 ObjectCreated 事件
    → 自動觸發 Lambda 函數
    → Lambda 呼叫 Discord Webhook
    → Discord 頻道收到通知
  ```

### 2. **AWS Lambda Serverless**
- **為什麼用 Lambda**？
  - 不需要管理伺服器（Serverless）
  - 只在函數執行時計費（按毫秒計算）
  - 自動擴展（Auto-scaling）
  - 適合事件驅動的短任務

- **Lambda 與 EC2 的差異**：
  | 比較項目 | Lambda | EC2 |
  |---------|--------|-----|
  | 管理 | 無需管理伺服器 | 需要維護 OS、套件 |
  | 計費 | 執行時間計費 | 持續運行計費 |
  | 啟動 | 毫秒級冷啟動 | 需要開機時間 |
  | 適用場景 | 短時間、事件驅動 | 長時間運行服務 |

### 3. **IAM 權限最佳實踐**
- **Least Privilege（最小權限原則）**：
  - Lambda 只需要「讀取 S3 特定 bucket」的權限
  - 不應給予「所有 S3 bucket」或「寫入權限」
  
- **Lambda Execution Role 組成**：
  ```
  Lambda Function
    ↓ 使用
  IAM Execution Role
    ↓ 附加
  IAM Policy（定義具體權限）
    - 允許寫入 CloudWatch Logs（記錄日誌）
    - 允許讀取特定 S3 bucket（取得檔案資訊）
  ```

### 4. **第三方整合（Discord Webhook）**
- **Webhook 原理**：
  - Discord 提供一個 HTTPS URL
  - 向該 URL POST JSON 資料即可發送訊息
  - 不需要 Discord SDK，只需要 HTTP 請求

---

## 🏗️ 架構圖

```
┌─────────────┐
│   使用者     │
│ 上傳單據圖片  │
└──────┬──────┘
       │ PUT Object
       ▼
┌─────────────────────┐
│   S3 Bucket         │
│ (receipt-uploads)   │◄────┐
└──────┬──────────────┘     │
       │ Event              │ 2. GetObject
       │ Notification       │    (取得檔案資訊)
       ▼                    │
┌─────────────────────┐     │
│   Lambda Function   ├─────┘
│  (discord-notifier) │
└──────┬──────────────┘
       │ HTTPS POST
       ▼
┌─────────────────────┐
│  Discord Webhook    │
│   (會計頻道)        │
└─────────────────────┘
```

---

## 📋 前置需求

1. **Discord Webhook URL**（作業已提供）
   ```
   https://discord.com/api/webhooks/1307026207325552781/yiAZaCxjkc_z8VQ4NhXMYYYZ0JaHudsy8qB1PzHT3uk7vncEghXEbBigSDoRrOPoC6kT
   ```

2. **AWS CLI 設定完成**
   ```bash
   aws configure --profile dev
   ```


---

## 🚀 部署步驟

### 1. 設定變數
```bash
# 複製範本
cp terraform.tfvars.example terraform.tfvars

# 編輯變數（貼上 Discord webhook URL）
vim terraform.tfvars
```

### 2. 初始化並部署
```bash
terraform init
terraform plan
terraform apply
```

### 3. 驗證測試

#### AWS Console
1. 進入 S3 Console
2. 找到建立的 bucket
3. 手動上傳圖片
4. 檢查 Discord 頻道

## 🧹 清理資源

```bash
# 刪除 S3 內的所有檔案（必須先清空才能刪除 bucket）
aws s3 rm s3://$(terraform output -raw s3_bucket_name) --recursive --profile dev

# 刪除所有 Terraform 資源
terraform destroy
```

---

## 💡 延伸思考

1. **安全性改進**：
   - 如何避免將 Discord Webhook URL 寫入程式碼？（提示：AWS Secrets Manager）
   - 如何限制只有特定 IP 可以上傳到 S3？

2. **功能擴展**：
   - 如何在通知中顯示圖片預覽？（提示：Pre-signed URL）
   - 如何過濾只通知特定類型檔案？（提示：Lambda 內檢查副檔名）

3. **成本優化**：
   - Lambda 是否適合每天數萬次的通知？（提示：考慮 SQS 作為緩衝）

---

## 📚 相關資源

- [AWS Lambda 開發指南](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html)
- [S3 Event Notifications](https://docs.aws.amazon.com/AmazonS3/latest/userguide/NotificationHowTo.html)
- [Discord Webhook 文件](https://discord.com/developers/docs/resources/webhook)
