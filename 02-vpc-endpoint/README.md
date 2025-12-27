# VPC Endpoint 使用場景

## 作業目標

理解並實作兩種 VPC Endpoint，學習在不走公網的情況下，讓 VPC 內的資源安全存取 AWS 服務。

---

## 問答題

### Q1: 為何需要用 VPC Endpoint？

#### **情境對比：沒有 VPC Endpoint vs 有 VPC Endpoint**

**傳統方式（沒有 VPC Endpoint）**：
```
Private EC2 (10.0.1.10)
    ↓
    需要存取 S3
    ↓
Private Route Table → NAT Gateway ($$$) → Internet Gateway
    ↓
    走公網到 S3 (aws.amazon.com)
    ↓
S3 Bucket
```

**問題**：
1. **費用高昂**：
   - NAT Gateway 費用：$0.045/小時 ≈ $32/月
   - 資料傳輸費：$0.045/GB
   - 例：每天傳 100GB = $135/月

2. **安全風險**：
   - 流量走公網，暴露在網際網路
   - 雖然有 HTTPS 加密，但仍有中間人攻擊風險

3. **效能較差**：
   - 需要經過 NAT Gateway 轉換
   - 走公網延遲較高

**使用 VPC Endpoint 後**：
```
Private EC2 (10.0.1.10)
    ↓
    需要存取 S3
    ↓
Private Route Table → VPC Endpoint (免費或便宜)
    ↓
    走 AWS 內部網路（PrivateLink）
    ↓
S3 Bucket
```

**優點**：
1. **大幅節省成本**：
   - Gateway Endpoint（S3/DynamoDB）：**完全免費**
   - Interface Endpoint：$0.01/小時 ≈ $7/月（比 NAT Gateway 便宜 78%）

2. **安全性提升**：
   - 流量完全不離開 AWS 網路
   - 可透過 Security Group 和 Bucket Policy 精確控制

3. **效能更好**：
   - 走 AWS 內部高速網路
   - 延遲更低、頻寬更高

#### **成本試算範例**

假設一個應用每月從 Private Subnet 傳輸 1TB 資料到 S3：

| 方案 | NAT Gateway | VPC Endpoint Gateway |
|------|-------------|---------------------|
| Endpoint 費用 | $32/月 | **免費** |
| 資料傳輸費 | $45/月 (1TB × $0.045) | **免費** |
| **總計** | **$77/月** | **$0/月** |

**結論：使用 Gateway Endpoint 每月省 $924（一年省 $11,088）**

---

### Q2: Gateway Endpoint 跟 Interface Endpoint 有什麼差別？

#### **技術架構差異**

| 比較項目 | Gateway Endpoint | Interface Endpoint |
|---------|-----------------|-------------------|
| **實作方式** | Route Table 路由 | ENI (Elastic Network Interface) |
| **呈現方式** | 路由規則（看不到實體） | 實體網卡（有 IP 位址） |
| **DNS 解析** | 解析到公網 IP（走 VPC 內部路由） | 解析到 VPC 內部 Private IP |
| **費用** | **免費** | $0.01/小時/AZ ≈ $7/月 |
| **支援服務** | **只有** S3, DynamoDB | 大部分 AWS 服務（100+） |
| **設定位置** | Route Table | Security Group + Subnet |

#### **詳細說明**

**Gateway Endpoint（以 S3 為例）**

1. **運作原理**：
   ```
   EC2 要存取 S3
   ↓ DNS 查詢 s3.amazonaws.com
   解析到：52.219.xxx.xxx（公網 IP）
   ↓ 查詢 Route Table
   發現：pl-xxxxx（S3 prefix list）→ vpce-gateway
   ↓ 實際走向
   流量被導向 VPC Endpoint，走 AWS 內部網路
   ```

2. **設定步驟**：
   - 建立 Gateway Endpoint
   - 關聯 Route Table
   - 自動新增路由：`pl-xxxxxx → vpce-xxxxx`

3. **優點**：
   - 完全免費
   - 設定簡單
   - 不佔用 IP 位址

4. **限制**：
   - 只支援 S3 和 DynamoDB
   - 無法用 Security Group 控制（只能用 Bucket Policy）

**Interface Endpoint（以 SQS 為例）**

