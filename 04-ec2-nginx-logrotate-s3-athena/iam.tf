# IAM 角色 - EC2 使用
resource "aws_iam_role" "ec2_nginx" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# IAM 政策 - S3 上傳權限
resource "aws_iam_role_policy" "s3_upload" {
  name = "s3-upload-logs"
  role = aws_iam_role.ec2_nginx.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "${aws_s3_bucket.nginx_logs.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.nginx_logs.arn
      }
    ]
  })
}

# Instance Profile
resource "aws_iam_instance_profile" "ec2_nginx" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_nginx.name
}
