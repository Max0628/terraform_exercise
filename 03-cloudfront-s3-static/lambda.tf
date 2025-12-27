# Archive Lambda function code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/todos"
  output_path = "${path.module}/lambda/todos.zip"
  excludes    = ["node_modules", "package-lock.json", ".gitignore"]
}

# Lambda Function
resource "aws_lambda_function" "todos_api" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "todos-api"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "index.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime         = "nodejs20.x"
  timeout         = 10
  memory_size     = 128

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.todos.name
    }
  }

  tags = {
    Name    = "Todos API Lambda"
    Project = "cloudfront-s3-static"
  }
}

# CloudWatch Log Group for Lambda（暫時註解，需要額外 IAM 權限）
# resource "aws_cloudwatch_log_group" "lambda_logs" {
#   name              = "/aws/lambda/${aws_lambda_function.todos_api.function_name}"
#   retention_in_days = 7
# 
#   tags = {
#     Name    = "Todos Lambda Logs"
#     Project = "cloudfront-s3-static"
#   }
# }
