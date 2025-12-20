# ACM SSL 憑證配置
#
# 學習重點：
# 1. CloudFront 的 ACM 憑證必須在 us-east-1 region
# 2. 使用 DNS 驗證方式
# 3. 需要客戶在 Route53 添加驗證記錄
# 4. 等待驗證完成後才能綁定到 CloudFront

locals {
  # 自動判斷是否啟用自訂網域
  enable_custom_domain = var.custom_domain != ""
}

# 條件性警告：提醒配置自訂網域
check "domain_configured" {
  assert {
    condition     = local.enable_custom_domain
    error_message = "建議配置自訂網域，在 terraform.tfvars 添加：custom_domain = \"www.yourcompany.com\""
  }
}

# ACM 憑證申請
#
# 學習重點：
# - count 用於條件性創建資源
# - provider = aws.us_east_1 指定必須在 us-east-1
# - validation_method = "DNS" 使用 DNS 驗證
resource "aws_acm_certificate" "cloudfront" {
  count = local.enable_custom_domain ? 1 : 0
  
  provider          = aws.us_east_1
  domain_name       = var.custom_domain
  validation_method = "DNS"
  
  lifecycle {
    create_before_destroy = true
  }
  
  tags = {
    Name = "${var.project_name}-certificate"
  }
}

# ACM 憑證驗證
#
# 學習重點：
# - 此資源會等待 DNS 驗證記錄生效
# - 客戶需要先在 Route53 添加驗證記錄
# - timeouts 設定最多等待 45 分鐘
resource "aws_acm_certificate_validation" "cloudfront" {
  count = local.enable_custom_domain ? 1 : 0
  
  provider        = aws.us_east_1
  certificate_arn = aws_acm_certificate.cloudfront[0].arn
  
  timeouts {
    create = "45m"
  }
}
