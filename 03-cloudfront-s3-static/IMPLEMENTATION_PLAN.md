# API Gateway 前後端分流專案實作計畫

## 作業目標

將現有的純靜態網站（Vue SPA + CloudFront + S3）擴充為具備後端功能的全端應用，實現前後端分離架構。

### 核心要求

1. 使用 API Gateway 作為 API 入口進行請求分流
2. 使用 Lambda 處理後端業務邏輯（因流量不高）
3. 實作 Todolist 應用或任何可證明前後端互動的範例
4. 分流規則：
   - `/api/*` 路徑的請求導向 Lambda
   - 其他路徑導向原本的靜態網頁

---

## 架構設計

### 現有架構（靜態網站）

```
用戶瀏覽器
    |
CloudFront (CDN)
    |
S3 (靜態檔案：HTML/CSS/JS)
```

特性：
- 只有前端，無後端 API
- 資料寫死在程式碼中
- 無資料持久化

### 目標架構（Serverless 全端應用）

```
用戶瀏覽器
    |
CloudFront (統一入口 + 路徑分流)
    |
    +--- S3 (前端靜態檔案)
    |
    +--- API Gateway (API 入口)
            |
         Lambda (業務邏輯)
            |
         DynamoDB (資料儲存)
```

特性：
- 前後端分離
- Serverless 架構（按需付費）
- 資料持久化
- 單一網域（避免 CORS 問題）

---

## 技術選型

### 前端技術

- **框架**: Vue 3 (已有)
- **建置工具**: Vite 5
- **部署**: S3 + CloudFront
- **語言**: JavaScript

### 後端技術

- **API 閘道**: AWS API Gateway (HTTP API)
- **運算**: AWS Lambda (Node.js)
- **資料庫**: AWS DynamoDB
- **基礎設施**: Terraform

### 選型理由

#### 為什麼選 Lambda？
- 流量不高，按需付費更經濟
- 自動擴展，無需管理伺服器
- 冷啟動對低流量場景影響小

#### 為什麼選 API Gateway？
- Serverless 架構標配
- 比 ALB 便宜（低流量時）
- 整合 Lambda 簡單

#### 為什麼選 DynamoDB？
- Serverless 生態完美搭配
- 免費額度足夠（25 GB 儲存 + 2.5 億次讀寫/月）
- 零運維，自動擴展
- NoSQL 適合簡單資料結構

---

## 資料模型設計

### DynamoDB 表結構

**表名**: `todos`

**主鍵設計**:
- Partition Key: `id` (String)

**屬性**:
```
{
  id: string         // 主鍵，使用時間戳生成
  text: string       // Todo 內容
  done: boolean      // 是否完成
  createdAt: number  // 建立時間（timestamp）
}
```

**範例資料**:
```json
{
  "id": "1703145600000",
  "text": "學習 AWS Serverless 架構",
  "done": false,
  "createdAt": 1703145600000
}
```

---

## API 設計

### RESTful API 端點

| 方法 | 路徑 | 功能 | 請求 Body | 回應 |
|------|------|------|-----------|------|
| GET | /api/todos | 取得所有 todos | - | `{ todos: [...], count: 2 }` |
| POST | /api/todos | 建立新 todo | `{ text: "..." }` | `{ id, text, done, createdAt }` |
| PUT | /api/todos/:id | 更新 todo | `{ done: true }` | `{ success: true }` |
| DELETE | /api/todos/:id | 刪除 todo | - | 204 No Content |

### 請求與回應範例

**建立 Todo**:
```http
POST /api/todos
Content-Type: application/json

{
  "text": "完成 Terraform 作業"
}
```

回應:
```http
HTTP/1.1 201 Created
Content-Type: application/json

{
  "id": "1703145600000",
  "text": "完成 Terraform 作業",
  "done": false,
  "createdAt": 1703145600000
}
```

**取得所有 Todos**:
```http
GET /api/todos
```

