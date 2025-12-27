import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, ScanCommand, GetCommand, PutCommand, DeleteCommand, UpdateCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);
const TABLE_NAME = 'todos';

// CORS headers for all responses
const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Content-Type': 'application/json'
};

export const handler = async (event) => {
  console.log('Event:', JSON.stringify(event, null, 2));

  const method = event.requestContext.http.method;
  const path = event.rawPath;

  try {
    // Handle CORS preflight
    if (method === 'OPTIONS') {
      return {
        statusCode: 200,
        headers: CORS_HEADERS,
        body: ''
      };
    }

    // Route handlers
    if (path === '/api/todos' && method === 'GET') {
      return await getTodos();
    }

    if (path === '/api/todos' && method === 'POST') {
      return await createTodo(event);
    }

    if (path.startsWith('/api/todos/') && method === 'PUT') {
      const id = path.split('/')[3]; // /api/todos/{id}
      return await updateTodo(id, event);
    }

    if (path.startsWith('/api/todos/') && method === 'DELETE') {
      const id = path.split('/')[3]; // /api/todos/{id}
      return await deleteTodo(id);
    }

    // Not found
    return {
      statusCode: 404,
      headers: CORS_HEADERS,
      body: JSON.stringify({ error: 'Not found' })
    };

  } catch (error) {
    console.error('Error:', error);
    return {
      statusCode: 500,
      headers: CORS_HEADERS,
      body: JSON.stringify({ 
        error: 'Internal server error',
        message: error.message 
      })
    };
  }
};

// GET /todos - Get all todos
async function getTodos() {
  const command = new ScanCommand({
    TableName: TABLE_NAME
  });

  const response = await ddbDocClient.send(command);
  
  return {
    statusCode: 200,
    headers: CORS_HEADERS,
    body: JSON.stringify({
      todos: response.Items || [],
      count: response.Count || 0
    })
  };
}

// POST /todos - Create a new todo
async function createTodo(event) {
  const body = JSON.parse(event.body || '{}');
  
  if (!body.text || body.text.trim() === '') {
    return {
      statusCode: 400,
      headers: CORS_HEADERS,
      body: JSON.stringify({ error: 'Text is required' })
    };
  }

  const todo = {
    id: Date.now().toString(),
    text: body.text.trim(),
    done: false,
    createdAt: Date.now()
  };

  const command = new PutCommand({
    TableName: TABLE_NAME,
    Item: todo
  });

  await ddbDocClient.send(command);

  return {
    statusCode: 201,
    headers: CORS_HEADERS,
    body: JSON.stringify(todo)
  };
}

// PUT /todos/:id - Update a todo
async function updateTodo(id, event) {
  const body = JSON.parse(event.body || '{}');

  // Check if todo exists first
  const getCommand = new GetCommand({
    TableName: TABLE_NAME,
    Key: { id }
  });

  const existingTodo = await ddbDocClient.send(getCommand);
  
  if (!existingTodo.Item) {
    return {
      statusCode: 404,
      headers: CORS_HEADERS,
      body: JSON.stringify({ error: 'Todo not found' })
    };
  }

  // Update the done status
  const command = new UpdateCommand({
    TableName: TABLE_NAME,
    Key: { id },
    UpdateExpression: 'SET done = :done',
    ExpressionAttributeValues: {
      ':done': body.done === true
    },
    ReturnValues: 'ALL_NEW'
  });

  const response = await ddbDocClient.send(command);

  return {
    statusCode: 200,
    headers: CORS_HEADERS,
    body: JSON.stringify(response.Attributes)
  };
}

// DELETE /todos/:id - Delete a todo
async function deleteTodo(id) {
  const command = new DeleteCommand({
    TableName: TABLE_NAME,
    Key: { id }
  });

  await ddbDocClient.send(command);

  return {
    statusCode: 204,
    headers: CORS_HEADERS,
    body: ''
  };
}
