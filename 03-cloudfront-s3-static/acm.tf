# ACM SSL 憑證配置（CloudFront 必須在 us-east-1 region）

locals {
  enable_custom_domain = var.custom_domain != ""
}

check "domain_configured" {
  assert {
    condition     = local.enable_custom_domain
    error_message = "建議配置自訂網域，在 terraform.tfvars 添加：custom_domain = \"www.yourcompany.com\""
  }
}

# ACM 憑證申請（DNS 驗證）
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

# ACM 憑證驗證（等待 DNS 驗證記錄生效，最多 45 分鐘）
resource "aws_acm_certificate_validation" "cloudfront" {
  count = local.enable_custom_domain ? 1 : 0
  
  provider        = aws.us_east_1
  certificate_arn = aws_acm_certificate.cloudfront[0].arn
  
  timeouts {
    create = "45m"
  }
}
