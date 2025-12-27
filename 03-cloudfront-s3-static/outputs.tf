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
  value       = local.enable_custom_domain ? "https://${var.custom_domain}" : "https://${aws_cloudfront_distribution.website.domain_name}"
}

output "cloudfront_domain_name" {
  description = "CloudFront Domain Name"
  value       = aws_cloudfront_distribution.website.domain_name
}

output "website_url" {
  description = "網站訪問地址（使用者應該訪問的網址）"
  value       = local.enable_custom_domain ? "https://${var.custom_domain}" : "https://${aws_cloudfront_distribution.website.domain_name}"
}

output "dns_validation_records" {
  description = "DNS 驗證記錄（請將這些記錄提供給客戶添加到 Route53）"
  value = local.enable_custom_domain ? {
    for dvo in aws_acm_certificate.cloudfront[0].domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  } : {}
}

output "ssl_certificate_arn" {
  description = "ACM 憑證 ARN（僅在配置自訂網域時有值）"
  value       = local.enable_custom_domain ? aws_acm_certificate.cloudfront[0].arn : null
}

output "configuration_status" {
  description = "配置狀態"
  value = local.enable_custom_domain ? "已配置自訂網域：${var.custom_domain}" : "當前使用 CloudFront 預設網域，建議配置 custom_domain 變數"
}

# API Gateway outputs
output "api_gateway_url" {
  description = "API Gateway 端點 URL"
  value       = aws_apigatewayv2_api.todos_api.api_endpoint
}

output "api_gateway_id" {
  description = "API Gateway ID"
  value       = aws_apigatewayv2_api.todos_api.id
}

output "lambda_function_name" {
  description = "Lambda 函數名稱"
  value       = aws_lambda_function.todos_api.function_name
}

output "dynamodb_table_name" {
  description = "DynamoDB 表名稱"
  value       = aws_dynamodb_table.todos.name
}

output "api_test_commands" {
  description = "API 測試指令"
  value = <<-EOF
    
    測試 API Gateway 端點（繞過 CloudFront）：
    
    1. 取得所有 Todos：
       curl ${aws_apigatewayv2_api.todos_api.api_endpoint}/todos
    
    2. 建立新 Todo：
       curl -X POST ${aws_apigatewayv2_api.todos_api.api_endpoint}/todos \
         -H "Content-Type: application/json" \
         -d '{"text":"測試項目"}'
    
    測試 CloudFront 分流（生產環境路徑）：
    
    1. 前端（應回傳 HTML）：
       curl -I https://${aws_cloudfront_distribution.website.domain_name}/
    
    2. API（應回傳 JSON）：
       curl https://${aws_cloudfront_distribution.website.domain_name}/api/todos
    
  EOF
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