1. **運作原理**：
   ```
   EC2 要存取 SQS
   ↓ DNS 查詢 sqs.ap-northeast-1.amazonaws.com
   Private DNS 啟用時：解析到 10.0.1.100（VPC 內部 IP）
   ↓ 直接連線
   流量透過 ENI 網卡，走 AWS PrivateLink
   ```

2. **設定步驟**：
   - 建立 Interface Endpoint
   - 選擇 Subnet（會在該 Subnet 建立 ENI）
   - 設定 Security Group（控制流量）
   - 啟用 Private DNS

3. **優點**：
   - 支援大多數 AWS 服務
   - 可用 Security Group 精確控制
   - Private DNS 無縫整合（不需修改程式碼）

4. **限制**：
   - 需要付費（$0.01/小時/AZ）
   - 佔用 Subnet IP 位址
   - 每個 AZ 需要一個 ENI

#### **何時使用哪種？**

```
需要存取 S3 或 DynamoDB？
    ├─ 是 → 用 Gateway Endpoint（免費）
    └─ 否 → 需要存取其他服務（SQS, Lambda, ECR 等）
           → 用 Interface Endpoint
```

---

### Q3: 使用時 VPC 內的設定是否有什麼限制？

#### **Gateway Endpoint 限制**

1. **VPC DNS 設定**：
   - 必須啟用 `enable_dns_support = true`
   - 必須啟用 `enable_dns_hostnames = true`

2. **Route Table 關聯**：
   - 必須將 Endpoint 關聯到正確的 Route Table
   - 如果 EC2 的 Route Table 沒關聯，流量會走 NAT Gateway

3. **Bucket Policy 設定**：
   - 必須設定 Bucket Policy 限制只能從 VPC Endpoint 存取
   - 否則仍可從公網存取

4. **不支援跨 Region**：
   - VPC Endpoint 只能存取同 Region 的 S3

#### **Interface Endpoint 限制**

1. **Subnet 要求**：
   - 必須有足夠的 IP 位址（每個 ENI 佔用一個）
   - 建議在每個 AZ 都建立（高可用性）

2. **Security Group 規則**：
   - 必須允許 HTTPS (443) 流量
   - 來源可設定為 EC2 的 Security Group

3. **Private DNS**：
   - 啟用 Private DNS 後，VPC 內的 DNS 查詢會自動解析到 Endpoint
   - 如果有自訂 DNS，可能需要調整

4. **網路 ACL**：
   - 如果有設定 Network ACL，需要允許對應流量

#### **通用限制**

```
必須做的事：
- VPC 啟用 DNS support 和 DNS hostnames
- 正確設定 Route Table（Gateway）或 Security Group（Interface）
- 設定 Bucket/Resource Policy 限制只能從 VPC Endpoint 存取

不能做的事：
- 跨 Region 存取（Endpoint 和服務必須同 Region）
- 跨 VPC 存取（除非設定 VPC Peering）
- 從 on-premises 透過 VPN/Direct Connect 存取（需要額外設定）
```

---

## 實作架構

### 架構一：S3 Gateway Endpoint

```
┌─────────────────── VPC (10.0.0.0/16) ──────────────────┐
│                                                         │
│  ┌────────────────────────────────────────────────┐   │
│  │  Private Subnet (10.0.1.0/24)                  │   │
│  │                                                 │   │
│  │    ┌──────────────┐                            │   │
│  │    │  Private EC2 │                            │   │
│  │    │  10.0.1.10   │                            │   │
│  │    └──────┬───────┘                            │   │
│  │           │                                     │   │
│  │           │ 存取 S3                             │   │
│  │           ↓                                     │   │
│  │    ┌──────────────┐                            │   │
│  │    │ Route Table  │                            │   │
│  │    │ pl-xxx → vpce│                            │   │
│  │    └──────┬───────┘                            │   │
│  └───────────┼──────────────────────────────────┘   │
│              │                                        │
│              ↓                                        │
│       ┌─────────────────┐                            │
│       │ VPC Gateway     │                            │
│       │ Endpoint        │ ───────→ S3 Bucket        │
│       │ (vpce-xxx)      │         (Private)          │
│       └─────────────────┘                            │
│                                                        │
└────────────────────────────────────────────────────────┘
```

