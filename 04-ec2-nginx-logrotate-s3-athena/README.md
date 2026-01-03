# EC2 Nginx 日誌管理與 Athena 查詢

## 專案目標

建立完整的 Nginx 日誌生命週期管理系統：
- EC2 上的 Nginx 日誌每小時輪替
- 本地保留最近 24 小時日誌
- 歷史日誌自動上傳至 S3
- 使用 Athena 查詢歷史日誌

## 架構

```
EC2 (Nginx)
  ↓ Logrotate (每小時)
  ↓ Cron Job (上傳)
S3 Bucket (長期儲存)
  ↓
Athena (SQL 查詢)
```

## 資料夾結構

- `main.tf` - Provider 和基本設定
- `ec2.tf` - EC2 實例設定
- `s3.tf` - S3 儲存桶
- `iam.tf` - IAM 角色和權限
- `athena.tf` - Athena 資料庫和表
- `scripts/` - 部署腳本
  - `logrotate.conf` - Logrotate 配置
  - `upload-logs.sh` - S3 上傳腳本
  - `user-data.sh` - EC2 初始化腳本

## 使用方式

```bash
# 初始化
terraform init

# 規劃
terraform plan

# 部署
terraform apply

# 查看輸出
terraform output
```

## S3 路徑結構

```
s3://bucket-name/nginx/YYYY/MM/DD/HH/hostname.access.log.gz
```

## Athena 查詢範例

```sql
-- 查詢特定 IP 的存取記錄
SELECT * FROM nginx_logs
WHERE client_ip = '203.0.113.5'
AND year = 2025 AND month = 12 AND day = 27;

-- 統計每小時的請求數
SELECT hour, COUNT(*) as requests
FROM nginx_logs
WHERE year = 2025 AND month = 12 AND day = 27
GROUP BY hour
ORDER BY hour;
```
