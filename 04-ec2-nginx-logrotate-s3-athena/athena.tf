# Athena Workgroup
resource "aws_athena_workgroup" "nginx_logs" {
  name = "${var.project_name}-workgroup"

  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.id}/query-results/"
    }

    enforce_workgroup_configuration = true
  }

  tags = {
    Name = "${var.project_name}-workgroup"
  }
}

# Athena 資料庫
resource "aws_athena_database" "nginx_logs" {
  name   = replace("${var.project_name}_db", "-", "_")
  bucket = aws_s3_bucket.athena_results.id
}

# Athena 表 - Nginx Access Logs
resource "aws_athena_named_query" "create_access_logs_table" {
  name      = "create_nginx_access_logs_table"
  database  = aws_athena_database.nginx_logs.name
  workgroup = aws_athena_workgroup.nginx_logs.id

  query = <<-SQL
    CREATE EXTERNAL TABLE IF NOT EXISTS nginx_access_logs (
      client_ip STRING,
      identity STRING,
      user STRING,
      timestamp STRING,
      request STRING,
      status INT,
      bytes_sent BIGINT,
      referer STRING,
      user_agent STRING
    )
    ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.RegexSerDe'
    WITH SERDEPROPERTIES (
      'serialization.format' = '1',
      'input.regex' = '^(\\S+) (\\S+) (\\S+) \\[([^\\]]+)\\] "([^"]+)" (\\d+) (\\d+|-) "([^"]*)" "([^"]*)".*$'
    )
    LOCATION 's3://${aws_s3_bucket.nginx_logs.id}/nginx/access/'
    TBLPROPERTIES ('has_encrypted_data'='false');
  SQL
}

# Athena 表 - Nginx Error Logs
resource "aws_athena_named_query" "create_error_logs_table" {
  name      = "create_nginx_error_logs_table"
  database  = aws_athena_database.nginx_logs.name
  workgroup = aws_athena_workgroup.nginx_logs.id

  query = <<-SQL
    CREATE EXTERNAL TABLE IF NOT EXISTS nginx_error_logs (
      timestamp STRING,
      severity STRING,
      process_id STRING,
      thread_id STRING,
      connection_id STRING,
      message STRING
    )
    ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.RegexSerDe'
    WITH SERDEPROPERTIES (
      'serialization.format' = '1',
      'input.regex' = '^(\\d{4}/\\d{2}/\\d{2} \\d{2}:\\d{2}:\\d{2}) \\[(\\w+)\\] (\\d+)#(\\d+): (?:\\*(\\d+) )?(.*)$'
    )
    LOCATION 's3://${aws_s3_bucket.nginx_logs.id}/nginx/error/'
    TBLPROPERTIES ('has_encrypted_data'='false');
  SQL
}

# Athena 查詢範例 - 查詢特定 IP
resource "aws_athena_named_query" "query_by_ip" {
  name      = "query_nginx_by_ip"
  database  = aws_athena_database.nginx_logs.name
  workgroup = aws_athena_workgroup.nginx_logs.id

  query = <<-SQL
    SELECT 
      client_ip,
      timestamp,
      request,
      status,
      bytes_sent,
      user_agent
    FROM nginx_access_logs
    WHERE client_ip = '<IP_ADDRESS>'
    AND substr(timestamp, 1, 11) = '<DD/MMM/YYYY>'
    ORDER BY timestamp DESC
    LIMIT 100;
  SQL
}

# Athena 查詢範例 - 查詢 error log 特定嚴重性
resource "aws_athena_named_query" "query_errors_by_severity" {
  name      = "query_nginx_errors_by_severity"
  database  = aws_athena_database.nginx_logs.name
  workgroup = aws_athena_workgroup.nginx_logs.id

  query = <<-SQL
    SELECT 
      timestamp,
      severity,
      message
    FROM nginx_error_logs
    WHERE severity = '<SEVERITY>'
    AND substr(timestamp, 1, 10) = '<YYYY/MM/DD>'
    ORDER BY timestamp DESC
    LIMIT 100;
  SQL
}

# Athena 查詢範例 - 統計分析
resource "aws_athena_named_query" "hourly_stats" {
  name      = "nginx_hourly_stats"
  database  = aws_athena_database.nginx_logs.name
  workgroup = aws_athena_workgroup.nginx_logs.id

  query = <<-SQL
    SELECT 
      substr(timestamp, 1, 11) as date,
      substr(timestamp, 13, 2) as hour,
      COUNT(*) as total_requests,
      COUNT(DISTINCT client_ip) as unique_ips,
      AVG(bytes_sent) as avg_bytes,
      SUM(bytes_sent) as total_bytes
    FROM nginx_access_logs
    WHERE substr(timestamp, 1, 11) = '<DD/MMM/YYYY>'
    GROUP BY substr(timestamp, 1, 11), substr(timestamp, 13, 2)
    ORDER BY date, hour;
  SQL
}