**特點**：
- 不需要 NAT Gateway
- 完全免費
- 透過 Route Table 路由

### 架構二：SQS Interface Endpoint

```
┌─────────────────── VPC (10.0.0.0/16) ──────────────────┐
│                                                         │
│  ┌────────────────────────────────────────────────┐   │
│  │  Private Subnet (10.0.1.0/24)                  │   │
│  │                                                 │   │
│  │    ┌──────────────┐        ┌──────────────┐   │   │
│  │    │  Private EC2 │───────→│  ENI         │   │   │
│  │    │  10.0.1.10   │  HTTPS │  10.0.1.100  │   │   │
│  │    └──────────────┘        │  (Endpoint)  │   │   │
│  │                             └──────┬───────┘   │   │
│  └────────────────────────────────────┼───────────┘   │
│                                        │               │
│                                        │ Private DNS   │
│    sqs.ap-northeast-1.amazonaws.com   │ 解析到       │
│             ↓                          ↓               │
│          10.0.1.100 (VPC 內部)                        │
│                                                        │
│       ┌─────────────────┐                            │
│       │ VPC Interface   │                            │
│       │ Endpoint        │ ──→ AWS PrivateLink ──→   │
│       │ (vpce-svc-xxx)  │     SQS Service           │
│       └─────────────────┘                            │
│                                                        │
└────────────────────────────────────────────────────────┘
```

**特點**：
- 有實體 ENI 網卡（可看到 IP）
- 可用 Security Group 控制
- Private DNS 無縫整合

---

## 驗證重點（最關鍵！）

### **如何證明流量沒有走外網？**

這是作業的核心！以下提供多種驗證方法：

#### **方法一：檢查 Route Table**
```bash
# SSH 進入 Private EC2
# 查看路由
ip route show

# 應該看到：
# - 沒有 0.0.0.0/0 → NAT Gateway 的路由
# - 有 pl-xxxxx → vpce-gateway 的路由（Gateway Endpoint）
```

#### **方法二：VPC Flow Logs**
```bash
# 啟用 VPC Flow Logs
# 檢查日誌，流量應該：
# - 來源 IP：EC2 private IP
# - 目標 IP：S3 prefix list 或 Endpoint ENI IP
# - 不會出現 NAT Gateway IP
```

#### **方法三：Traceroute**
```bash
# 在 Private EC2 執行
traceroute s3.amazonaws.com

# Gateway Endpoint：只會看到 1 hop（直接到達）
# 沒有 NAT Gateway：不會看到 NAT Gateway IP
```

#### **方法四：測試斷開 NAT Gateway**
```bash
# 最直接的驗證方式：
# 1. 刪除 NAT Gateway 或移除 Route Table 中的 0.0.0.0/0 路由
# 2. 測試 S3/SQS 存取
# 3. 如果仍能存取 → 證明走 VPC Endpoint
# 4. 如果無法存取 google.com → 證明確實沒外網
```

---

## 子作業結構

- [gateway-endpoint/](./gateway-endpoint/) - S3 Gateway Endpoint 實作
- [interface-endpoint/](./interface-endpoint/) - SQS Interface Endpoint 實作

每個子作業都有：
- 完整的 Terraform 程式碼
- 驗證腳本（證明不走外網）
- 詳細的中文註解

---

## 學習目標總結

完成此作業後，你應該能夠：

1. **理解成本差異**：知道何時該用 VPC Endpoint 節省費用
2. **選擇正確類型**：Gateway vs Interface 的使用場景
3. **正確配置**：VPC DNS、Route Table、Security Group、Bucket Policy
4. **驗證流量路徑**：使用多種方法證明流量走私有網路
5. **安全最佳實踐**：Bucket Policy 限制只能從 VPC Endpoint 存取

---

## 參考資源

- [AWS VPC Endpoints 官方文件](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints.html)
- [Gateway Endpoints 說明](https://docs.aws.amazon.com/vpc/latest/privatelink/gateway-endpoints.html)
- [Interface Endpoints (AWS PrivateLink)](https://docs.aws.amazon.com/vpc/latest/privatelink/create-interface-endpoint.html)
- [VPC Endpoint Pricing](https://aws.amazon.com/privatelink/pricing/)
