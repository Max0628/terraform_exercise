/**
 * Lambda Function - Discord Webhook Notifier
 *
 * 功能：當 S3 收到新檔案時，發送通知到 Discord
 *
 * 學習重點：
 * 1. Lambda Handler 函數結構：exports.handler = async (event, context)
 * 2. S3 Event 解析：從 event.Records 取得檔案資訊
 * 3. HTTP 請求：使用 Node.js 原生 https 模組呼叫 Discord Webhook
 * 4. 錯誤處理：正確的 try-catch 和日誌記錄
 */

const https = require('https');
const url = require('url');

/**
 * Lambda Handler 函數
 *
 * @param {Object} event - S3 事件物件（包含上傳檔案的資訊）
 * @param {Object} context - Lambda 執行環境資訊
 * @returns {Object} 回傳執行結果
 */
exports.handler = async (event, context) => {
  console.log('收到 S3 事件:', JSON.stringify(event, null, 2));

  // 從環境變數取得 Discord Webhook URL
  const webhookUrl = process.env.DISCORD_WEBHOOK_URL;
  const bucketName = process.env.S3_BUCKET_NAME;

  if (!webhookUrl) {
    console.error('錯誤：未設定 DISCORD_WEBHOOK_URL 環境變數');
    throw new Error('DISCORD_WEBHOOK_URL is not set');
  }

  try {
    // 解析 S3 事件（一次可能有多個檔案上傳）
    const results = await Promise.all(
      event.Records.map((record) =>
        processRecord(record, webhookUrl, bucketName),
      ),
    );

    console.log('所有通知發送完成:', results);

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: '通知發送成功',
        processed: results.length,
      }),
    };
  } catch (error) {
    console.error('處理失敗:', error);
    throw error;
  }
};

/**
 * 處理單一 S3 Record
 *
 * @param {Object} record - S3 事件記錄
 * @param {string} webhookUrl - Discord Webhook URL
 * @param {string} bucketName - S3 Bucket 名稱
 */
async function processRecord(record, webhookUrl, bucketName) {
  // 解析 S3 事件資訊
  const s3 = record.s3;
  const objectKey = decodeURIComponent(s3.object.key.replace(/\+/g, ' '));
  const objectSize = s3.object.size;
  const eventTime = record.eventTime;

  console.log('處理檔案:', {
    bucket: bucketName,
    key: objectKey,
    size: objectSize,
    time: eventTime,
  });

  // 建立 Discord 訊息內容
  const discordMessage = createDiscordMessage(
    objectKey,
    objectSize,
    eventTime,
    bucketName,
  );

  // 發送到 Discord
  return await sendToDiscord(webhookUrl, discordMessage);
}

/**
 * 建立 Discord 訊息內容
 *
 * Discord Webhook 支援 Embed 格式（更美觀）
 * 文件：https://discord.com/developers/docs/resources/webhook#execute-webhook
 */
function createDiscordMessage(fileName, fileSize, uploadTime, bucketName) {
  // 轉換檔案大小（Bytes → KB/MB）
  const sizeInKB = (fileSize / 1024).toFixed(2);
  const sizeDisplay =
    fileSize > 1024 * 1024
      ? `${(fileSize / 1024 / 1024).toFixed(2)} MB`
      : `${sizeInKB} KB`;

  // 判斷檔案類型（根據副檔名）
  const fileExtension = fileName.split('.').pop().toLowerCase();
  const fileType = getFileType(fileExtension);

  return {
    // 簡單文字訊息
    content: ' **新單據上傳通知**',

    // Embed 格式訊息（更豐富的格式）
    embeds: [
      {
        title: '會計系統 - 單據上傳通知',
        description: `有新的${fileType}單據已上傳至系統，請盡快處理。`,
        color: 0x00ff00, // 綠色
        fields: [
          {
            name: '檔案名稱',
            value: `\`${fileName}\``,
            inline: false,
          },
          {
            name: '檔案大小',
            value: sizeDisplay,
            inline: true,
          },
          {
            name: '上傳時間',
            value: new Date(uploadTime).toLocaleString('zh-TW', {
              timeZone: 'Asia/Taipei',
            }),
            inline: true,
          },
          {
            name: '儲存位置',
            value: `S3 Bucket: \`${bucketName}\``,
            inline: false,
          },
        ],
        footer: {
          text: '提示：請登入會計系統查看詳細內容',
        },
        timestamp: new Date().toISOString(),
      },
    ],
  };
}

/**
 * 判斷檔案類型
 */
function getFileType(extension) {
  const typeMap = {
    jpg: '圖片',
    jpeg: '圖片',
    png: '圖片',
    gif: '圖片',
    pdf: 'PDF',
    doc: 'Word',
    docx: 'Word',
    xls: 'Excel',
    xlsx: 'Excel',
  };
  return typeMap[extension] || '未知';
}

/**
 * 發送訊息到 Discord Webhook
 *
 * 使用 Node.js 原生 https 模組（不需要額外套件）
 *
 * @param {string} webhookUrl - Discord Webhook URL
 * @param {Object} message - 訊息內容
 */
function sendToDiscord(webhookUrl, message) {
  return new Promise((resolve, reject) => {
    // 解析 URL
    const parsedUrl = url.parse(webhookUrl);

    // 準備 HTTP POST 資料
    const postData = JSON.stringify(message);

    // 設定 HTTPS 請求選項
    const options = {
      hostname: parsedUrl.hostname,
      path: parsedUrl.path,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData),
      },
    };

    console.log('發送 Discord Webhook 請求...');

    // 發送 HTTPS 請求
    const req = https.request(options, (res) => {
      let responseBody = '';

      res.on('data', (chunk) => {
        responseBody += chunk;
      });

      res.on('end', () => {
        if (res.statusCode === 204 || res.statusCode === 200) {
          console.log('Discord 通知發送成功');
          resolve({ success: true, statusCode: res.statusCode });
        } else {
          console.error(' Discord API 回應錯誤:', res.statusCode, responseBody);
          reject(new Error(`Discord API error: ${res.statusCode}`));
        }
      });
    });

    req.on('error', (error) => {
      console.error(' HTTPS 請求失敗:', error);
      reject(error);
    });

    // 發送請求資料
    req.write(postData);
    req.end();
  });
}
