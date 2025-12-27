# DynamoDB Table for Todos
resource "aws_dynamodb_table" "todos" {
  name         = "todos"
  billing_mode = "PAY_PER_REQUEST" # On-demand pricing, no capacity planning needed
  hash_key     = "id"

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
