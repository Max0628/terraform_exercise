#!/bin/bash


# Gateway Endpoint 驗證腳本
#
# 功能：自動驗證 Gateway Endpoint 是否正常運作
# 使用：./verify-gateway-endpoint.sh


set -e

echo "=========================================="
echo "Gateway Endpoint 驗證測試"
echo "=========================================="
echo ""

# 取得 Terraform outputs
echo "取得部署資訊..."
INSTANCE_ID=$(cd .. && terraform output -raw ec2_instance_id 2>/dev/null)
S3_BUCKET=$(cd .. && terraform output -raw s3_bucket_name 2>/dev/null)
AWS_PROFILE=${AWS_PROFILE:-dev}

if [ -z "$INSTANCE_ID" ]; then
    echo "錯誤：無法取得 EC2 Instance ID"
    echo "請確認已執行 terraform apply"
    exit 1
fi

echo "Instance ID: $INSTANCE_ID"
echo "S3 Bucket: $S3_BUCKET"
echo ""

# 測試 1：S3 存取（應該成功）
echo "=========================================="
echo "測試 1：S3 存取測試（應該成功）"
echo "=========================================="

echo "透過 SSM 在 EC2 上測試 S3 存取..."
aws ssm send-command \
    --instance-ids "$INSTANCE_ID" \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=["aws s3 ls s3://'"$S3_BUCKET"'/ && echo \"S3 存取成功\" || echo \"S3 存取失敗\""]' \
    --profile "$AWS_PROFILE" \
    --output text \
    --query 'Command.CommandId' > /tmp/command_id.txt

COMMAND_ID=$(cat /tmp/command_id.txt)
echo "等待指令執行..."
sleep 5

# 取得執行結果
aws ssm get-command-invocation \
    --command-id "$COMMAND_ID" \
    --instance-id "$INSTANCE_ID" \
    --profile "$AWS_PROFILE" \
    --query 'StandardOutputContent' \
    --output text

echo ""

# 測試 2：外網存取（應該失敗）
echo "=========================================="
echo "測試 2：外網存取測試（應該失敗）"
echo "=========================================="

echo "測試外網連線（應該 timeout）..."
aws ssm send-command \
    --instance-ids "$INSTANCE_ID" \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=["timeout 5 curl -I https://www.google.com && echo \"外網可存取（異常）\" || echo \"外網無法存取（正常）\""]' \
    --profile "$AWS_PROFILE" \
    --output text \
    --query 'Command.CommandId' > /tmp/command_id2.txt

COMMAND_ID2=$(cat /tmp/command_id2.txt)
sleep 5

aws ssm get-command-invocation \
    --command-id "$COMMAND_ID2" \
    --instance-id "$INSTANCE_ID" \
    --profile "$AWS_PROFILE" \
    --query 'StandardOutputContent' \
    --output text

echo ""

# 測試 3：上傳檔案測試
echo "=========================================="
echo "測試 3：S3 上傳/下載測試"
echo "=========================================="

echo "📤 上傳測試檔案..."
aws ssm send-command \
    --instance-ids "$INSTANCE_ID" \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=["echo \"Test from Gateway Endpoint at $(date)\" > /tmp/test.txt && aws s3 cp /tmp/test.txt s3://'"$S3_BUCKET"'/test.txt && echo \"✅ 上傳成功\" || echo \"❌ 上傳失敗\""]' \
    --profile "$AWS_PROFILE" \
    --output text \
    --query 'Command.CommandId' > /tmp/command_id3.txt

COMMAND_ID3=$(cat /tmp/command_id3.txt)
sleep 5

aws ssm get-command-invocation \
    --command-id "$COMMAND_ID3" \
    --instance-id "$INSTANCE_ID" \
    --profile "$AWS_PROFILE" \
    --query 'StandardOutputContent' \
    --output text

echo ""

# 最終報告
echo "=========================================="
echo "驗證完成"
echo "=========================================="
echo ""
echo "驗證總結："
echo "1. S3 存取應該成功（透過 Gateway Endpoint）"
echo "2. 外網存取應該失敗（沒有 NAT Gateway）"
echo "3. S3 上傳應該成功"
echo ""
echo " 如果以上三項都符合預期，表示 Gateway Endpoint 運作正常！"
echo ""
echo " 提示："
echo "- 流量完全沒有走公網"
echo "- 不需要 NAT Gateway"
echo "- 完全免費"
echo ""
