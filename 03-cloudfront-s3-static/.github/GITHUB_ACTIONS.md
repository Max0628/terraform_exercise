# GitHub Actions 設定指南

## 需要設定的 Secrets

在 GitHub Repository → Settings → Secrets and variables → Actions 中新增以下 Secrets：

### 1. AWS_ACCESS_KEY_ID
IAM 使用者的 Access Key ID

### 2. AWS_SECRET_ACCESS_KEY
IAM 使用者的 Secret Access Key

### 3. AWS_REGION
AWS Region，例如：`ap-northeast-1`

### 4. S3_BUCKET_NAME
S3 Bucket 名稱，可以從 Terraform output 取得：
```bash
terraform output -raw s3_bucket_name
```

### 5. CLOUDFRONT_DISTRIBUTION_ID
CloudFront Distribution ID，可以從 Terraform output 取得：
```bash
terraform output -raw cloudfront_distribution_id
```

### 6. CLOUDFRONT_DOMAIN (選用)
CloudFront Domain Name，用於顯示部署網址：
```bash
terraform output -raw cloudfront_domain_name
```

## IAM 權限需求

GitHub Actions 使用的 IAM 使用者需要以下權限：

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::your-bucket-name",
        "arn:aws:s3:::your-bucket-name/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudfront:CreateInvalidation",
        "cloudfront:GetInvalidation"
      ],
      "Resource": "arn:aws:cloudfront::ACCOUNT_ID:distribution/DISTRIBUTION_ID"
    }
  ]
}
```

## 觸發條件

當推送到 `main` 分支且修改了 `exercises/03-cloudfront-s3-static/website/` 目錄下的檔案時，會自動觸發部署。

## 部署流程

1. Checkout 程式碼
2. 設定 AWS 憑證
3. 同步檔案到 S3
4. 清除 CloudFront 快取

## 測試 GitHub Actions

```bash
# 修改網站檔案
vim exercises/03-cloudfront-s3-static/website/index.html

# 提交並推送
git add .
git commit -m "Update website content"
git push

# 查看 GitHub Actions 執行狀態
# 到 GitHub Repository → Actions 查看
```
