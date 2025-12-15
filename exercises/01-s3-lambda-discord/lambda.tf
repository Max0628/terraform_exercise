
# Lambda Function - Discord 通知處理

# 將 Lambda 程式碼打包成 zip
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"  # lambda/ 目錄下的所有檔案
  output_path = "${path.module}/lambda/function.zip"
}

# 
resource "aws_lambda_function" "discord_notifier" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-${var.lambda_function_name}"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "index.handler"  # 檔案名稱.函數名稱
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  
  runtime = var.lambda_runtime
  timeout = var.lambda_timeout
  memory_size = var.lambda_memory_size
  
  
  # 環境變數 - 傳遞配置到 Lambda
  environment {
    variables = {
      DISCORD_WEBHOOK_URL = var.discord_webhook_url
      S3_BUCKET_NAME      = aws_s3_bucket.receipt_uploads.id
    }
  }
  
  tags = {
    Name = "Discord Notifier Function"
  }
}


# Lambda Reserved Concurrent Executions - 限制併發(rate limiting)
resource "aws_lambda_function_event_invoke_config" "discord_notifier" {
  function_name = aws_lambda_function.discord_notifier.function_name
  
  # 最多重試 0 次（Discord 通知失敗就算了，不要重複發）
  maximum_retry_attempts = 0
  
  # 最長等待事件處理時間 60 秒（AWS 最小值）
  maximum_event_age_in_seconds = 60
}
