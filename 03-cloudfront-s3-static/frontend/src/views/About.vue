<template>
  <div class="about">
    <div class="header">
      <h1>關於此專案</h1>
      <p>使用 Terraform 部署的 Vue 3 靜態網站</p>
    </div>

    <div class="content">
      <section class="info-section">
        <h2>專案目標</h2>
        <p>本專案展示如何使用 Terraform 在 AWS 上建立一個安全、高效能的靜態網站部署架構。</p>
        <ul>
          <li>S3 儲存靜態網站資源（完全私有）</li>
          <li>CloudFront 作為 CDN 加速全球存取</li>
          <li>OAC (Origin Access Control) 確保安全性</li>
          <li>GitHub Actions 實現自動化 CI/CD</li>
        </ul>
      </section>

      <section class="info-section">
        <h2>安全性最佳實踐</h2>
        <div class="comparison">
          <div class="method">
            <h3>舊方法：OAI</h3>
            <p>Origin Access Identity</p>
            <ul>
              <li>較舊的權限控管方式</li>
              <li>功能較少</li>
              <li>AWS 建議棄用</li>
            </ul>
          </div>
          <div class="method highlight">
            <h3>新方法：OAC</h3>
            <p>Origin Access Control</p>
            <ul>
              <li>支援所有 S3 Bucket 類型</li>
              <li>支援 SSE-KMS 加密</li>
              <li>更精細的權限控管</li>
              <li>AWS 官方推薦</li>
            </ul>
          </div>
        </div>
      </section>

      <section class="info-section">
        <h2>成本分析</h2>
        <table class="cost-table">
          <thead>
            <tr>
              <th>項目</th>
              <th>月流量 1TB</th>
              <th>說明</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>直接從 S3 Public</td>
              <td class="cost">$118</td>
              <td>資料傳輸費用高</td>
            </tr>
            <tr class="highlight-row">
              <td>CloudFront + S3</td>
              <td class="cost-save">$15</td>
              <td>邊緣快取大幅降低成本</td>
            </tr>
          </tbody>
        </table>
        <p class="saving">使用 CloudFront 可節省 <strong>87% 成本</strong>！</p>
      </section>

      <section class="info-section">
        <h2>技術棧</h2>
        <div class="tech-grid">
          <div class="tech-item">
            <span class="tech-icon"></span>
            <span>Vue 3</span>
          </div>
          <div class="tech-item">
            <span class="tech-icon"></span>
            <span>Vite</span>
          </div>
          <div class="tech-item">
            <span class="tech-icon"></span>
            <span>Vue Router</span>
          </div>
          <div class="tech-item">
            <span class="tech-icon"></span>
            <span>Terraform</span>
          </div>
          <div class="tech-item">
            <span class="tech-icon"></span>
            <span>AWS S3</span>
          </div>
          <div class="tech-item">
            <span class="tech-icon"></span>
            <span>CloudFront</span>
          </div>
          <div class="tech-item">
            <span class="tech-icon"></span>
            <span>GitHub Actions</span>
          </div>
          <div class="tech-item">
            <span class="tech-icon"></span>
            <span>OAC</span>
          </div>
        </div>
      </section>
    </div>
  </div>
</template>

<script setup>
</script>

<style scoped>
.about {
  max-width: 1000px;
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

.info-section {
  background: white;
  padding: 30px;
  border-radius: 15px;
  box-shadow: 0 5px 15px rgba(0,0,0,0.1);
}

.info-section h2 {
  color: #667eea;
  margin-bottom: 20px;
}

.info-section ul {
  list-style: none;
  padding-left: 0;
}

.info-section li {
  padding: 8px 0;
  padding-left: 30px;
  position: relative;
}

.info-section li::before {
  content: "";
  position: absolute;
  left: 0;
  color: #667eea;
  font-weight: bold;
}

.comparison {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 20px;
  margin-top: 20px;
}

.method {
  padding: 20px;
  border-radius: 10px;
  background: #f8f9ff;
  border: 2px solid #e0e0e0;
}

.method.highlight {
  background: linear-gradient(135deg, #f8f9ff 0%, #e8ecff 100%);
  border: 2px solid #667eea;
}

.method h3 {
  margin-bottom: 10px;
}

.cost-table {
  width: 100%;
  border-collapse: collapse;
  margin: 20px 0;
}

.cost-table th,
.cost-table td {
  padding: 15px;
  text-align: left;
  border-bottom: 1px solid #e0e0e0;
}

.cost-table th {
  background: #667eea;
  color: white;
  font-weight: 600;
}

.cost-table .highlight-row {
  background: #f8f9ff;
}

.cost {
  font-weight: bold;
  color: #e74c3c;
  font-size: 1.2em;
}

.cost-save {
  font-weight: bold;
  color: #27ae60;
  font-size: 1.2em;
}

.saving {
  text-align: center;
  font-size: 1.1em;
  color: #667eea;
  margin-top: 20px;
}

.tech-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 15px;
  margin-top: 20px;
}

.tech-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 15px;
  background: #f8f9ff;
  border-radius: 10px;
  font-weight: 500;
  transition: transform 0.3s;
}

.tech-item:hover {
  transform: translateY(-3px);
}

.tech-icon {
  font-size: 1.5em;
}

@media (max-width: 768px) {
  .header h1 {
    font-size: 2em;
  }
}
</style>
