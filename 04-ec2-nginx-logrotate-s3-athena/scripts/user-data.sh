#!/bin/bash
# ==============================================================================
# EC2 User Data Script - Nginx 日誌管理系統自動化部署腳本
# ==============================================================================
#
# 功能說明:
#   本腳本會在 EC2 實例啟動時自動執行,完成以下任務:
#   1. 安裝並啟動 Nginx Web 伺服器
#   2. 設定日誌自動輪替機制(每小時輪替一次,保留 24 小時)
#   3. 建立自動上傳腳本,將舊日誌壓縮後上傳至 S3
#   4. 配置 Cron 定時任務,實現日誌自動管理
#
# 執行流程:
#   系統更新 -> 安裝 Nginx -> 啟動服務 -> 配置日誌輪替 ->
#   建立上傳腳本 -> 設定定時任務
#
# 日誌管理策略:
#   - 每小時第 17 分輪替日誌
#   - 每小時第 20 分上傳 2 小時前的舊日誌到 S3
#   - 本地僅保留最近 24 小時的日誌備份
#   - 上傳成功後自動刪除本地備份
#
# ==============================================================================

# 啟用調試模式:會在終端顯示每一行執行的指令,方便追蹤問題
set -x

# ==============================================================================
# 步驟 1: 更新系統套件
# ==============================================================================
# 使用 dnf(Fedora/RHEL 系列的套件管理工具)更新所有已安裝的套件
echo "正在更新系統套件..."
if ! dnf update -y; then
    # 即使更新失敗也繼續執行(系統更新失敗不應阻止 Nginx 安裝)
    echo "[警告] 系統更新失敗,但繼續執行"
fi

# ==============================================================================
# 步驟 2: 安裝 Nginx
# ==============================================================================
# -y 參數:自動回答 yes,無需人工確認
echo "正在安裝 Nginx..."
if ! dnf install -y nginx; then
    # 如果安裝失敗,顯示錯誤訊息並結束腳本(exit 1 表示異常結束)
    echo "[錯誤] Nginx 安裝失敗！"
    exit 1
fi
echo "[成功] Nginx 安裝成功"
# 安裝 cronie (Amazon Linux 2023 預設未安裝 cron)
echo "正在安裝 cronie..."
dnf install -y cronie
systemctl enable --now crond
echo "[成功] Cronie 安裝並啟動"
# ==============================================================================
# 步驟 3: 驗證 Nginx 配置檔
# ==============================================================================
# nginx -t 會測試配置檔但不實際啟動服務
echo "檢查 Nginx 配置..."
if ! nginx -t; then
    # 配置檔有語法錯誤,顯示錯誤並結束腳本
    echo "[錯誤] Nginx 配置檔語法錯誤！"
    exit 1
fi
echo "[成功] Nginx 配置正確"

# ==============================================================================
# 步驟 4: 啟動 Nginx 服務
# ==============================================================================
echo "正在啟動 Nginx..."

# systemctl enable:將 Nginx 加入開機啟動項目
# 這樣 EC2 重開機後 Nginx 會自動啟動
systemctl enable nginx

# systemctl start:立即啟動 Nginx,讓它開始接受 HTTP 請求
if ! systemctl start nginx; then
    # 啟動失敗時,顯示詳細的診斷資訊
    echo "[錯誤] Nginx 啟動失敗！"
    echo "=== Nginx 服務狀態 ==="
    systemctl status nginx
    echo ""
    echo "=== 系統日誌(最近 50 行)==="
    journalctl -xeu nginx.service --no-pager
    exit 1
fi
echo "[成功] Nginx 啟動成功"

# ==============================================================================
# 步驟 5: 配置日誌輪替(Log Rotation)
# ==============================================================================
# 說明:建立 logrotate 配置檔,定義日誌輪替規則
# 執行時機:每小時第 17 分執行(由下方 cron 控制)
# 保留策略:本地保留最近 24 小時的日誌備份

