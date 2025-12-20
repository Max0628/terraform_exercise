
# SQS Queue - 測試用佇列
# 不需要特別設定就能透過 Interface Endpoint 存取

resource "aws_sqs_queue" "test_queue" {
  name = "${var.project_name}-test-queue"
  
  # 訊息保留時間（4 天）
  message_retention_seconds = 345600  # 4 days
  
  # 可見性超時（30 秒）
  visibility_timeout_seconds = 30
  
  # 最大訊息大小（256 KB）
  max_message_size = 262144
  
  # 接收等待時間（Long Polling，10 秒）
  receive_wait_time_seconds = 10
  
  tags = {
    Name = "${var.project_name}-test-queue"
  }
}