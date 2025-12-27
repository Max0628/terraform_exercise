// API 基礎路徑（使用相對路徑，CloudFront 會分流到 API Gateway）
const API_BASE = '/api'

/**
 * 取得所有 Todos
 */
export async function getTodos() {
  try {
    const response = await fetch(`${API_BASE}/todos`)
    if (!response.ok) {
      throw new Error(`Failed to fetch todos: ${response.statusText}`)
    }
    const data = await response.json()
    return data.todos || []
  } catch (error) {
    console.error('Error fetching todos:', error)
    throw error
  }
}

/**
 * 建立新 Todo
 * @param {string} text - Todo 內容
 */
export async function createTodo(text) {
  try {
    const response = await fetch(`${API_BASE}/todos`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ text })
    })
    
    if (!response.ok) {
      throw new Error(`Failed to create todo: ${response.statusText}`)
    }
    
    return await response.json()
  } catch (error) {
    console.error('Error creating todo:', error)
    throw error
  }
}

/**
 * 更新 Todo 狀態
 * @param {string} id - Todo ID
 * @param {boolean} done - 是否完成
 */
export async function updateTodo(id, done) {
  try {
    const response = await fetch(`${API_BASE}/todos/${id}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ done })
    })
    
    if (!response.ok) {
      throw new Error(`Failed to update todo: ${response.statusText}`)
    }
    
    return await response.json()
  } catch (error) {
    console.error('Error updating todo:', error)
    throw error
  }
}

/**
 * 刪除 Todo
 * @param {string} id - Todo ID
 */
export async function deleteTodo(id) {
  try {
    const response = await fetch(`${API_BASE}/todos/${id}`, {
      method: 'DELETE'
    })
    
    if (!response.ok && response.status !== 204) {
      throw new Error(`Failed to delete todo: ${response.statusText}`)
    }
  } catch (error) {
    console.error('Error deleting todo:', error)
    throw error
  }
}