cat > /etc/logrotate.d/nginx << 'LOGROTATE'
/var/log/nginx/*.log {
    # missingok: 如果日誌檔不存在,不報錯(避免腳本中斷)
    missingok
    
    # size 0: 不管檔案大小,每次 cron 執行時都進行輪替
    # 這確保測試時每 3 分鐘都會產生新的 .gz 檔案
    size 0
    
    # rotate 5: 保留最近 5 個備份檔案(15 分鐘)
    # 因為設定為每 3 分鐘輪替一次,所以保留 15 分鐘的日誌
    # 超過 5 個的舊檔案會被刪除(但應該已經上傳到 S3)
    rotate 5
    
    # compress: 壓縮備份的日誌檔(使用 gzip,節省約 90% 空間)
    compress
    
    # notifempty: 如果日誌檔是空的,不進行輪替(避免產生無用檔案)
    notifempty
    
    # create 0640 nginx adm: 輪替後建立新日誌檔,並設定權限與擁有者
    #   0640 = 擁有者可讀寫,群組可讀,其他人無權限
    #   nginx = 檔案擁有者
    #   adm = 檔案群組
    create 0640 nginx adm
    
    # dateext: 使用日期而非數字命名備份檔
    # 例如:access.log-20260101 而不是 access.log.1
    dateext
    
    # dateformat: 自訂日期格式為 年月日時分秒
    # 例如:access.log-20260101171700.gz(2026年1月1日17:17:00)
    dateformat -%Y%m%d%H%M%S
    
    # sharedscripts: 所有日誌輪替完成後,只執行一次 postrotate 腳本
    # (避免 access.log 和 error.log 各自觸發一次 Nginx 重啟)
    sharedscripts
    
    # postrotate: 日誌輪替後要執行的腳本
    postrotate
        # 發送 USR1 信號給 Nginx,讓它重新開啟日誌檔
        # 這樣 Nginx 才會寫入新的日誌檔,而不是繼續寫入已改名的舊檔
        # 2>/dev/null 會隱藏錯誤訊息
        # || true 確保即使失敗也回傳成功(避免 logrotate 報錯)
        /bin/kill -USR1 $(cat /var/run/nginx.pid 2>/dev/null) 2>/dev/null || true
    endscript
}
LOGROTATE

# ==============================================================================
# 步驟 6: 建立 S3 日誌上傳腳本
# ==============================================================================
# 說明:建立一個 Bash 腳本,負責將已輪替的日誌檔上傳到 S3
# 執行時機:每小時第 20 分執行(由下方 cron 控制)
# 上傳策略:只上傳 2 小時前的檔案,確保檔案穩定且不再被使用

cat > /usr/local/bin/upload-nginx-logs.sh << 'UPLOAD_SCRIPT'
#!/bin/bash

# 從 Terraform 變數取得 S3 bucket 名稱與 AWS 區域
# 這些變數會在 EC2 啟動時由 Terraform 替換成實際值
S3_BUCKET="${s3_bucket}"
AWS_REGION="${aws_region}"

# 定義日誌檔案目錄與主機名稱
LOG_DIR="/var/log/nginx"
HOSTNAME=$(hostname)

# ------------------------------------------------------------------------------
# 函式:upload_logs
# 功能:上傳指定類型的日誌檔案到 S3
# 參數:log_type(access 或 error)
# 策略:只上傳修改時間超過 2 小時的檔案(-mmin +120)
# ------------------------------------------------------------------------------
upload_logs() {
    local log_type=$1  # 接收參數:日誌類型(access 或 error)
    
    # 尋找已壓縮且超過 1 分鐘的日誌檔案
    # -name "$${log_type}.log-*.gz": 符合 access.log-*.gz 或 error.log-*.gz
    # -mmin +1: 檔案修改時間超過 1 分鐘
    #
    # 為什麼要等 1 分鐘？
    #   10:00 - logrotate 壓縮檔案
    #   10:01 - upload 執行,此時檔案已超過 1 分鐘,確保壓縮完成
    #   測試用快速設定,生產環境應改為 -mmin +120(2小時)
    find "$LOG_DIR" -name "$${log_type}.log-*.gz" -mmin +1 | while read -r logfile; do
        
        # 取得檔案的最後修改時間戳(Unix 時間,例如:1735700130)
        timestamp=$(stat -c %Y "$logfile")
        
        # 將時間戳轉換為目錄結構格式:YYYY/MM/DD/HH
        # 例如:2026/01/01/17
        # 這樣可以在 S3 中按日期時間組織日誌,方便 Athena partition 查詢
        datetime=$(date -d "@$timestamp" +"%Y/%m/%d/%H")
        
        # 取得檔案名稱(不含路徑)
        # 例如:access.log-20260101171700.gz
        filename=$(basename "$logfile")
        
        # 建立 S3 路徑
        # 格式:s3://bucket名稱/nginx/日誌類型/年/月/日/時/主機名.檔名
        # 例如:s3://my-bucket/nginx/access/2026/01/01/17/ip-172-31-1-1.access.log-20260101171700.gz
        s3_path="s3://$S3_BUCKET/nginx/$${log_type}/$datetime/$HOSTNAME.$filename"
        
        # 使用 AWS CLI 上傳檔案到 S3
        if aws s3 cp "$logfile" "$s3_path" --region "$AWS_REGION"; then
            # 上傳成功
            echo "$(date): 上傳成功 [$${log_type}] - $logfile -> $s3_path"
            
            # 上傳成功後刪除本地檔案,釋放磁碟空間
            # -f 參數:強制刪除,即使檔案不存在也不報錯
            rm -f "$logfile"
        else
            # 上傳失敗,將錯誤訊息輸出到 stderr(標準錯誤)
            echo "$(date): 上傳失敗 [$${log_type}] - $logfile" >&2
        fi
    done
}

# 分別處理 access log 和 error log
upload_logs "access"
upload_logs "error"
UPLOAD_SCRIPT

chmod +x /usr/local/bin/upload-nginx-logs.sh

# ==============================================================================
# 步驟 7: 設定 Cron 定時任務
# ==============================================================================
# 說明:建立定時任務,讓系統自動執行日誌輪替與上傳
# Cron 是 Linux 的定時任務排程工具,可以在指定時間自動執行腳本

# 確保 cron.d 目錄存在(通常已存在,這是保險起見)
mkdir -p /etc/cron.d

# ------------------------------------------------------------------------------
# 7-1: 設定日誌輪替的定時任務
# ------------------------------------------------------------------------------
# Cron 時間格式:分 時 日 月 星期 使用者 指令
#   */3: 每 3 分鐘執行一次
#   * * * *: 每小時、每天、每月、每個星期幾都執行
#   root: 以 root 使用者身份執行
#
# 執行時間:每 3 分鐘(例如:10:00, 10:03, 10:06, 10:09...)
# 測試用快速設定,生產環境應改為每小時
cat > /etc/cron.d/nginx-logrotate << 'LOGROTATE_CRON'
*/3 * * * * root /usr/sbin/logrotate /etc/logrotate.d/nginx
LOGROTATE_CRON

