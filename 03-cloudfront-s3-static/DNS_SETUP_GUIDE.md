# 自訂域名配置指南

**交付給客戶（歐哥）的操作手冊**

---

## 文件說明

此文件將指導您如何在自己的 AWS 帳號中，將公司的網域名稱（例如：www.yourcompany.com）指向我們為您部署的網站。

**預估操作時間：10-15 分鐘**

---

## 配置前需要知道的資訊

### 您的網站已部署在 CloudFront 上

我們已經為您建置好網站，目前可透過以下網址存取：

```
CloudFront 預設網址：d2b8l7w7kqv3yo.cloudfront.net
完整網址：https://d2b8l7w7kqv3yo.cloudfront.net/
```

這個網址是 AWS 自動產生的，看起來不夠專業。接下來我們要讓您使用自己公司的網域名稱來存取網站。

---

## 操作步驟

### 步驟 1：登入 AWS 管理控制台

1. 打開瀏覽器，前往 AWS 登入頁面
   ```
   https://console.aws.amazon.com/
   ```

2. 輸入您的帳號資訊：
   - **帳戶 ID**（12 位數字）
   - **使用者名稱**
   - **密碼**

3. 點擊「登入」

> **提示**：如果您不確定帳號資訊，請聯繫貴公司的 IT 部門

---

### 步驟 2：進入 Route53 服務

**Route53 是什麼？**
- 這是 AWS 的網域名稱管理服務（DNS 服務）
- 就像是網路世界的電話簿，負責把網域名稱轉換成實際的網站位置

**操作方式：**

1. 登入後，在頁面最上方找到「搜尋列」
   
2. 在搜尋框輸入：`Route53`

3. 點擊搜尋結果中的「Route53」服務

4. 您會看到 Route53 的主控制台頁面

> **畫面說明**：頂部會顯示「Route53」，左側有選單，包含「Hosted zones」等選項

---

### 步驟 3：選擇您的 Hosted Zone（託管區域）

**Hosted Zone 是什麼？**
- 這是您公司網域名稱的管理區域
- 例如：如果您的公司網域是 `mycompany.com`，就會有一個對應的 Hosted Zone

**操作方式：**

1. 在左側選單點擊「Hosted zones」（託管區域）

2. 您會看到一個列表，找到您公司的網域名稱
   ```
   例如：mycompany.com
   ```

3. 點擊該網域名稱進入

4. 進入後會看到現有的 DNS 記錄列表（通常已經有 NS 和 SOA 等記錄）

> **注意**：如果您看不到任何 Hosted Zone，表示您的網域可能不在這個 AWS 帳號中，請聯繫 IT 部門確認

---

### 步驟 4：建立新的 DNS 記錄

現在要建立一筆新記錄，讓您的網域指向我們部署的網站。

#### 方法 A：使用 A 記錄（Alias）- **強烈推薦**

這是最簡單且免費的方式。

**操作步驟：**

1. 點擊右上角的「Create record」（建立記錄）按鈕

2. 填寫以下欄位：

   **a. Record name（記錄名稱）**
   ```
   填寫：www
   ```
   - 這代表使用者會透過 `www.yourcompany.com` 存取網站
   - 如果想用其他名稱（例如 `app`），可以填 `app`（變成 `app.yourcompany.com`）
   - 如果要讓 `mycompany.com`（不加 www）直接存取，就留空白

   **b. Record type（記錄類型）**
   ```
   選擇：A - Routes traffic to an IPv4 address
   ```
   - 點擊下拉選單，選擇「A」開頭的那一項

   **c. Alias（別名）**
   ```
   勾選 ☑ 「Alias」
   ```
   - 這個很重要！一定要勾選
   - 勾選後畫面會改變

   **d. Route traffic to（流量路由到）**
   ```
   第一個下拉選單選擇：
   「Alias to CloudFront distribution」
   （別名到 CloudFront 分發）
   
   第二個欄位會出現您可以選擇的 CloudFront 網址：
   選擇：d2b8l7w7kqv3yo.cloudfront.net
   ```
   - 這是我們為您建立的 CloudFront 網址
   - 如果沒有出現，請手動輸入我們提供給您的 CloudFront 網址

   **e. Routing policy（路由政策）**
   ```
   選擇：Simple routing
   ```
   - 這是最基本的路由方式，適合大部分情況

3. 確認所有資訊無誤後，點擊右下角「Create records」（建立記錄）

4. 完成！您會看到新記錄出現在列表中

---

#### 方法 B：使用 CNAME 記錄（替代方案）

**什麼時候用這個方法？**
- 如果方法 A 遇到問題
- 或者您想使用子網域（例如：`blog.mycompany.com`）

**操作步驟：**

1. 點擊「Create record」（建立記錄）

2. 填寫以下欄位：

   **a. Record name（記錄名稱）**
   ```
   填寫：www 或 app
   ```
   - **注意**：CNAME 不能用在根網域（不能留空白）
   - 只能用 `www`、`app`、`blog` 等子網域

   **b. Record type（記錄類型）**
   ```
   選擇：CNAME
   ```

   **c. Value（值）**
   ```
   填寫：d2b8l7w7kqv3yo.cloudfront.net
   ```
   - 請複製貼上我們提供的 CloudFront 網址
   - **注意**：不要加 `https://` 或 `/`

   **d. TTL（Time to Live）**
   ```
   填寫：300
   ```
   - 這代表 5 分鐘，表示 DNS 記錄的快取時間

