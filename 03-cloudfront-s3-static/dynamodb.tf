# DynamoDB Table for Todos
resource "aws_dynamodb_table" "todos" {
  name         = "todos"
  billing_mode = "PAY_PER_REQUEST" # 按需計費模式，
  hash_key     = "id"              # 主鍵

  attribute {
    name = "id"
    type = "S" # String type
  }

  tags = {
    Name        = "Todos Table"
    Environment = "dev"
    Project     = "cloudfront-s3-static"
  }
}
