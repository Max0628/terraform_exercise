
# CloudFront Distribution - CDN 設定

# Origin Access Control (OAC) - 用於 S3 存取控制
resource "aws_cloudfront_origin_access_control" "website" {
  name                              = "${var.project_name}-oac"
  description                       = "OAC for ${var.project_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "website" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project_name} static website"
  default_root_object = "index.html"
  price_class         = "PriceClass_200"
  
  # Origin 1: S3 靜態檔案（使用 OAC）
  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id                = "S3-Frontend"
    origin_access_control_id = aws_cloudfront_origin_access_control.website.id
  }
  
  # Origin 2: API Gateway 後端 API（HTTPS only）
  origin {
    domain_name = replace(aws_apigatewayv2_api.todos_api.api_endpoint, "https://", "")
    origin_id   = "API-Backend"
    
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  
  # 預設快取行為：靜態檔案（強制 HTTPS + Gzip 壓縮）
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-Frontend"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    
    # AWS 管理的快取策略：CachingOptimized（1天 TTL）
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    
    # SPA 路由處理：將非靜態請求重寫為 /index.html
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.spa_routing.arn
    }
  }
  
  # /api/* 路徑：轉發到 API Gateway（不快取）
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    target_origin_id       = "API-Backend"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    
    # CachingDisabled：不快取 API 回應
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    
    # AllViewerExceptHostHeader：轉發所有 headers/cookies/query strings
    origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
  }
  
  # 地理限制：無
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  # SSL 憑證：根據是否配置自訂網域自動切換
  viewer_certificate {
    cloudfront_default_certificate = !local.enable_custom_domain
    acm_certificate_arn            = local.enable_custom_domain ? aws_acm_certificate_validation.cloudfront[0].certificate_arn : null
    ssl_support_method             = local.enable_custom_domain ? "sni-only" : null
    minimum_protocol_version       = local.enable_custom_domain ? "TLSv1.2_2021" : null
  }
  
  aliases = local.enable_custom_domain ? [var.custom_domain] : []
  
  tags = {
    Name = "${var.project_name}-distribution"
  }
}

