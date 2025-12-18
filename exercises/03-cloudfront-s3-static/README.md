# CloudFront + S3 靜態網站 + GitHub Actions CI/CD

## 學習目標

本練習透過建立 CloudFront + S3 架構，學習：

1. **CDN（Content Delivery Network）最佳實踐**
   - 全球加速靜態內容傳輸
   - 降低 S3 負載
   - 減少資料傳輸成本
   
2. **OAC（Origin Access Control）vs OAI**
   - OAC 是新版機制（推薦使用）
   - OAI 已被標記為 legacy（舊版）
   - 為什麼要用 OAC 而不是直接允許公開存取

3. **Bucket Policy vs ACL**
   - Bucket Policy 的優勢
   - 為什麼 AWS 建議停用 ACL
   
4. **GitHub Actions CI/CD**
   - 自動化部署靜態網站
   - Git push → 自動更新 CloudFront

## 架構說明

```
┌────────────────────────────────────────────────────────────┐
│                        Internet                            │
└────────────────────────┬───────────────────────────────────┘
                         │
                         │ HTTPS
                         ↓
          ┌──────────────────────────────┐
          │    CloudFront Distribution   │
          │  (Global Edge Locations)     │
          │  - 快取靜態內容               │
          │  - HTTPS 加密                 │
          │  - 自訂網域（選用）           │
          └──────────────┬───────────────┘
                         │
                         │ 透過 OAC 存取
                         │ (Origin Access Control)
                         ↓
          ┌──────────────────────────────┐
          │      S3 Bucket (Private)     │
          │  - 完全私有（Block Public)    │
          │  - Bucket Policy 限制         │
          │    只允許 CloudFront OAC      │
          │  - 靜態網站檔案：              │
          │    index.html, CSS, JS       │
          └──────────────────────────────┘
                         ↑
                         │ GitHub Actions
                         │ 自動上傳
          ┌──────────────────────────────┐
          │       GitHub Repository      │
          │  - git push                   │
          │  - 觸發 CI/CD                 │
          │  - 自動部署 + CloudFront 清除 │
          └──────────────────────────────┘
```

## OAC vs OAI vs Public Bucket

### 方案比較

| 方案 | 安全性 | AWS 建議 | 設定複雜度 | 限制 |
|------|--------|----------|-----------|------|
| **Public Bucket** | ❌ 低 | ❌ 不建議 | 簡單 | S3 直接公開，任何人都可存取 |
| **OAI (Legacy)** | ⚠️ 中 | ⚠️ Legacy | 中等 | 舊版機制，功能有限 |
| **OAC (推薦)** | ✅ 高 | ✅ 推薦 | 中等 | 新版機制，支援更多功能 |

### Public Bucket 的問題

```
❌ 任何人都可以直接存取 S3：
   https://bucket-name.s3.amazonaws.com/index.html

問題：
1. 繞過 CloudFront，無法計量實際流量
2. 無法使用 CloudFront 的安全功能（WAF、DDoS 防護）
3. S3 資料傳輸費用更高
```

### OAI (Origin Access Identity) - Legacy

```
⚠️ 舊版機制：
- 2022 年前的標準做法
- 功能有限
- AWS 建議遷移到 OAC
```

### OAC (Origin Access Control) - 推薦

```
✅ 新版機制（2022 推出）：
- 支援所有 S3 功能（包括 SSE-KMS 加密）
- 支援動態請求（PUT、DELETE）
- 更好的安全性（使用 AWS Signature v4）
- 未來的新功能只會加到 OAC
```

## Bucket Policy vs ACL

### ACL (Access Control List) - 不建議

```
❌ AWS 建議停用 ACL：
- 功能有限（只有預設的幾種權限）
- 無法設定複雜條件
- 難以管理（每個物件都要設定）
- 與 Bucket Policy 衝突時難以除錯
```

### Bucket Policy - 推薦

```
✅ Bucket Policy 優勢：
- 功能強大（支援各種條件）
- 集中管理（一個 Policy 控制整個 Bucket）
- 易於版本控制（JSON 格式）
- 可以設定 IP 限制、VPC 限制等
```

