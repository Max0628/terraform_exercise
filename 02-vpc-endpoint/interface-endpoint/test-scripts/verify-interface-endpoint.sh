#!/bin/bash


# Interface Endpoint 驗證腳本
#
# 功能：自動驗證 Interface Endpoint 是否正常運作
# 使用：./verify-interface-endpoint.sh


set -e

echo "=========================================="
echo "🔍 Interface Endpoint 驗證測試"
echo "=========================================="
echo ""

# 取得 Terraform outputs
echo "📋 取得部署資訊..."
INSTANCE_ID=$(cd .. && terraform output -raw ec2_instance_id 2>/dev/null)
QUEUE_URL=$(cd .. && terraform output -raw sqs_queue_url 2>/dev/null)
AWS_REGION=${AWS_REGION:-ap-northeast-1}
AWS_PROFILE=${AWS_PROFILE:-dev}

if [ -z "$INSTANCE_ID" ]; then
    echo " 錯誤：無法取得 EC2 Instance ID"
    echo "請確認已執行 terraform apply"
    exit 1
fi

echo " Instance ID: $INSTANCE_ID"
echo " Queue URL: $QUEUE_URL"
echo ""

# 測試 1：DNS 解析
echo "=========================================="
echo "測試 1：DNS 解析（應該回應私有 IP）"
echo "=========================================="

echo " 查詢 SQS DNS..."
aws ssm send-command \
    --instance-ids "$INSTANCE_ID" \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=["nslookup sqs.'"$AWS_REGION"'.amazonaws.com | grep -A 2 \"Non-authoritative answer\" || nslookup sqs.'"$AWS_REGION"'.amazonaws.com"]' \
    --profile "$AWS_PROFILE" \
    --output text \
    --query 'Command.CommandId' > /tmp/command_id_dns.txt

COMMAND_ID=$(cat /tmp/command_id_dns.txt)
sleep 5

echo "  DNS 解析結果："
aws ssm get-command-invocation \
    --command-id "$COMMAND_ID" \
    --instance-id "$INSTANCE_ID" \
    --profile "$AWS_PROFILE" \
    --query 'StandardOutputContent' \
    --output text

echo ""
echo "💡 檢查重點：IP 應該是 10.0.x.x（私有 IP），不是 52.x.x.x（公網 IP）"
echo ""

# 測試 2：發送 SQS 訊息
echo "=========================================="
echo "測試 2：發送 SQS 訊息"
echo "=========================================="

echo " 發送測試訊息..."
aws ssm send-command \
    --instance-ids "$INSTANCE_ID" \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=["aws sqs send-message --queue-url '"$QUEUE_URL"' --message-body \"Test from Interface Endpoint at $(date)\" && echo \" 發送成功\" || echo \" 發送失敗\""]' \
    --profile "$AWS_PROFILE" \
    --output text \
    --query 'Command.CommandId' > /tmp/command_id_send.txt

COMMAND_ID=$(cat /tmp/command_id_send.txt)
sleep 5

aws ssm get-command-invocation \
    --command-id "$COMMAND_ID" \
    --instance-id "$INSTANCE_ID" \
    --profile "$AWS_PROFILE" \
    --query 'StandardOutputContent' \
    --output text

echo ""

# 測試 3：接收 SQS 訊息
echo "=========================================="
echo "測試 3：接收 SQS 訊息"
echo "=========================================="

echo " 接收訊息..."
aws ssm send-command \
    --instance-ids "$INSTANCE_ID" \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=["aws sqs receive-message --queue-url '"$QUEUE_URL"' --max-number-of-messages 1 && echo \" 接收成功\" || echo \" 接收失敗\""]' \
    --profile "$AWS_PROFILE" \
    --output text \
    --query 'Command.CommandId' > /tmp/command_id_receive.txt

COMMAND_ID=$(cat /tmp/command_id_receive.txt)
sleep 5

