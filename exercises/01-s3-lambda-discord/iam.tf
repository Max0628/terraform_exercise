# IAM Role for Lambda
resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.project_name}-lambda-execution-role"
  
  # Assume Role Policy (Trust Policy)
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com" # 允許 Lambda play role
        }
      }
    ]
  })
  
  tags = {
    Name = "Lambda Execution Role"
  }
}


# IAM Policy - S3 讀取權限
resource "aws_iam_policy" "lambda_s3_read" {
  name        = "${var.project_name}-lambda-s3-read-policy"
  description = "允許 Lambda 讀取 S3 bucket"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",          # 讀取物件內容
          "s3:GetObjectVersion",   # 讀取特定版本
          "s3:ListBucket"          # 列出 bucket 內容
        ]
        # 限制：只能存取特定 bucket
        Resource = [
          aws_s3_bucket.receipt_uploads.arn,
          "${aws_s3_bucket.receipt_uploads.arn}/*"
        ]
      }
    ]
  })
}

# 附加 S3 讀取權限到 Lambda 執行角色
resource "aws_iam_role_policy_attachment" "lambda_s3" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_s3_read.arn
}

# 附加 CloudWatch Logs 權限（Lambda 寫入日誌必須）
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}