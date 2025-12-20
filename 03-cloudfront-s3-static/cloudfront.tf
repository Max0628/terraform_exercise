
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
  # Origin - S3 來源設定
  # 
  # 學習重點：
  # - 使用 S3 REST API endpoint（不是 website endpoint）
  # - 連結到 OAC
  ########
  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.website.id}"
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
  # Default Cache Behavior - 預設快取行為
  # 
  # 學習重點：
  # - 使用 AWS 管理的 Cache Policy
  # - 強制 HTTPS
  # - 壓縮檔案
  ########
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.website.id}"
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
  }
  
  ########
  # Custom Error Response - 自訂錯誤頁面
  # 
  # 學習重點：
  # - 404 錯誤顯示自訂頁面
  # - 403 錯誤顯示自訂頁面
  # - SPA 應用可以用這個實現 client-side routing
  ########
  custom_error_response {
    error_code         = 404
    response_code      = 404
    response_page_path = "/error.html"
    error_caching_min_ttl = 300  # 錯誤頁面快取 5 分鐘
  }
  
  custom_error_response {
    error_code         = 403
    response_code      = 403
    response_page_path = "/error.html"
    error_caching_min_ttl = 300
  }
  
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
  ########
  viewer_certificate {
    cloudfront_default_certificate = !var.enable_custom_domain
    
    # 如果啟用自訂網域（需要先建立 ACM 憑證）
    # acm_certificate_arn      = var.enable_custom_domain ? aws_acm_certificate.cloudfront[0].arn : null
    # ssl_support_method       = var.enable_custom_domain ? "sni-only" : null
    # minimum_protocol_version = var.enable_custom_domain ? "TLSv1.2_2021" : null
  }
  
  # 如果啟用自訂網域
  # aliases = var.enable_custom_domain ? [var.custom_domain] : []
  
  tags = {
    Name = "${var.project_name}-distribution"
  }
}