### 本練習的 Bucket Policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCloudFrontOAC",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudfront.amazonaws.com"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::bucket-name/*",
      "Condition": {
        "StringEquals": {
          "AWS:SourceArn": "arn:aws:cloudfront::account-id:distribution/XXXX"
        }
      }
    }
  ]
}
```

**關鍵：**
- 只允許 CloudFront 服務
- 限制特定 Distribution ARN
- 只允許 GetObject（唯讀）

## 成本分析

### CloudFront 費用（東京到台灣）

| 項目 | 費用 |
|------|------|
| 請求費用 | $0.0090 / 10,000 請求（HTTPS） |
| 資料傳輸（前 10 TB） | $0.140 / GB |
| 資料傳輸（10-50 TB） | $0.135 / GB |
| **小型網站預估** | **$5-10 / 月** |

### 對比直接用 S3

| 方案 | 每 GB 費用 | 100 GB/月 | 1 TB/月 |
|------|-----------|----------|---------|
| 直接從 S3 | $0.114 | $11.4 | $114 |
| 透過 CloudFront | $0.140 | $14.0 | $140 |

**等等，CloudFront 更貴？**

實際上 CloudFront 更便宜，因為：
1. **快取命中率 90%+**：大部分請求不會到 S3
2. **S3 請求費用**：直接存取 S3 要付每次請求費
3. **全球加速**：使用者體驗更好

**實際成本（90% 快取命中率）：**
```
CloudFront: $14.0（資料傳輸）+ $0.9（請求費）= $14.9
直接 S3:   $114（資料傳輸）+ $4（請求費）= $118

節省：$103 / 月（87% 節省）
```

## 部署步驟

### 1. 部署基礎設施

```bash
cd exercises/03-cloudfront-s3-static
terraform init
terraform plan
terraform apply
```

### 2. 上傳網站檔案

```bash
# 方式 1：手動上傳
aws s3 sync website/ s3://$(terraform output -raw s3_bucket_name)/ \
  --profile dev \
  --delete

# 清除 CloudFront 快取
aws cloudfront create-invalidation \
  --distribution-id $(terraform output -raw cloudfront_distribution_id) \
  --paths "/*" \
  --profile dev

# 方式 2：使用提供的腳本
chmod +x scripts/deploy-website.sh
./scripts/deploy-website.sh
```

### 3. 存取網站

```bash
# 取得 CloudFront URL
terraform output cloudfront_url

# 在瀏覽器開啟
open $(terraform output -raw cloudfront_url)
```

### 4. 設定 GitHub Actions（選用）

如果要自動部署：

```bash
# 1. 在 GitHub Secrets 設定：
#    AWS_ACCESS_KEY_ID
#    AWS_SECRET_ACCESS_KEY
#    AWS_REGION
#    S3_BUCKET_NAME
#    CLOUDFRONT_DISTRIBUTION_ID

# 2. Push 程式碼
git add .
git commit -m "Update website"
git push

# 3. GitHub Actions 自動：
#    - 部署檔案到 S3
#    - 清除 CloudFront 快取
```

## 驗證測試

### 1. 測試 CloudFront 存取

```bash
# 應該回應 200 OK
curl -I $(terraform output -raw cloudfront_url)
```

### 2. 測試 S3 直接存取（應該拒絕）

```bash
# 應該回應 403 Forbidden
BUCKET_NAME=$(terraform output -raw s3_bucket_name)
curl -I https://$BUCKET_NAME.s3.ap-northeast-1.amazonaws.com/index.html
```

### 3. 測試快取

```bash
# 第一次請求（Cache Miss）
curl -I $(terraform output -raw cloudfront_url) | grep X-Cache

# 第二次請求（Cache Hit）
curl -I $(terraform output -raw cloudfront_url) | grep X-Cache
# 應該看到 X-Cache: Hit from cloudfront
```

### 4. 測試 HTTPS

```bash
# 確認使用 HTTPS
curl -I $(terraform output -raw cloudfront_url) | grep -i "HTTP/2"
```

## 驗證重點

### ✅ 成功指標

1. **CloudFront 可以存取**
   - HTTP 200 OK
   - 看到完整的網頁內容

2. **S3 無法直接存取**
   - HTTP 403 Forbidden
   - 證明 Bucket 是私有的

3. **快取運作正常**
   - 第一次：X-Cache: Miss from cloudfront
   - 第二次：X-Cache: Hit from cloudfront

4. **HTTPS 運作正常**
   - 使用 HTTP/2
   - SSL 憑證有效

### ❌ 失敗排查

1. **CloudFront 回應 403**
   - 檢查 Bucket Policy 是否正確
   - 檢查 OAC 設定
   - 確認檔案已上傳到 S3

2. **S3 可以直接存取**
   - 檢查 Public Access Block 設定
   - 檢查 Bucket Policy（不應該有 Public 規則）

3. **快取不運作**
   - 檢查 CloudFront Cache Policy
   - 確認沒有設定 Cache-Control: no-cache

## 學習重點總結

### 1. OAC 是關鍵

- **為什麼用 OAC？** 安全 + 功能完整 + AWS 推薦
- **如何運作？** CloudFront 使用 AWS Signature v4 簽署請求
- **替代方案缺點：**
  - Public Bucket：不安全，無法控制存取
  - OAI：舊版，功能有限

### 2. Bucket Policy 優於 ACL

- **集中管理**：一個 JSON 控制所有權限
- **條件豐富**：可以設定 IP、VPC、SourceArn 等條件
- **易於維護**：版本控制、code review

### 3. CloudFront 的價值

- **效能**：全球 Edge Locations，降低延遲
- **成本**：快取減少 S3 請求，節省費用
- **安全**：HTTPS、DDoS 防護、WAF
- **功能**：自訂網域、SSL 憑證、壓縮

### 4. CI/CD 最佳實踐

- **自動化**：git push 自動部署
- **一致性**：避免手動錯誤
- **追蹤**：Git 歷史記錄所有變更
- **快速回滾**：git revert 即可

## 延伸學習

### 1. 自訂網域

使用 Route 53 + ACM 憑證：

```hcl
# 申請憑證（必須在 us-east-1）
resource "aws_acm_certificate" "cloudfront" {
  provider          = aws.us_east_1
  domain_name       = "www.example.com"
  validation_method = "DNS"
}