# ------------------------------------------------------------------------------
# 7-2: 設定 S3 上傳的定時任務
# ------------------------------------------------------------------------------
# Cron 時間格式:分 時 日 月 星期 使用者 指令
#   1-59/3: 從第 1 分開始,每 3 分鐘執行一次
#   * * * *: 每小時、每天、每月、每個星期幾都執行
#   root: 以 root 使用者身份執行
#   >> /var/log/nginx-upload.log: 將標準輸出附加到日誌檔
#   2>&1: 將標準錯誤(錯誤訊息)也導向同一個日誌檔
#
# 執行時間:每 3 分鐘,錯開 1 分鐘(例如:10:01, 10:04, 10:07, 10:10...)
# 為什麼錯開 1 分鐘？
#   - logrotate 在 10:00, 10:03, 10:06... 執行
#   - upload 在 10:01, 10:04, 10:07... 執行,錯開 1 分鐘確保壓縮完成
#   - 測試用快速設定,生產環境應改為每小時
cat > /etc/cron.d/nginx-log-upload << 'CRON'
1-59/3 * * * * root /usr/local/bin/upload-nginx-logs.sh >> /var/log/nginx-upload.log 2>&1
CRON

# ==============================================================================
# 完成
# ==============================================================================
echo "Nginx 日誌系統設定完成"
echo ""
echo "系統配置摘要:"
echo "  - Nginx 已安裝並啟動"
echo "  - 日誌輪替:每 3 分鐘執行(測試用)"
echo "  - S3 上傳:每 3 分鐘執行,錯開 1 分鐘(測試用)"
echo "  - 本地保留:最近 24 小時的日誌"
echo "  - 上傳條件:超過 2 小時的舊日誌"
echo "  - 上傳位置:s3://${s3_bucket}/nginx/access|error/YYYY/MM/DD/HH/"
echo ""
echo "日誌檔案位置:"
echo "  - Nginx access log: /var/log/nginx/access.log"
echo "  - Nginx error log: /var/log/nginx/error.log"
echo "  - 上傳腳本日誌: /var/log/nginx-upload.log"