3. 點擊「Create records」（建立記錄）

---

### 步驟 5：等待 DNS 生效

**需要等多久？**
- 通常 5-10 分鐘即可生效
- 最多可能需要 24-48 小時（但很少見）

**如何確認是否生效？**

1. 打開瀏覽器

2. 在網址列輸入您配置的網域：
   ```
   http://www.yourcompany.com
   ```
   
3. 如果看到網站內容，表示配置成功！

4. 如果看到錯誤訊息，請稍等 10 分鐘後再試一次

---

## HTTPS（安全連線）說明

### 目前狀態

配置完成後，您會發現：
- `http://www.yourcompany.com` 可以存取
- `https://www.yourcompany.com` 會出現憑證警告

### 為什麼？

因為還需要額外配置 **SSL 憑證**，才能使用 HTTPS（安全連線）。

### 如何啟用 HTTPS？

**請聯繫我們，我們會協助您：**
1. 在 AWS Certificate Manager（ACM）申請免費 SSL 憑證
2. 驗證網域所有權（需要您配合新增一筆 DNS 記錄）
3. 將憑證綁定到 CloudFront
4. 完成後即可使用 `https://` 存取

**預估時間：30 分鐘 - 1 小時**

---

## 配置範例總結

### 範例 1：使用 www.mycompany.com

```
Record name: www
Record type: A (Alias)
Alias:       ☑ Yes
Route to:    CloudFront distribution
             d2b8l7w7kqv3yo.cloudfront.net
```

**結果**：使用者可透過 `www.mycompany.com` 存取網站

---

### 範例 2：使用 app.mycompany.com

```
Record name: app
Record type: A (Alias)
Alias:       ☑ Yes
Route to:    CloudFront distribution
             d2b8l7w7kqv3yo.cloudfront.net
```

**結果**：使用者可透過 `app.mycompany.com` 存取網站

---

### 範例 3：同時支援根網域和 www

需要建立**兩筆記錄**：

**記錄 1（根網域）：**
```
Record name: （留空）
Record type: A (Alias)
Alias:       ☑ Yes
Route to:    CloudFront distribution
```

**記錄 2（www）：**
```
Record name: www
Record type: A (Alias)
Alias:       ☑ Yes
Route to:    CloudFront distribution
```

**結果**：
- `mycompany.com`
- `www.mycompany.com`

---

## 常見問題

### Q1：我找不到 Hosted Zone 怎麼辦？

**A：** 有幾種可能：
1. 您的網域不在這個 AWS 帳號中
2. 網域在其他服務商（例如 GoDaddy、Namecheap）
3. 需要請 IT 部門協助確認

**解決方式**：
- 確認網域註冊商
- 如果網域在其他地方，需要將 NS（Name Server）記錄指向 Route53

---

### Q2：配置後網站顯示 404 或無法存取

**可能原因：**
1. DNS 尚未生效（請等待 10-30 分鐘）
2. CloudFront 網址填寫錯誤
3. 網站尚未部署完成

**解決方式：**
1. 確認填寫的 CloudFront 網址正確
2. 先用 CloudFront 預設網址測試是否能存取
3. 清除瀏覽器快取後再試
4. 聯繫我們協助排查

---

### Q3：配置後出現「憑證錯誤」或「不安全」警告

**原因：**
- 這是正常的！因為尚未配置 SSL 憑證

**解決方式：**
- 暫時使用 `http://` 而非 `https://` 存取
- 或聯繫我們協助配置 SSL 憑證（免費）

---

### Q4：我可以同時使用多個網域名稱嗎？

**A：** 可以！
- 您可以建立多筆記錄，例如：
  - `www.mycompany.com`
  - `app.mycompany.com`
  - `demo.mycompany.com`
- 只要重複「步驟 4」，改變 Record name 即可

---

### Q5：如何刪除或修改 DNS 記錄？

**刪除記錄：**
1. 在 Hosted Zone 中找到該記錄
2. 勾選該記錄
3. 點擊「Delete record」

**修改記錄：**
1. 勾選該記錄
2. 點擊「Edit record」
3. 修改後點擊「Save」

---

## 需要協助？

如果在配置過程中遇到任何問題，歡迎隨時聯繫我們：

- **技術支援 Email**：support@example.com
- **專案負責人**：[您的姓名]
- **電話**：[聯絡電話]

---

## 配置檢查清單

完成配置後，請確認以下項目：

- [ ] 已登入 AWS Console
- [ ] 已進入 Route53 服務
- [ ] 已找到正確的 Hosted Zone
- [ ] 已建立 DNS 記錄（A 記錄或 CNAME）
- [ ] 已填寫正確的 CloudFront 網址
- [ ] 已等待 DNS 生效（10-30 分鐘）
- [ ] 已測試網站是否可以存取
- [ ] （可選）已申請 SSL 憑證啟用 HTTPS

---

## 附件資訊

**您的網站資訊：**
- CloudFront 網址：`d2b8l7w7kqv3yo.cloudfront.net`
- 完整測試網址：`https://d2b8l7w7kqv3yo.cloudfront.net/`
- 建議使用網域：`www.yourcompany.com`（請依實際需求填入）
- 部署日期：`2025-12-20`
- 專案聯絡人：`_____________________`（請填入）

---

**文件版本**：v1.0  
**最後更新**：2025-12-20  
**適用對象**：非技術背景的客戶

---

© 2025 CloudFront + S3 靜態網站部署專案
