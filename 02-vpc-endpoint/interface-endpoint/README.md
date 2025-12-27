# Interface Endpoint 練習 - SQS

## 學習目標

本練習透過建立 SQS Interface Endpoint，學習：

1. **Interface Endpoint 與 Gateway Endpoint 的差異**
   - Interface Endpoint 是實體 ENI（Elastic Network Interface）
   - 有真實的私有 IP 位址
   - 收費：$0.01/小時 + 資料傳輸費
   
2. **Private DNS 運作原理**
   - 自動建立私有 DNS 記錄
   - 讓原本的 AWS 服務 URL 自動解析到 VPC 內的 IP
   
3. **Security Group 設定**
   - Interface Endpoint 需要設定 Security Group
   - 控制誰可以存取這個 Endpoint

## 架構說明

```
┌─────────────────────────────────────────────────────────┐
│                        VPC                              │
│                    10.0.0.0/16                          │
│                                                         │
│  ┌─────────────────────────────────────────────────┐  │
│  │         Private Subnet 10.0.16.0/20             │  │
│  │                                                 │  │
│  │  ┌──────────┐            ┌──────────────────┐  │  │
│  │  │ EC2      │──HTTPS────→│ Interface        │  │  │
│  │  │ Instance │   443      │ Endpoint (ENI)   │  │  │
│  │  │          │            │ 10.0.16.10       │──┼──┼──→ AWS SQS
│  │  └──────────┘            └──────────────────┘  │  │    (透過 PrivateLink)
│  │                                                 │  │
│  └─────────────────────────────────────────────────┘  │
│                                                         │
│  無 Internet Gateway                                │
│  無 NAT Gateway                                     │
└─────────────────────────────────────────────────────────┘
```

## Interface Endpoint 運作流程

### 1. DNS 解析（關鍵！）

**未啟用 Private DNS：**
```bash
$ nslookup sqs.ap-northeast-1.amazonaws.com
# 回應：52.95.xxx.xxx（公網 IP）
```

**啟用 Private DNS：**
```bash
$ nslookup sqs.ap-northeast-1.amazonaws.com
# 回應：10.0.16.10（VPC 內的私有 IP）
```

### 2. 流量路徑

```
EC2 發送訊息到 SQS
  ↓
DNS 查詢 sqs.ap-northeast-1.amazonaws.com
  ↓
Private DNS 回應：10.0.16.10（Endpoint ENI 的 IP）
  ↓
封包發送到 10.0.16.10
  ↓
通過 Security Group 檢查（需要允許 HTTPS 443）
  ↓
透過 AWS PrivateLink 到達 SQS 服務
  ↓
完全不經過公網
```

## 成本分析

### Interface Endpoint 費用

| 項目 | 費用 |
|------|------|
| Endpoint 費用 | $0.01/小時 = $7.2/月 |
| 資料傳輸費 | $0.01/GB |
| **總成本（估計）** | **$7.2/月 + 流量費** |

### 對比 NAT Gateway

| 方案 | 費用 |
|------|------|
| NAT Gateway | $32.4/月 + $0.045/GB |
| Interface Endpoint | $7.2/月 + $0.01/GB |
| **節省** | **$25.2/月 + 每 GB 省 $0.035** |

**成本優勢：**
- 固定成本省 78%
- 流量成本省 78%
- 如果有多個 AWS 服務，每個 Interface Endpoint 都要收費

## Interface Endpoint vs Gateway Endpoint

| 特性 | Gateway Endpoint | Interface Endpoint |
|------|-----------------|-------------------|
| **實體** | 虛擬（無 ENI） | 實體 ENI |
| **IP 位址** | 無 | 有私有 IP |
| **費用** | 免費 | $0.01/小時 |
| **支援服務** | 只有 S3、DynamoDB | 100+ AWS 服務 |
| **路由方式** | Route Table | Security Group |
| **Private DNS** | 不支援 | 支援 |
| **可用區** | VPC 層級 | 需要在每個 AZ |
| **Security Group** | 不需要 | 需要 |

## 部署步驟

### 1. 初始化

```bash
cd exercises/02-vpc-endpoint/interface-endpoint
terraform init
```

### 2. 部署

```bash
# 檢查執行計畫
terraform plan

# 部署
terraform apply
```

### 3. 驗證

```bash
# 自動驗證腳本
chmod +x test-scripts/verify-interface-endpoint.sh
./test-scripts/verify-interface-endpoint.sh

# 或手動驗證
# 1. 透過 SSM 連線到 EC2
aws ssm start-session \
  --target $(terraform output -raw ec2_instance_id) \
  --profile dev

# 2. 在 EC2 內測試 DNS 解析
nslookup sqs.ap-northeast-1.amazonaws.com
# 應該回應私有 IP（10.0.16.x）

# 3. 測試 SQS 傳送訊息
aws sqs send-message \
  --queue-url $(terraform output -raw sqs_queue_url) \
  --message-body "Test from Interface Endpoint"

# 4. 測試 SQS 接收訊息
aws sqs receive-message \
  --queue-url $(terraform output -raw sqs_queue_url)

# 5. 測試外網（應該失敗）
curl -I https://www.google.com
# 應該 timeout
```

## 驗證重點

### 成功指標

1. **DNS 解析到私有 IP**
   ```bash
   nslookup sqs.ap-northeast-1.amazonaws.com
   # 回應：10.0.16.x（私有 IP）
   ```

2. **SQS 操作成功**
   - 可以發送訊息
   - 可以接收訊息
   - 可以列出 Queue

3. **外網無法存取**
   ```bash
   curl https://www.google.com
   # 應該 timeout
   ```

### 失敗排查

1. **SQS 無法存取**
   - 檢查 Security Group 是否允許 HTTPS (443)
   - 檢查 IAM Role 是否有 SQS 權限
   - 檢查 Private DNS 是否啟用

2. **DNS 解析到公網 IP**
   - 確認 VPC 設定：enable_dns_support = true
   - 確認 VPC 設定：enable_dns_hostnames = true
   - 確認 Endpoint 設定：private_dns_enabled = true

## 學習重點總結

### 1. Private DNS 是關鍵

Interface Endpoint 最重要的功能是 **Private DNS**：
- 讓你的程式碼不需要修改
- 原本的 AWS SDK 呼叫自動走內網
- 只要修改 DNS 解析結果

### 2. Security Group 設定

Interface Endpoint 需要設定 Security Group：
- 允許來源：EC2 Security Group
- 允許 Port：443 (HTTPS)
- 不需要允許 Ingress（EC2 是發起者）

### 3. 成本考量

**何時使用 Interface Endpoint？**
- 需要存取多個 AWS 服務
- 資料傳輸量很大
- 需要額外的安全性

**何時使用 NAT Gateway？**
- 需要存取外網
- 只有少量 AWS 服務流量
- 需要固定的公網 IP

## 延伸學習

1. **Multi-AZ Interface Endpoint**
   - 每個 AZ 都需要建立一個 ENI
   - 成本會翻倍（2 AZ = $14.4/月）

2. **Endpoint Policy**
   - 可以限制只能存取特定的 SQS Queue
   - 額外的安全層

3. **PrivateLink**
   - Interface Endpoint 底層技術
   - 可以用來提供自己的服務給其他 VPC

## 下一步

完成本練習後，你可以：
1. 比較 Gateway Endpoint 和 Interface Endpoint 的實際差異
2. 實驗停用 Private DNS 看效果
3. 繼續作業三：CloudFront + S3 靜態網站
