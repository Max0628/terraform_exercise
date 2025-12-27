<template>
  <div class="home">
    <div class="hero">
      <h1>CloudFront + S3 靜態網站</h1>
      <p class="subtitle">使用 OAC (Origin Access Control) 的安全靜態網站</p>
      <p class="tech-stack">Vue 3 + Vite + Vue Router + CI/CD</p>
    </div>

    <div class="features">
      <div class="feature-card">
        <div class="icon"></div>
        <h3>CloudFront CDN</h3>
        <p>全球加速內容傳輸，邊緣節點快取</p>
      </div>
      
      <div class="feature-card">
        <div class="icon"></div>
        <h3>S3 Private Bucket</h3>
        <p>完全私有的儲存空間，禁止公開存取</p>
      </div>
      
      <div class="feature-card">
        <div class="icon"></div>
        <h3>OAC 安全機制</h3>
        <p>只能透過 CloudFront 存取 S3</p>
      </div>
      
      <div class="feature-card">
        <div class="icon"></div>
        <h3>自動化部署</h3>
        <p>GitHub Actions CI/CD 自動編譯上傳</p>
      </div>
    </div>

    <div class="architecture">
      <h2>架構流程</h2>
      <div class="steps">
        <div class="step">
          <div class="step-number">1</div>
          <div class="step-content">
            <h4>使用者請求</h4>
            <p>瀏覽器 → CloudFront</p>
          </div>
        </div>
        <div class="arrow">→</div>
        <div class="step">
          <div class="step-number">2</div>
          <div class="step-content">
            <h4>快取檢查</h4>
            <p>Edge Location 快取</p>
          </div>
        </div>
        <div class="arrow">→</div>
        <div class="step">
          <div class="step-number">3</div>
          <div class="step-content">
            <h4>OAC 驗證</h4>
            <p>CloudFront 向 S3 請求</p>
          </div>
        </div>
        <div class="arrow">→</div>
        <div class="step">
          <div class="step-number">4</div>
          <div class="step-content">
            <h4>回傳內容</h4>
            <p>S3 → CloudFront → 使用者</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
</script>

<style scoped>
.home {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

.hero {
  text-align: center;
  padding: 60px 20px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border-radius: 20px;
  margin-bottom: 40px;
  box-shadow: 0 10px 30px rgba(0,0,0,0.2);
}

.hero h1 {
  font-size: 3em;
  margin-bottom: 10px;
}

.subtitle {
  font-size: 1.3em;
  margin-bottom: 10px;
  opacity: 0.95;
}

.tech-stack {
  font-size: 1.1em;
  opacity: 0.9;
  font-weight: 500;
}

.features {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 30px;
  margin-bottom: 60px;
}

.feature-card {
  background: white;
  padding: 30px;
  border-radius: 15px;
  box-shadow: 0 5px 15px rgba(0,0,0,0.1);
  text-align: center;
  transition: transform 0.3s, box-shadow 0.3s;
}

.feature-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 10px 25px rgba(0,0,0,0.15);
}

.icon {
  font-size: 3em;
  margin-bottom: 15px;
}

.feature-card h3 {
  color: #667eea;
  margin-bottom: 10px;
}

.architecture {
  background: white;
  padding: 40px;
  border-radius: 15px;
  box-shadow: 0 5px 15px rgba(0,0,0,0.1);
}

.architecture h2 {
  text-align: center;
  color: #667eea;
  margin-bottom: 40px;
}

.steps {
  display: flex;
  align-items: center;
  justify-content: center;
  flex-wrap: wrap;
  gap: 20px;
}

.step {
  display: flex;
  align-items: center;
  gap: 15px;
  background: #f8f9ff;
  padding: 20px;
  border-radius: 10px;
  min-width: 200px;
}

.step-number {
  width: 40px;
  height: 40px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: bold;
  flex-shrink: 0;
}

.step-content h4 {
  margin: 0 0 5px 0;
  color: #333;
}

.step-content p {
  margin: 0;
  font-size: 0.9em;
  color: #666;
}

.arrow {
  font-size: 2em;
  color: #667eea;
  font-weight: bold;
}

@media (max-width: 768px) {
  .hero h1 {
    font-size: 2em;
  }
  
  .arrow {
    transform: rotate(90deg);
  }
}
</style>
