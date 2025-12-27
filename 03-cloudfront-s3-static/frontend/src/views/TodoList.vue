<template>
  <div class="todo-container">
    <h1>Todo List</h1>
    <p class="subtitle">Serverless 全端應用範例</p>
    
    <!-- 錯誤訊息 -->
    <div v-if="error" class="error-message">
      {{ error }}
    </div>
    
    <!-- 新增 Todo 表單 -->
    <div class="add-todo">
      <input
        v-model="newTodoText"
        @keyup.enter="handleAddTodo"
        type="text"
        placeholder="輸入新的待辦事項..."
        :disabled="loading"
      />
      <button @click="handleAddTodo" :disabled="loading || !newTodoText.trim()">
        新增
      </button>
    </div>
    
    <!-- 載入狀態 -->
    <div v-if="loading && !todos.length" class="loading">
      載入中...
    </div>
    
    <!-- Todo 列表 -->
    <div v-else-if="todos.length > 0" class="todo-list">
      <div
        v-for="todo in todos"
        :key="todo.id"
        class="todo-item"
        :class="{ completed: todo.done }"
      >
        <input
          type="checkbox"
          :checked="todo.done"
          @change="handleToggleTodo(todo)"
          :disabled="loading"
        />
        <span class="todo-text">{{ todo.text }}</span>
        <span class="todo-time">{{ formatTime(todo.createdAt) }}</span>
        <button
          class="delete-btn"
          @click="handleDeleteTodo(todo.id)"
          :disabled="loading"
        >
          刪除
        </button>
      </div>
    </div>
    
    <!-- 空狀態 -->
    <div v-else class="empty-state">
      <p>還沒有待辦事項</p>
      <p class="hint">在上方輸入框新增你的第一個 Todo</p>
    </div>
    
    <!-- 統計資訊 -->
    <div v-if="todos.length > 0" class="stats">
      <p>
        總共 {{ todos.length }} 個項目，
        已完成 {{ completedCount }} 個，
        待完成 {{ pendingCount }} 個
      </p>
    </div>
    
    <!-- 架構說明 -->
    <div class="architecture-info">
      <h3>架構說明</h3>
      <p>這個應用展示了 Serverless 全端架構：</p>
      <ul>
        <li><strong>前端</strong>: Vue 3 SPA（部署在 S3 + CloudFront）</li>
        <li><strong>API</strong>: API Gateway HTTP API（路徑分流 /api/*）</li>
        <li><strong>後端</strong>: Lambda 函數（Node.js，處理業務邏輯）</li>
        <li><strong>資料庫</strong>: DynamoDB（NoSQL，按需付費）</li>
      </ul>
      <p class="tech-note">
        資料通過 CloudFront → API Gateway → Lambda → DynamoDB 完整流程
      </p>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { getTodos, createTodo, updateTodo, deleteTodo } from '../api/todoApi'

const todos = ref([])
const newTodoText = ref('')
const loading = ref(false)
const error = ref(null)

// 計算屬性
const completedCount = computed(() => todos.value.filter(t => t.done).length)
const pendingCount = computed(() => todos.value.filter(t => !t.done).length)

// 載入 Todos
async function loadTodos() {
  loading.value = true
  error.value = null
  try {
    todos.value = await getTodos()
    // 按建立時間排序（新的在前）
    todos.value.sort((a, b) => b.createdAt - a.createdAt)
  } catch (err) {
    error.value = '載入 Todos 失敗：' + err.message
  } finally {
    loading.value = false
  }
}

// 新增 Todo
async function handleAddTodo() {
  if (!newTodoText.value.trim()) return
  
  loading.value = true
  error.value = null
  try {
    const newTodo = await createTodo(newTodoText.value.trim())
    todos.value.unshift(newTodo) // 新增到列表開頭
    newTodoText.value = ''
  } catch (err) {
    error.value = '新增 Todo 失敗：' + err.message
  } finally {
    loading.value = false
  }
}

// 切換 Todo 狀態
async function handleToggleTodo(todo) {
  loading.value = true
  error.value = null
  try {
    await updateTodo(todo.id, !todo.done)
    todo.done = !todo.done
  } catch (err) {
    error.value = '更新 Todo 失敗：' + err.message
  } finally {
    loading.value = false
  }
}

// 刪除 Todo
async function handleDeleteTodo(id) {
  if (!confirm('確定要刪除這個 Todo 嗎？')) return
  
  loading.value = true
  error.value = null
  try {
    await deleteTodo(id)
    todos.value = todos.value.filter(t => t.id !== id)
  } catch (err) {
    error.value = '刪除 Todo 失敗：' + err.message
  } finally {
    loading.value = false
  }
}

// 格式化時間
function formatTime(timestamp) {
  const date = new Date(timestamp)
  return date.toLocaleString('zh-TW', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  })
}

// 組件掛載時載入資料
onMounted(() => {
  loadTodos()
})
</script>

<style scoped>
.todo-container {
  max-width: 800px;
  margin: 0 auto;
  padding: 2rem;
}

h1 {
  color: #42b983;
  margin-bottom: 0.5rem;
}

.subtitle {
  color: #888;
  margin-bottom: 2rem;
}

.error-message {
  background-color: #fee;
  border: 1px solid #fcc;
  color: #c33;
  padding: 1rem;
  border-radius: 4px;
  margin-bottom: 1rem;
}

.add-todo {
  display: flex;
  gap: 0.5rem;
  margin-bottom: 2rem;
}

.add-todo input {
  flex: 1;
  padding: 0.75rem;
  border: 2px solid #ddd;
  border-radius: 4px;
  font-size: 1rem;
}

.add-todo input:focus {
  outline: none;
  border-color: #42b983;
}

.add-todo button {
  padding: 0.75rem 1.5rem;
  background-color: #42b983;
  color: white;
  border: none;
  border-radius: 4px;
  font-size: 1rem;
  cursor: pointer;
  transition: background-color 0.3s;
}

.add-todo button:hover:not(:disabled) {
  background-color: #35a372;
}

.add-todo button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.loading {
  text-align: center;
  padding: 2rem;
  color: #888;
}

.todo-list {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.todo-item {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1rem;
  background-color: #f9f9f9;
  border-radius: 4px;
  border: 1px solid #eee;
  transition: all 0.3s;
}

.todo-item:hover {
  background-color: #f0f0f0;
}

.todo-item.completed {
  opacity: 0.6;
}

.todo-item.completed .todo-text {
  text-decoration: line-through;
}

.todo-item input[type="checkbox"] {
  width: 20px;
  height: 20px;
  cursor: pointer;
}

.todo-text {
  flex: 1;
  font-size: 1rem;
}

.todo-time {
  font-size: 0.875rem;
  color: #888;
}

.delete-btn {
  padding: 0.5rem 1rem;
  background-color: #dc3545;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  transition: background-color 0.3s;
}

.delete-btn:hover:not(:disabled) {
  background-color: #c82333;
}

.delete-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.empty-state {
  text-align: center;
  padding: 3rem 1rem;
  color: #888;
}

.empty-state .hint {
  font-size: 0.875rem;
  color: #aaa;
  margin-top: 0.5rem;
}

.stats {
  margin-top: 2rem;
  padding: 1rem;
  background-color: #f0f9ff;
  border-radius: 4px;
  text-align: center;
  color: #555;
}

.architecture-info {
  margin-top: 3rem;
  padding: 1.5rem;
  background-color: #fafafa;
  border-left: 4px solid #42b983;
  border-radius: 4px;
}

.architecture-info h3 {
  margin-top: 0;
  color: #42b983;
}

.architecture-info ul {
  margin: 1rem 0;
  padding-left: 1.5rem;
}

.architecture-info li {
  margin: 0.5rem 0;
}

.tech-note {
  margin-top: 1rem;
  font-style: italic;
  color: #666;
}

@media (max-width: 600px) {
  .todo-container {
    padding: 1rem;
  }
  
  .add-todo {
    flex-direction: column;
  }
  
  .todo-item {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.5rem;
  }
  
  .todo-time {
    font-size: 0.75rem;
  }
}
</style>