# CloudFront 使用自訂網域
resource "aws_cloudfront_distribution" "main" {
  aliases = ["www.example.com"]
  
  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.cloudfront.arn
    ssl_support_method  = "sni-only"
  }
}
```

### 2. Lambda@Edge

在 Edge 執行程式碼：

- 請求重寫（例如：/blog → /blog/index.html）
- A/B 測試
- 圖片即時壓縮
- 安全 Headers

### 3. WAF 整合

防止 DDoS、SQL Injection：

```hcl
resource "aws_wafv2_web_acl" "cloudfront" {
  name  = "cloudfront-waf"
  scope = "CLOUDFRONT"
  
  default_action {
    allow {}
  }
  
  rule {
    name     = "RateLimitRule"
    priority = 1
    
    action {
      block {}
    }
    
    statement {
      rate_based_statement {
        limit = 2000
      }
    }
  }
}
```

## 常見問題

### Q1: 為什麼不直接讓 S3 Bucket 公開？

**A:** 三個原因：
1. **安全風險**：任何人都可以直接存取，繞過 CloudFront 的安全機制
2. **成本**：直接從 S3 傳輸比從 CloudFront 更貴（無快取）
3. **無法控制**：無法追蹤實際使用量、無法設定 WAF、無法防 DDoS

### Q2: OAC 和 OAI 差在哪？能混用嗎？

**A:** 主要差異：
- **OAI (舊)**：只支援 GET/HEAD，不支援 SSE-KMS 加密
- **OAC (新)**：支援所有 HTTP 方法，支援 SSE-KMS，更安全

**不建議混用**，全部用 OAC 就對了。AWS 未來會淘汰 OAI。

### Q3: 更新網站後看不到新內容？

**A:** CloudFront 快取問題，三種解決方式：
```bash
# 1. 清除所有快取（簡單但貴，每次 $0.005）
aws cloudfront create-invalidation \
  --distribution-id XXXX \
  --paths "/*"

# 2. 只清除特定檔案
aws cloudfront create-invalidation \
  --distribution-id XXXX \
  --paths "/index.html" "/style.css"

# 3. 使用版本號（最佳實踐）
# 檔案命名：style.v2.css, script.v3.js
# 不需要清除快取，自動使用新檔案
```

### Q4: CloudFront 要多久才會生效？

**A:** 
- **首次建立**：15-20 分鐘（部署到全球 Edge Locations）
- **設定變更**：5-10 分鐘
- **清除快取**：幾秒到幾分鐘

### Q5: GitHub Actions 部署失敗怎麼辦？

**A:** 檢查清單：
1. ✅ GitHub Secrets 設定正確
2. ✅ IAM 權限足夠（S3 寫入 + CloudFront Invalidation）
3. ✅ Bucket 名稱正確
4. ✅ Distribution ID 正確
5. ✅ 網站檔案路徑正確（website/）

## 下一步

完成本練習後，你已經掌握：
- ✅ CloudFront + S3 靜態網站架構
- ✅ OAC 安全設定
- ✅ Bucket Policy vs ACL 差異
- ✅ CI/CD 自動部署

可以嘗試：
1. 加上自訂網域
2. 整合 WAF
3. 實作 Lambda@Edge 功能
4. 使用 CloudFront Functions 做簡單重寫
