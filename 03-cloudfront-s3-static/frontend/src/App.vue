<script setup>
import { RouterLink, RouterView } from 'vue-router'
</script>

<template>
  <div id="app">
    <nav class="navbar">
      <div class="nav-container">
        <div class="logo">
          <span class="logo-icon">☁️</span>
          <span class="logo-text">CloudFront S3</span>
        </div>
        <div class="nav-links">
          <RouterLink to="/" class="nav-link">首頁</RouterLink>
          <RouterLink to="/about" class="nav-link">關於</RouterLink>
          <RouterLink to="/contact" class="nav-link">聯絡</RouterLink>
          <RouterLink to="/todos" class="nav-link">Todo List</RouterLink>
        </div>
      </div>
    </nav>
    
    <main class="main-content">
      <RouterView />
    </main>
    
    <footer class="footer">
      <p>© 2025 CloudFront + S3 靜態網站 | 使用 Vue 3 + Vite + Terraform 建置</p>
    </footer>
  </div>
</template>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
  line-height: 1.6;
  color: #333;
  background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
  min-height: 100vh;
}

#app {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

.navbar {
  background: white;
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);
  position: sticky;
  top: 0;
  z-index: 100;
}

.nav-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  height: 70px;
}

.logo {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 1.3em;
  font-weight: bold;
  color: #667eea;
}

.logo-icon {
  font-size: 1.5em;
}

.nav-links {
  display: flex;
  gap: 30px;
}

.nav-link {
  text-decoration: none;
  color: #666;
  font-weight: 500;
  padding: 8px 16px;
  border-radius: 8px;
  transition: all 0.3s;
}

.nav-link:hover {
  color: #667eea;
  background: #f8f9ff;
}

.nav-link.router-link-active {
  color: white;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.main-content {
  flex: 1;
  padding: 40px 20px;
}

.footer {
  background: white;
  text-align: center;
  padding: 30px 20px;
  box-shadow: 0 -2px 10px rgba(0,0,0,0.1);
  color: #666;
}

@media (max-width: 768px) {
  .nav-container {
    flex-direction: column;
    height: auto;
    padding: 15px 20px;
    gap: 15px;
  }
  
  .nav-links {
    gap: 15px;
  }
  
  .nav-link {
    font-size: 0.9em;
    padding: 6px 12px;
  }
  will-change: filter;
  transition: filter 300ms;
}
.logo:hover {
  filter: drop-shadow(0 0 2em #646cffaa);
}
.logo.vue:hover {
  filter: drop-shadow(0 0 2em #42b883aa);
}
</style>
