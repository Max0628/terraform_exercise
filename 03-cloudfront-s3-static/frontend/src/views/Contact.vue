<template>
  <div class="contact">
    <div class="header">
      <h1>📞 聯絡資訊</h1>
      <p>有問題或建議？歡迎聯絡我們！</p>
    </div>

    <div class="content">
      <div class="contact-cards">
        <div class="card">
          <div class="card-icon">💼</div>
          <h3>專案資訊</h3>
          <div class="info-item">
            <strong>專案名稱：</strong>
            <span>CloudFront + S3 靜態網站部署</span>
          </div>
          <div class="info-item">
            <strong>技術棧：</strong>
            <span>Vue 3, Vite, Terraform, AWS</span>
          </div>
          <div class="info-item">
            <strong>部署方式：</strong>
            <span>GitHub Actions CI/CD</span>
          </div>
        </div>

        <div class="card">
          <div class="card-icon">🔗</div>
          <h3>相關連結</h3>
          <div class="link-item">
            <a href="https://github.com" target="_blank" rel="noopener">
              <span class="link-icon">🐙</span>
              GitHub Repository
            </a>
          </div>
          <div class="link-item">
            <a href="https://aws.amazon.com/cloudfront/" target="_blank" rel="noopener">
              <span class="link-icon">☁️</span>
              AWS CloudFront 文件
            </a>
          </div>
          <div class="link-item">
            <a href="https://vuejs.org" target="_blank" rel="noopener">
              <span class="link-icon">💚</span>
              Vue.js 官方網站
            </a>
          </div>
          <div class="link-item">
            <a href="https://vitejs.dev" target="_blank" rel="noopener">
              <span class="link-icon">⚡</span>
              Vite 官方網站
            </a>
          </div>
        </div>

        <div class="card">
          <div class="card-icon">📧</div>
          <h3>技術支援</h3>
          <div class="info-item">
            <strong>Email：</strong>
            <span>support@example.com</span>
          </div>
          <div class="info-item">
            <strong>文件：</strong>
            <span>請參考專案 README.md</span>
          </div>
          <div class="info-item">
            <strong>問題回報：</strong>
            <span>GitHub Issues</span>
          </div>
        </div>
      </div>

      <div class="deployment-info">
        <h2>🚀 部署資訊</h2>
        <div class="deployment-steps">
          <div class="step">
            <div class="step-number">1</div>
            <div class="step-content">
              <h4>開發</h4>
              <p>使用 Vue 3 + Vite 開發前端應用</p>
              <code>npm run dev</code>
            </div>
          </div>
          <div class="step">
            <div class="step-number">2</div>
            <div class="step-content">
              <h4>編譯</h4>
              <p>建置生產版本的靜態檔案</p>
              <code>npm run build</code>
            </div>
          </div>
          <div class="step">
            <div class="step-number">3</div>
            <div class="step-content">
              <h4>部署</h4>
              <p>GitHub Actions 自動上傳到 S3</p>
              <code>aws s3 sync dist/ s3://bucket/</code>
            </div>
          </div>
          <div class="step">
            <div class="step-number">4</div>
            <div class="step-content">
              <h4>清除快取</h4>
              <p>CloudFront 快取失效</p>
              <code>aws cloudfront create-invalidation</code>
            </div>
          </div>
        </div>
      </div>

      <div class="faq">
        <h2>❓ 常見問題</h2>
        <details>
          <summary>為什麼選擇 CloudFront + S3？</summary>
          <p>CloudFront 提供全球 CDN 加速，大幅降低資料傳輸成本（節省 87%），並且提供 HTTPS、DDoS 防護等安全功能。</p>
        </details>
        <details>
          <summary>OAC 和 OAI 有什麼差別？</summary>
          <p>OAC (Origin Access Control) 是新一代的權限控管方式，支援更多 S3 功能（如 SSE-KMS 加密），AWS 官方建議使用 OAC 取代舊的 OAI。</p>
        </details>
        <details>
          <summary>如何觸發自動部署？</summary>
          <p>只要將程式碼推送到 GitHub 的 main 或 dev 分支，GitHub Actions 會自動執行編譯、上傳 S3、清除 CloudFront 快取。</p>
        </details>
        <details>
          <summary>Bucket Policy 和 ACL 的差別？</summary>
          <p>Bucket Policy 是基於資源的策略（推薦），可以精細控制權限；ACL 是較舊的方式，功能較少。AWS 建議優先使用 Bucket Policy。</p>
        </details>
      </div>
    </div>
  </div>
