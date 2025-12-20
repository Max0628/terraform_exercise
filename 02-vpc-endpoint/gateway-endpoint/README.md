# S3 Gateway Endpoint 實作

## 🎯 目標

建立一個完全私有的環境，讓 Private Subnet 中的 EC2 可以透過 Gateway Endpoint 存取 S3，**完全不需要 NAT Gateway**，並驗證流量確實沒有走公網。

---

## 🏗️ 架構說明

```
VPC (10.0.0.0/16)
├── Private Subnet (10.0.16.0/20)
│   └── EC2 (有 Instance Profile 可存取 S3)
│
├── Route Table (Private)
│   ├── 10.0.0.0/16 → local
│   └── pl-xxxxx (S3 prefix list) → vpce-gateway
│
├── S3 Gateway Endpoint
│   └── 關聯到 Private Route Table
│
└── S3 Bucket (Private)
    └── Bucket Policy: 只允許從 VPC Endpoint 存取
```

**關鍵重點**：
- ❌ **沒有** Internet Gateway
- ❌ **沒有** NAT Gateway
- ❌ **沒有** Public Subnet
- ✅ **只有** Private Subnet + Gateway Endpoint

---

## 🚀 部署步驟

### 1. 初始化
```bash
cd exercises/02-vpc-endpoint/gateway-endpoint
terraform init
```

### 2. 查看計劃
```bash
terraform plan
```

### 3. 部署
```bash
terraform apply
```

### 4. 取得連線資訊
```bash
# 輸出 EC2 Instance ID
terraform output ec2_instance_id

# 輸出 S3 Bucket 名稱
terraform output s3_bucket_name
```

---

## 🧪 驗證測試

### **驗證一：透過 SSM Session Manager 連線**

由於 EC2 在 Private Subnet 且沒有 NAT Gateway，無法直接 SSH。使用 AWS Systems Manager Session Manager：

```bash
# 透過 SSM 連線（需要先建立 SSM VPC Endpoint 或用 AWS Console）
aws ssm start-session \
  --target $(terraform output -raw ec2_instance_id) \
  --profile dev
```

### **驗證二：測試 S3 存取（應該成功）**

在 EC2 內執行：
```bash
# 1. 列出 bucket
aws s3 ls s3://$(terraform output -raw s3_bucket_name)

# 2. 上傳測試檔案
echo "Hello from Private EC2 via Gateway Endpoint" > test.txt
aws s3 cp test.txt s3://$(terraform output -raw s3_bucket_name)/

# 3. 下載驗證
aws s3 cp s3://$(terraform output -raw s3_bucket_name)/test.txt - 

# ✅ 如果成功 → Gateway Endpoint 正常運作
```

### **驗證三：測試外網存取（應該失敗）**

```bash
# 測試無法存取外網（證明沒有 NAT Gateway）
curl -I https://www.google.com --max-time 10

# ❌ 應該會 timeout → 證明確實沒有外網
```

### **驗證四：檢查路由（關鍵證明！）**

```bash
# 在 EC2 內查看路由表
ip route show

# 應該只看到：
# 10.0.0.0/16 dev eth0 proto kernel scope link src 10.0.x.x
# 沒有 0.0.0.0/0 的預設路由 → 證明沒走 NAT Gateway

# 查看 DNS 解析
nslookup s3.amazonaws.com
# 會解析到公網 IP（這是正常的）

# 但實際流量會被 Route Table 導向 Gateway Endpoint
```

### **驗證五：VPC Flow Logs（進階）**

```bash
# 在 AWS Console 查看 VPC Flow Logs
# 篩選條件：
# - Source IP = EC2 private IP
# - Destination = S3 prefix list
# - Action = ACCEPT

# 應該會看到流量直接從 EC2 到 S3
# 不會經過任何 NAT Gateway IP
```

---

## 🔧 驗證腳本

提供自動化驗證腳本：

```bash
# 在本地執行（會透過 SSM 在 EC2 上執行測試）
./test-scripts/verify-gateway-endpoint.sh
```

腳本會自動測試：
1. ✅ S3 存取（應該成功）
2. ❌ 外網存取（應該失敗）
3. 📊 輸出驗證報告

---

## 🧹 清理資源

```bash
# 1. 刪除 S3 內的測試檔案
aws s3 rm s3://$(terraform output -raw s3_bucket_name) \
  --recursive \
  --profile dev

# 2. 刪除所有資源
terraform destroy
```

---

## 💡 學習重點

### 1. **Gateway Endpoint 完全免費**
   - 不像 NAT Gateway 需要 $32/月
   - 資料傳輸也免費
   - 適合大量 S3 存取的場景

### 2. **Route Table 自動路由**
   - Gateway Endpoint 會自動在 Route Table 加入路由
   - `pl-xxxxx → vpce-xxxxx`
   - 流量自動導向 Endpoint

### 3. **Bucket Policy 安全控制**
   - 限制只能從特定 VPC Endpoint 存取
   - 即使知道 Bucket 名稱，從外網也無法存取
   - 這是額外的安全層

### 4. **DNS 不變，路由改變**
   - `s3.amazonaws.com` 仍解析到公網 IP
   - 但 Route Table 會攔截流量
   - 應用程式不需要修改任何程式碼

---

## 🚨 常見問題

### Q: 為什麼 S3 的 DNS 還是解析到公網 IP？

A: 這是正常的！Gateway Endpoint 不改變 DNS 解析，而是透過 Route Table 路由攔截。流量路徑：
```
應用程式 → DNS 查詢（得到公網 IP）→ 發送請求
→ Route Table 檢查（發現 S3 prefix list）
→ 導向 Gateway Endpoint → 走 AWS 內部網路
```

### Q: 如何確定流量沒走 NAT Gateway？

A: 三種方法：
1. 刪除 NAT Gateway，S3 仍能存取（最直接）
2. 檢查 VPC Flow Logs，看不到 NAT Gateway IP
3. 檢查 Route Table，沒有 0.0.0.0/0 → NAT 的路由

### Q: 可以限制只有特定 EC2 存取 S3 嗎？

A: 可以！在 Bucket Policy 中使用條件：
```json
"Condition": {
  "StringEquals": {
    "aws:SourceVpce": "vpce-xxxxx",
    "aws:PrincipalArn": "arn:aws:iam::account:role/specific-role"
  }
}
```

---

## 📚 延伸思考

1. **如果 EC2 需要同時存取 S3 和外網怎麼辦？**
   - 可以同時有 Gateway Endpoint 和 NAT Gateway
   - Route Table 優先匹配 S3 prefix list → Gateway Endpoint
   - 其他流量走 0.0.0.0/0 → NAT Gateway

2. **Gateway Endpoint 有流量限制嗎？**
   - 沒有！可以無限使用
   - AWS 會自動擴展（Serverless）

3. **跨 Region 存取怎麼辦？**
   - Gateway Endpoint 只能存取同 Region 的 S3
   - 跨 Region 需要走公網（或使用 S3 Transfer Acceleration）
