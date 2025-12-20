output "s3_bucket_name" {
  description = "S3 Bucket 名稱（用於上傳測試檔案）"
  value       = aws_s3_bucket.receipt_uploads.id
}

output "s3_bucket_arn" {
  description = "S3 Bucket ARN"
  value       = aws_s3_bucket.receipt_uploads.arn
}

output "lambda_function_name" {
  description = "Lambda Function 名稱（用於查看日誌）"
  value       = aws_lambda_function.discord_notifier.function_name
}

output "lambda_function_arn" {
  description = "Lambda Function ARN"
  value       = aws_lambda_function.discord_notifier.arn
}

output "lambda_role_arn" {
  description = "Lambda IAM Role ARN"
  value       = aws_iam_role.lambda_execution_role.arn
}