</template>

<script setup>
</script>

<style scoped>
.contact {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

.header {
  text-align: center;
  padding: 40px 20px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border-radius: 20px;
  margin-bottom: 40px;
  box-shadow: 0 10px 30px rgba(0,0,0,0.2);
}

.header h1 {
  font-size: 2.5em;
  margin-bottom: 10px;
}

.content {
  display: flex;
  flex-direction: column;
  gap: 30px;
}

.contact-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 30px;
}

.card {
  background: white;
  padding: 30px;
  border-radius: 15px;
  box-shadow: 0 5px 15px rgba(0,0,0,0.1);
  transition: transform 0.3s;
}

.card:hover {
  transform: translateY(-5px);
}

.card-icon {
  font-size: 3em;
  text-align: center;
  margin-bottom: 20px;
}

.card h3 {
  color: #667eea;
  margin-bottom: 20px;
  text-align: center;
}

.info-item {
  margin-bottom: 15px;
  line-height: 1.6;
}

.info-item strong {
  color: #333;
  display: inline-block;
  min-width: 100px;
}

.link-item {
  margin-bottom: 12px;
}

.link-item a {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px;
  background: #f8f9ff;
  border-radius: 8px;
  text-decoration: none;
  color: #667eea;
  transition: all 0.3s;
}

.link-item a:hover {
  background: #667eea;
  color: white;
  transform: translateX(5px);
}

.link-icon {
  font-size: 1.2em;
}

.deployment-info {
  background: white;
  padding: 30px;
  border-radius: 15px;
  box-shadow: 0 5px 15px rgba(0,0,0,0.1);
}

.deployment-info h2 {
  color: #667eea;
  margin-bottom: 30px;
  text-align: center;
}

.deployment-steps {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 20px;
}

.step {
  background: #f8f9ff;
  padding: 20px;
  border-radius: 10px;
  border-left: 4px solid #667eea;
}

.step-number {
  width: 35px;
  height: 35px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border-radius: 50%;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-weight: bold;
  margin-bottom: 15px;
}

.step-content h4 {
  color: #333;
  margin-bottom: 8px;
}

.step-content p {
  color: #666;
  font-size: 0.9em;
  margin-bottom: 10px;
}

.step-content code {
  display: block;
  background: #2d2d2d;
  color: #a5d6ff;
  padding: 8px 12px;
  border-radius: 5px;
  font-size: 0.85em;
  overflow-x: auto;
}

.faq {
  background: white;
  padding: 30px;
  border-radius: 15px;
  box-shadow: 0 5px 15px rgba(0,0,0,0.1);
}

.faq h2 {
  color: #667eea;
  margin-bottom: 25px;
  text-align: center;
}

details {
  margin-bottom: 15px;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  overflow: hidden;
}

summary {
  padding: 15px 20px;
  background: #f8f9ff;
  cursor: pointer;
  font-weight: 500;
  color: #667eea;
  transition: background 0.3s;
}

summary:hover {
  background: #e8ecff;
}

details p {
  padding: 15px 20px;
  margin: 0;
  line-height: 1.6;
  color: #666;
}

@media (max-width: 768px) {
  .header h1 {
    font-size: 2em;
  }
  
  .deployment-steps {
    grid-template-columns: 1fr;
  }
}
</style>
