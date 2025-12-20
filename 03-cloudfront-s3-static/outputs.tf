output "s3_bucket_name" {
  description = "S3 Bucket 名稱"
  value       = aws_s3_bucket.website.id
}

output "s3_bucket_arn" {
  description = "S3 Bucket ARN"
  value       = aws_s3_bucket.website.arn
}

output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID（用於清除快取）"
  value       = aws_cloudfront_distribution.website.id
}

output "cloudfront_url" {
  description = "CloudFront 網址"
  value       = "https://${aws_cloudfront_distribution.website.domain_name}"
}

output "cloudfront_domain_name" {
  description = "CloudFront Domain Name"
  value       = aws_cloudfront_distribution.website.domain_name
}

output "deployment_commands" {
  description = "部署指令"
  value = <<-EOF
    
    部署步驟：
    
    1. 上傳網站檔案到 S3：
       aws s3 sync website/ s3://${aws_s3_bucket.website.id}/ \
         --profile ${var.aws_profile} \
         --delete
    
    2. 清除 CloudFront 快取：
       aws cloudfront create-invalidation \
         --distribution-id ${aws_cloudfront_distribution.website.id} \
         --paths "/*" \
         --profile ${var.aws_profile}
    
    3. 存取網站：
       open https://${aws_cloudfront_distribution.website.domain_name}
    
    或使用提供的腳本：
       chmod +x scripts/deploy-website.sh
       ./scripts/deploy-website.sh
    
    驗證測試：
    
    1. 測試 CloudFront 存取（應該成功）：
       curl -I https://${aws_cloudfront_distribution.website.domain_name}
    
    2. 測試 S3 直接存取（應該 403）：
       curl -I https://${aws_s3_bucket.website.id}.s3.${var.aws_region}.amazonaws.com/index.html
    
    3. 測試快取：
       curl -I https://${aws_cloudfront_distribution.website.domain_name} | grep X-Cache
       # 第二次應該看到 Hit from cloudfront
    
  EOF
}
