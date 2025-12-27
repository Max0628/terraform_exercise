
# CloudFront Distribution - CDN 設定
#
# 學習重點：
# 1. OAC（Origin Access Control）設定
# 2. Cache Policy 設定
# 3. 自訂錯誤頁面
# 4. HTTPS 強制



# Origin Access Control (OAC) - 新版機制
#
# 學習重點：
# - OAC 是 OAI 的升級版
# - 支援 SSE-KMS 加密
# - 支援所有 HTTP 方法
# - 使用 AWS Signature v4

resource "aws_cloudfront_origin_access_control" "website" {
  name                              = "${var.project_name}-oac"
  description                       = "OAC for ${var.project_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"  # 總是簽署請求
  signing_protocol                  = "sigv4"   # 使用 AWS Signature v4
}


# CloudFront Distribution

resource "aws_cloudfront_distribution" "website" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project_name} static website"
  default_root_object = "index.html"  # 預設首頁
  price_class         = "PriceClass_200"  # 亞洲、歐洲、北美（不含南美、澳洲）
  
  ########
  # Origin 1 - S3 來源設定（前端靜態檔案）
  # 
  # 學習重點：
  # - 使用 S3 REST API endpoint（不是 website endpoint）
  # - 連結到 OAC
  ########
  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id                = "S3-Frontend"
    origin_access_control_id = aws_cloudfront_origin_access_control.website.id
    
    
    # 為什麼用 bucket_regional_domain_name？
    # 
    # bucket_regional_domain_name:
    #   格式：bucket-name.s3.ap-northeast-1.amazonaws.com
    #   用途：REST API endpoint，支援 OAC
    # 
    # bucket_domain_name:
    #   格式：bucket-name.s3.amazonaws.com
    #   用途：全域 endpoint（較慢）
    # 
    # website_endpoint:
    #   格式：bucket-name.s3-website.ap-northeast-1.amazonaws.com
    #   用途：Static Website Hosting（不支援 OAC）
    
  }
  
  ########
  # Origin 2 - API Gateway（後端 API）
  # 
  # 學習重點：
  # - API Gateway 作為 custom origin
  # - 移除 https:// 前綴（CloudFront 要求）
  # - 使用 HTTPS 連接
  ########
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
  
  ########
  # Default Cache Behavior - 預設快取行為（靜態檔案）
  # 
  # 學習重點：
  # - 使用 AWS 管理的 Cache Policy
  # - 強制 HTTPS
  # - 壓縮檔案
  ########
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-Frontend"
    viewer_protocol_policy = "redirect-to-https"  # 強制 HTTPS
    compress               = true                  # Gzip 壓縮
    
    
    # Cache Policy - 使用 AWS 管理的政策
    # 
    # CachingOptimized (658327ea-f89d-4fab-a63d-7e88639e58f6)：
    # - Cache TTL: 86400 秒（1 天）
    # - 快取 Query Strings: No
    # - 快取 Headers: None
    # - 快取 Cookies: None
    # - 適合靜態內容
    
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    
    # CloudFront Function - SPA 路由處理
    # 將非 API 和非靜態資源的請求重寫為 /index.html，讓 Vue Router 處理路由
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.spa_routing.arn
    }
  }
  
  ########
  # Ordered Cache Behavior - /api/* 路徑分流到 API Gateway
  # 
  # 學習重點：
  # - 路徑優先級高於預設行為
  # - 支援所有 HTTP 方法（CRUD）
  # - 不快取 API 回應（CachingDisabled policy）
  ########
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    target_origin_id       = "API-Backend"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    
    # CachingDisabled (4135ea2d-6df8-44a3-9df3-4b5a84be39ad)：
    # - 不快取回應
    # - 適合動態 API
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    
    # AllViewerExceptHostHeader (b689b0a8-53d0-40ab-baf2-68738e2966ac)：
    # - 轉發所有 headers, cookies, query strings 到 origin（除了 Host）
    # - 使用 origin 的 domain name 作為 Host header
    # - 修正 API Gateway 的 Forbidden 錯誤
    origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
  }
  
  ########
  # Custom Error Response - 移除（會干擾 API 路徑）
  # 
  # 注意：
  # - custom_error_response 是全局配置，會影響所有 origins
  # - 對於 SPA 路由，Vue Router 的 history mode 會自動處理
  # - 如果需要 404 頁面，可以在 Vue Router 中配置 catch-all route
  ########
  
  # 已移除 custom_error_response 以避免干擾 API 回應
  # Vue Router 會自動處理前端路由的 404
  
  ########
  # Restrictions - 地理限制（可選）
  # 
  # 學習重點：
  # - 可以限制特定國家存取
  # - 練習不設限制（whitelist 空白）
  ########
  restrictions {
    geo_restriction {
      restriction_type = "none"  # 不限制（或用 whitelist/blacklist）
    }
  }
  
  ########
  # SSL Certificate - HTTPS 憑證
  # 
  # 學習重點：
  # - CloudFront 預設憑證（*.cloudfront.net）
  # - 如果要自訂網域，需要用 ACM 憑證（必須在 us-east-1）
  # - 根據 custom_domain 變數自動切換
  ########
  viewer_certificate {
    # 未配置自訂網域時使用 CloudFront 預設憑證
    cloudfront_default_certificate = !local.enable_custom_domain
    
    # 配置自訂網域時使用 ACM 憑證
    acm_certificate_arn      = local.enable_custom_domain ? aws_acm_certificate_validation.cloudfront[0].certificate_arn : null
    ssl_support_method       = local.enable_custom_domain ? "sni-only" : null
    minimum_protocol_version = local.enable_custom_domain ? "TLSv1.2_2021" : null
  }
  
  # 自訂網域別名（只有配置時才添加）
  aliases = local.enable_custom_domain ? [var.custom_domain] : []
  
  tags = {
    Name = "${var.project_name}-distribution"
  }
}

