# CloudFront Function for SPA routing
# 處理 Vue Router 的前端路由，將所有非 API 和非靜態資源的請求重定向到 index.html

resource "aws_cloudfront_function" "spa_routing" {
  name    = "spa-routing-${var.project_name}"
  runtime = "cloudfront-js-2.0"
  comment = "Rewrite SPA routes to index.html"
  publish = true
  code    = file("${path.module}/functions/spa-routing.js")
}
