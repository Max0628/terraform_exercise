# API Gateway HTTP API
resource "aws_apigatewayv2_api" "todos_api" {
  name          = "todos-api"
  protocol_type = "HTTP"
  description   = "HTTP API for Todos application"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token"]
    max_age       = 300
  }

  tags = {
    Name    = "Todos API Gateway"
    Project = "cloudfront-s3-static"
  }
}

# Lambda Integration
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id             = aws_apigatewayv2_api.todos_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.todos_api.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

# Route: GET /api/todos
resource "aws_apigatewayv2_route" "get_todos" {
  api_id    = aws_apigatewayv2_api.todos_api.id
  route_key = "GET /api/todos"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Route: POST /api/todos
resource "aws_apigatewayv2_route" "post_todos" {
  api_id    = aws_apigatewayv2_api.todos_api.id
  route_key = "POST /api/todos"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Route: PUT /api/todos/{id}
resource "aws_apigatewayv2_route" "put_todo" {
  api_id    = aws_apigatewayv2_api.todos_api.id
  route_key = "PUT /api/todos/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Route: DELETE /api/todos/{id}
resource "aws_apigatewayv2_route" "delete_todo" {
  api_id    = aws_apigatewayv2_api.todos_api.id
  route_key = "DELETE /api/todos/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Default Stage (auto-deploy)
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.todos_api.id
  name        = "$default"
  auto_deploy = true

  # 暫時註解 access logs（需要額外 IAM 權限）
  # access_log_settings {
  #   destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
  #   format = jsonencode({
  #     requestId      = "$context.requestId"
  #     ip             = "$context.identity.sourceIp"
  #     requestTime    = "$context.requestTime"
  #     httpMethod     = "$context.httpMethod"
  #     routeKey       = "$context.routeKey"
  #     status         = "$context.status"
  #     protocol       = "$context.protocol"
  #     responseLength = "$context.responseLength"
  #   })
  # }

  tags = {
    Name    = "Todos API Default Stage"
    Project = "cloudfront-s3-static"
  }
}

# CloudWatch Log Group for API Gateway（暫時註解，需要額外 IAM 權限）
# resource "aws_cloudwatch_log_group" "api_gateway_logs" {
#   name              = "/aws/apigateway/todos-api"
#   retention_in_days = 7
# 
#   tags = {
#     Name    = "API Gateway Logs"
#     Project = "cloudfront-s3-static"
#   }
# }

# Lambda Permission for API Gateway
resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.todos_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.todos_api.execution_arn}/*/*"
}
