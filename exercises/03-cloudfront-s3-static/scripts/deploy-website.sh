#!/bin/bash


# 部署網站到 S3 並清除 CloudFront 快取
#
# 使用：./deploy-website.sh


set -e

echo "=========================================="
echo "部署靜態網站"
echo "=========================================="
echo ""

# 取得 Terraform outputs
echo "取得部署資訊..."
cd "$(dirname "$0")/.."
S3_BUCKET=$(terraform output -raw s3_bucket_name 2>/dev/null)
DISTRIBUTION_ID=$(terraform output -raw cloudfront_distribution_id 2>/dev/null)
AWS_PROFILE=${AWS_PROFILE:-dev}

if [ -z "$S3_BUCKET" ]; then
    echo "錯誤：無法取得 S3 Bucket 名稱"
    echo "請確認已執行 terraform apply"
    exit 1
fi

echo "S3 Bucket: $S3_BUCKET"
echo "CloudFront Distribution: $DISTRIBUTION_ID"
echo ""

# 步驟 1：同步檔案到 S3
echo "=========================================="
echo "步驟 1：上傳檔案到 S3"
echo "=========================================="

echo "同步檔案..."
aws s3 sync website/ s3://$S3_BUCKET/ \
    --profile $AWS_PROFILE \
    --delete \
    --cache-control "public, max-age=31536000" \
    --exclude "*.html" \
    --exclude "error.html"

# HTML 檔案用較短的 cache
echo "上傳 HTML 檔案（較短快取時間）..."
aws s3 sync website/ s3://$S3_BUCKET/ \
    --profile $AWS_PROFILE \
    --exclude "*" \
    --include "*.html" \
    --cache-control "public, max-age=3600"

echo "檔案上傳完成"
echo ""

# 步驟 2：清除 CloudFront 快取
echo "=========================================="
echo "步驟 2：清除 CloudFront 快取"
echo "=========================================="

echo "建立 Invalidation..."
INVALIDATION_ID=$(aws cloudfront create-invalidation \
    --distribution-id $DISTRIBUTION_ID \
    --paths "/*" \
    --profile $AWS_PROFILE \
    --output text \
    --query 'Invalidation.Id')

echo "Invalidation 已建立：$INVALIDATION_ID"
echo "等待 Invalidation 完成（通常需要 1-3 分鐘）..."
echo ""

# 取得 CloudFront URL
CLOUDFRONT_URL=$(terraform output -raw cloudfront_url)

echo "=========================================="
echo "部署完成！"
echo "=========================================="
echo ""
echo "網站網址："
echo "   $CLOUDFRONT_URL"
echo ""
echo "驗證步驟："
echo "   1. 開啟網址：open $CLOUDFRONT_URL"
echo "   2. 檢查內容是否更新"
echo "   3. 開啟 DevTools → Network → 查看 x-cache header"
echo ""
echo "提示："
echo "   - Invalidation 通常需要 1-3 分鐘完成"
echo "   - 可以使用版本號檔名（style.v2.css）避免清除快取"
echo "   - 前 1000 次 Invalidation 免費，之後每次 $0.005"
echo ""