回應:
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "todos": [
    {
      "id": "1703145600000",
      "text": "完成 Terraform 作業",
      "done": false,
      "createdAt": 1703145600000
    }
  ],
  "count": 1
}
```

---

## 資料流程

### 完整請求流程

1. **用戶操作**: 在瀏覽器中點擊「新增 Todo」
2. **前端發送請求**: `fetch('/api/todos', { method: 'POST', ... })`
3. **CloudFront 接收**: 判斷路徑 `/api/*`，轉發至 API Gateway origin
4. **API Gateway 路由**: 根據 `POST /todos` 路由至對應的 Lambda 整合
5. **Lambda 執行**: 
   - 解析請求 body
   - 產生唯一 ID
   - 調用 DynamoDB PutItem API
6. **DynamoDB 寫入**: 儲存資料並回應成功
7. **Lambda 回應**: 組裝 JSON 回應
8. **API Gateway 轉換**: 將 Lambda 回應轉為 HTTP 格式
9. **CloudFront 傳回**: 回傳給瀏覽器
10. **前端更新**: Vue 更新界面顯示新 Todo

### Lambda 與 DynamoDB 通訊機制

- **認證方式**: IAM Role（非用戶名密碼）
- **通訊方式**: AWS SDK
- **權限管理**: Terraform 配置 IAM Policy
- **自動處理**: 無需手動管理連線池

---

## 專案結構

```
03-cloudfront-s3-static/
├── main.tf                     # Terraform 主檔案
├── provider.tf                 # AWS Provider 配置
├── variables.tf                # 變數定義
├── outputs.tf                  # 輸出定義
├── terraform.tfvars.example    # 變數範例
│
├── s3.tf                       # S3 Bucket（前端）
├── cloudfront.tf               # CloudFront（需修改：新增 API origin）
├── api_gateway.tf              # API Gateway 配置（新增）
├── lambda.tf                   # Lambda 函數定義（新增）
├── dynamodb.tf                 # DynamoDB 表（新增）
├── iam.tf                      # IAM 角色與權限（新增）
│
├── acm.tf                      # SSL 憑證（保留）
├── DNS_SETUP_GUIDE.md          # DNS 設定指南（保留）
├── IMPLEMENTATION_PLAN.md      # 本文件
│
├── frontend/                   # 前端專案
│   ├── package.json
│   ├── vite.config.js
│   ├── index.html
│   └── src/
│       ├── main.js
│       ├── App.vue             # 需修改：新增 Todolist 導航
│       ├── router/
│       │   └── index.js        # 需修改：新增 /todos 路由
│       ├── views/
│       │   ├── Home.vue
│       │   ├── About.vue
│       │   ├── Contact.vue
│       │   └── TodoList.vue    # 新增：Todolist 頁面
│       └── api/
│           └── todoApi.js      # 新增：API 調用邏輯
│
└── lambda/                     # Lambda 函數（新增整個目錄）
    └── todos/
        ├── package.json        # Lambda 依賴
        ├── index.js            # Lambda Handler
        └── .gitignore          # 忽略 node_modules
```

---

## 實作階段規劃

### 階段 1: 保護現有版本

**目的**: 確保可以隨時回到純靜態版本

**步驟**:
1. 建立 Git tag: `v1.0-static-website`
2. 推送至遠端: `git push origin v1.0-static-website`

### 階段 2: 建立 DynamoDB 表

**目的**: 提供資料儲存層

**檔案**: 
- 新增 `dynamodb.tf`

**驗證**: 
- `terraform plan` 檢查計畫
- `terraform apply` 執行部署
- AWS Console 確認表建立成功

### 階段 3: 開發 Lambda 函數

**目的**: 實作後端業務邏輯

**檔案**:
- 新增 `lambda/todos/index.js`
- 新增 `lambda/todos/package.json`
- 新增 `lambda.tf`
- 新增 `iam.tf`

**功能實作順序**:
1. GET /todos（查詢所有）
2. POST /todos（建立）
3. DELETE /todos/:id（刪除）
4. PUT /todos/:id（更新）

**本地測試**:
- 在 Lambda 目錄執行 `npm install`
- 使用 AWS SAM 或 Lambda Console 測試

### 階段 4: 配置 API Gateway

**目的**: 提供 HTTP API 入口

**檔案**:
- 新增 `api_gateway.tf`

**配置內容**:
- 建立 HTTP API
- 配置 CORS
- 定義路由（GET/POST/PUT/DELETE /todos）
- 整合 Lambda

**驗證**:
- 使用 `curl` 測試 API 端點
- 確認回應格式正確

### 階段 5: 整合 CloudFront

**目的**: 實現路徑分流，統一前後端入口

**檔案**:
- 修改 `cloudfront.tf`

**修改內容**:
1. 新增第二個 origin（API Gateway）
2. 新增 `ordered_cache_behavior`（/api/* 路徑規則）
3. 配置不快取 API 回應

**注意事項**:
- CloudFront 更新需要 10-15 分鐘
- 測試路徑分流是否正確

### 階段 6: 前端整合

**目的**: 實作 Todolist 界面，調用後端 API

**檔案**:
- 新增 `frontend/src/api/todoApi.js`
- 新增 `frontend/src/views/TodoList.vue`
- 修改 `frontend/src/router/index.js`
- 修改 `frontend/src/App.vue`

**本地開發**:
```bash
cd frontend
npm run dev
```

**部署**:
```bash
npm run build
aws s3 sync dist/ s3://bucket-name/
```

### 階段 7: 完整測試與優化

**測試項目**:
- 路徑分流測試（/ vs /api/*）
- CRUD 功能測試
- 錯誤處理測試
- 跨瀏覽器測試

**優化項目**:
- 錯誤訊息優化
- 載入狀態顯示
- 使用者體驗改善

---

## Terraform 配置重點

### CloudFront 雙 Origin 配置

**關鍵修改**:
```hcl
# Origin 1: S3（前端靜態檔案）
origin {
  domain_name = aws_s3_bucket.website.bucket_regional_domain_name
  origin_id   = "S3-Frontend"
  # OAC 配置保持不變
}

# Origin 2: API Gateway（後端 API）
origin {
  domain_name = replace(aws_apigatewayv2_api.api.api_endpoint, "https://", "")
  origin_id   = "API-Backend"
  
  custom_origin_config {
    http_port              = 80
    https_port             = 443
    origin_protocol_policy = "https-only"
    origin_ssl_protocols   = ["TLSv1.2"]
  }
}
```

**路徑分流規則**:
```hcl
# 預設行為：所有請求 → S3
default_cache_behavior {
  target_origin_id = "S3-Frontend"
  # 其他配置保持不變
}

# /api/* 路徑 → API Gateway
ordered_cache_behavior {
  path_pattern     = "/api/*"
  target_origin_id = "API-Backend"
  
  allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
  cached_methods         = ["GET", "HEAD"]
  viewer_protocol_policy = "redirect-to-https"
  
  # 使用不快取的 cache policy
  cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
  origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
}
```

### IAM 權限配置

**Lambda 執行角色**:
- 基本執行權限（CloudWatch Logs）
- DynamoDB 存取權限（Scan, GetItem, PutItem, DeleteItem, UpdateItem）

**權限範圍**:
- 僅限存取 `todos` 表
- 遵循最小權限原則

---

## 前端實作重點

### API 調用模組

**關鍵考量**:
- 使用相對路徑 `/api/*`（不是絕對 URL）
- 統一錯誤處理
- 適當的 HTTP headers

**範例結構**:
```javascript
// todoApi.js
const API_BASE = '/api'

export async function getTodos() {
  const response = await fetch(`${API_BASE}/todos`)
  if (!response.ok) throw new Error('Failed to fetch')
  return response.json()
}
```

### Vue 組件設計

**狀態管理**:
- 使用 Vue 3 Composition API
- `ref` 管理 todos 陣列
- `onMounted` 載入初始資料

**用戶體驗**:
- 載入狀態顯示
- 錯誤訊息提示
- 操作回饋

---

## Lambda 實作重點

### 單一函數設計

**路由處理**:
- 根據 `event.requestContext.http.method` 判斷 HTTP 方法
- 根據 `event.rawPath` 判斷路徑
- 統一錯誤處理機制

### DynamoDB 操作

**常用操作**:
- `ScanCommand`: 查詢所有項目
- `GetCommand`: 查詢單一項目
- `PutCommand`: 建立/覆寫項目
- `DeleteCommand`: 刪除項目
- `UpdateCommand`: 更新項目

**錯誤處理**:
- Try-catch 包裹所有資料庫操作
- 適當的 HTTP 狀態碼
- 詳細的錯誤訊息

### CORS 配置

**必要的 Headers**:
```javascript
{
  'Access-Control-Allow-Origin': '*',
  'Content-Type': 'application/json'
}
```

---

## 部署流程

### 後端部署（Terraform）

```bash
# 1. 初始化（首次）
terraform init

# 2. 檢查變更
terraform plan

# 3. 執行部署
terraform apply

# 4. 確認輸出
terraform output
```

### 前端部署

```bash
# 1. 建置
cd frontend
npm install
npm run build

# 2. 上傳至 S3
aws s3 sync dist/ s3://your-bucket-name/ --delete

# 3. 清除 CloudFront 快取（如需要）
aws cloudfront create-invalidation \
  --distribution-id YOUR_DISTRIBUTION_ID \
  --paths "/*"
```

---

## 測試計畫

### 單元測試

**Lambda 函數測試**:
- 測試每個 HTTP 方法
- 測試錯誤情境
- 測試 DynamoDB 互動

**前端測試**:
- API 調用邏輯測試
- 組件渲染測試
- 用戶互動測試

### 整合測試

**端對端流程**:
1. 開啟網站首頁
2. 導航至 Todolist 頁面
3. 建立新 Todo
4. 確認顯示在列表
5. 更新 Todo 狀態
6. 刪除 Todo
7. 重新整理頁面，確認資料持久化

### 路徑分流測試

**測試案例**:
- `https://example.com/` → 應回傳 S3 的 index.html
- `https://example.com/about` → 應回傳 S3 的 index.html（Vue Router 處理）
- `https://example.com/api/todos` → 應回傳 Lambda 的 JSON
- `https://example.com/api/invalid` → 應回傳 404

---

## 成本估算

### 預期成本（每月，低流量情境）

**假設**:
- 每天 1000 次 API 請求
- 每月 30,000 次請求
- 每個請求平均 200ms
- Lambda 記憶體: 128 MB

**費用計算**:

1. **API Gateway**:
   - 30,000 次 × $1/100萬次 = $0.03

2. **Lambda**:
   - 請求費用: 免費（< 100萬次/月）
   - 執行費用: 免費（< 40萬 GB-秒/月）

3. **DynamoDB**:
   - 儲存: 免費（< 25 GB）
   - 讀寫: 免費（< 2.5億次/月）

4. **CloudFront**:
   - 資料傳輸: 約 $1-2/月（依實際使用）

5. **S3**:
   - 儲存: $0.50/月
   - 請求: $0.10/月

**總計**: 約 $2-5/月

**對比傳統架構**:
- EC2 t3.micro: $7.6/月
- RDS t3.micro: $12.4/月
- 總計: $20/月

**節省**: 75-85%

---

## 潛在問題與解決方案

### 問題 1: Lambda 冷啟動延遲

**現象**: 首次請求或長時間無請求後，回應時間 1-3 秒

**影響**: 低流量時經常發生

**解決方案**:
- 接受冷啟動（對低流量場景影響小）
- 若需改善：使用 Provisioned Concurrency（增加成本）

### 問題 2: CORS 錯誤

**現象**: 瀏覽器 Console 出現 CORS 錯誤

**原因**:
1. API Gateway 未正確配置 CORS
2. Lambda 回應缺少 CORS headers

**解決方案**:
- API Gateway 配置 `cors_configuration`
- Lambda 回應加入 `Access-Control-Allow-Origin` header

### 問題 3: CloudFront 快取導致 API 回應過時

**現象**: 更新資料後，GET 請求仍回傳舊資料

**原因**: CloudFront 快取了 API 回應

**解決方案**:
- 對 `/api/*` 使用不快取的 cache policy
- 或設定極短的 TTL（如 5 秒）

### 問題 4: DynamoDB 權限不足

**現象**: Lambda 執行時出現 `AccessDeniedException`

**原因**: IAM 角色缺少必要權限

**解決方案**:
- 檢查 `iam.tf` 配置
- 確認 Lambda 角色有正確的 DynamoDB 權限
- 確認 Resource ARN 正確

### 問題 5: API Gateway URL 格式錯誤

**現象**: CloudFront 無法連接到 API Gateway

**原因**: CloudFront origin 配置錯誤

**解決方案**:
- API Gateway endpoint 需移除 `https://` 前綴
- 使用 `replace()` 函數處理

---

## 參考資源

### AWS 官方文件

- API Gateway HTTP API: https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api.html
- Lambda 開發指南: https://docs.aws.amazon.com/lambda/latest/dg/welcome.html
- DynamoDB 開發指南: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/

### Terraform 資源文件

- `aws_apigatewayv2_api`: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_api
- `aws_lambda_function`: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function
- `aws_dynamodb_table`: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table

### AWS SDK 文件

- AWS SDK for JavaScript v3: https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/
- DynamoDB DocumentClient: https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/modules/_aws_sdk_lib_dynamodb.html

---

## 版本控制策略

### Git 分支管理

**主要分支**:
- `main`: 生產環境代碼
- `dev`: 開發分支（當前工作）

**Tag 策略**:
- `v1.0-static-website`: 純靜態網站版本（已完成）
- `v2.0-serverless-fullstack`: Serverless 全端版本（待完成）

### Commit 訊息規範

**格式**: `<type>(<scope>): <subject>`

**類型**:
- `feat`: 新功能
- `fix`: 錯誤修復
- `refactor`: 重構
- `docs`: 文件更新
- `chore`: 建置/工具變更

**範例**:
```
feat(lambda): 實作 GET /todos API
feat(frontend): 新增 Todolist 頁面
fix(api-gateway): 修正 CORS 配置
refactor(cloudfront): 重構 origin 配置為雙 origin
```

---

## 下一步行動

### 立即行動

1. 建立 Git tag 保護現有版本
2. 閱讀並確認本實作計畫
3. 開始階段 2：建立 DynamoDB 表

### 預期時程

- 階段 1: 15 分鐘
- 階段 2: 30 分鐘
- 階段 3: 2 小時
- 階段 4: 1 小時
- 階段 5: 1 小時（含 CloudFront 更新等待）
- 階段 6: 2 小時
- 階段 7: 1 小時

**總計**: 約 8 小時（可分多天完成）

---

## 學習目標

完成本專案後，應掌握以下技能：

### AWS Serverless 技術

- API Gateway HTTP API 配置與整合
- Lambda 函數開發與部署
- DynamoDB NoSQL 資料庫操作
- IAM 角色與權限管理
- CloudFront 多 origin 配置

### 架構設計

- Serverless 架構設計原則
- 前後端分離最佳實踐
- RESTful API 設計
- 單一網域整合（避免 CORS）

### 開發實務

- Terraform IaC 管理複雜架構
- AWS SDK 使用
- 錯誤處理與除錯
- 成本優化思維

### 專案管理

- 分階段實作策略
- Git 版本控制
- 文件撰寫
- 測試計畫制定