aws ssm get-command-invocation \
    --command-id "$COMMAND_ID" \
    --instance-id "$INSTANCE_ID" \
    --profile "$AWS_PROFILE" \
    --query 'StandardOutputContent' \
    --output text

echo ""

# 測試 4：外網連線（應該失敗）
echo "=========================================="
echo "測試 4：外網連線測試（應該 timeout）"
echo "=========================================="

echo " 測試外網連線..."
aws ssm send-command \
    --instance-ids "$INSTANCE_ID" \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=["timeout 5 curl -I https://www.google.com && echo \" 外網可存取（異常）\" || echo \" 外網無法存取（正常）\""]' \
    --profile "$AWS_PROFILE" \
    --output text \
    --query 'Command.CommandId' > /tmp/command_id_internet.txt

COMMAND_ID=$(cat /tmp/command_id_internet.txt)
sleep 5

aws ssm get-command-invocation \
    --command-id "$COMMAND_ID" \
    --instance-id "$INSTANCE_ID" \
    --profile "$AWS_PROFILE" \
    --query 'StandardOutputContent' \
    --output text

echo ""

# 測試 5：檢查 Route Table
echo "=========================================="
echo "測試 5：路由表檢查"
echo "=========================================="

echo " 查看路由表（應該只有 local，沒有 0.0.0.0/0）..."
aws ssm send-command \
    --instance-ids "$INSTANCE_ID" \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=["ip route show"]' \
    --profile "$AWS_PROFILE" \
    --output text \
    --query 'Command.CommandId' > /tmp/command_id_route.txt

COMMAND_ID=$(cat /tmp/command_id_route.txt)
sleep 5

aws ssm get-command-invocation \
    --command-id "$COMMAND_ID" \
    --instance-id "$INSTANCE_ID" \
    --profile "$AWS_PROFILE" \
    --query 'StandardOutputContent' \
    --output text

echo ""
echo " 檢查重點：不應該有 default via x.x.x.x（代表沒有預設路由到 NAT Gateway）"
echo ""

# 測試 6：檢查 Interface Endpoint ENI
echo "=========================================="
echo "測試 6：Interface Endpoint ENI 檢查"
echo "=========================================="

echo " 取得 Endpoint ENI 資訊..."
ENDPOINT_ID=$(cd .. && terraform output -raw interface_endpoint_id 2>/dev/null)

aws ec2 describe-network-interfaces \
    --filters "Name=vpc-endpoint-id,Values=$ENDPOINT_ID" \
    --profile "$AWS_PROFILE" \
    --query 'NetworkInterfaces[*].[NetworkInterfaceId,PrivateIpAddress,SubnetId,Status]' \
    --output table

echo ""

# 最終報告
echo "=========================================="
echo " 驗證完成"
echo "=========================================="
echo ""
echo " 驗證總結："
echo ""
echo "1. DNS 解析："
echo "    應該回應私有 IP（10.0.x.x）"
echo "    如果回應公網 IP（52.x.x.x），檢查 VPC DNS 設定"
echo ""
echo "2. SQS 存取："
echo "    發送和接收都應該成功"
echo "    如果失敗，檢查 Security Group 和 IAM 權限"
echo ""
echo "3. 外網存取："
echo "    應該 timeout（沒有 NAT Gateway）"
echo "    如果成功，檢查 Route Table 是否有誤"
echo ""
echo "4. 路由表："
echo "    只有 local 路由"
echo "    如果有 default via，代表有預設路由"
echo ""
echo "5. Interface Endpoint："
echo "    ENI 應該是 available 狀態"
echo "    私有 IP 應該在 Subnet CIDR 範圍內"
echo ""
echo " 如果以上都符合預期，恭喜！Interface Endpoint 運作正常！"
echo ""
echo " 學習重點回顧："
echo "- Interface Endpoint 透過 Private DNS 自動導向流量"
echo "- 不需要修改 Route Table（與 Gateway Endpoint 不同）"
echo "- 需要設定 Security Group（與 Gateway Endpoint 不同）"
echo "- 收費：$0.01/小時 + 資料傳輸費"
echo ""
