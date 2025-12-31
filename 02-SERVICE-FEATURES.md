# Service Features & API Routes

## User Service (Go - gRPC)

**Port**: 50051  
**Protocol**: gRPC  
**Database**: PostgreSQL (userdb)

### Features
- User CRUD operations
- User validation for other services
- Automatic timestamps (created_at, updated_at)
- Pagination support

### gRPC Methods

#### CreateUser
```protobuf
rpc CreateUser(CreateUserRequest) returns (CreateUserResponse)
```
- Creates a new user
- Required fields: name, email

#### GetUser
```protobuf
rpc GetUser(GetUserRequest) returns (GetUserResponse)
```
- Retrieves user by ID

#### UpdateUser
```protobuf
rpc UpdateUser(UpdateUserRequest) returns (UpdateUserResponse)
```
- Updates user information
- Partial updates supported

#### DeleteUser
```protobuf
rpc DeleteUser(DeleteUserRequest) returns (DeleteUserResponse)
```
- Soft deletes a user

#### ListUsers
```protobuf
rpc ListUsers(ListUsersRequest) returns (ListUsersResponse)
```
- Lists all users with pagination
- Default limit: 10

#### ValidateUser
```protobuf
rpc ValidateUser(ValidateUserRequest) returns (ValidateUserResponse)
```
- Validates if a user exists
- Used by Order Service

---

## Order Service (Go - gRPC)

**Port**: 50052  
**Protocol**: gRPC  
**Database**: PostgreSQL (orderdb)

### Features
- Order management
- User validation via User Service (gRPC)
- Order items support
- Automatic total calculation
- Order status tracking

### gRPC Methods

#### CreateOrder
```protobuf
rpc CreateOrder(CreateOrderRequest) returns (CreateOrderResponse)
```
- Creates a new order
- Validates user via User Service
- Calculates total amount automatically
- Required fields: userId, items[]

#### GetOrder
```protobuf
rpc GetOrder(GetOrderRequest) returns (GetOrderResponse)
```
- Retrieves order by ID

#### UpdateOrderStatus
```protobuf
rpc UpdateOrderStatus(UpdateOrderStatusRequest) returns (UpdateOrderStatusResponse)
```
- Updates order status
- Status options: PENDING, PROCESSING, SHIPPED, DELIVERED, CANCELLED

#### ListOrders
```protobuf
rpc ListOrders(ListOrdersRequest) returns (ListOrdersResponse)
```
- Lists all orders with pagination

#### GetUserOrders
```protobuf
rpc GetUserOrders(GetUserOrdersRequest) returns (GetUserOrdersResponse)
```
- Lists orders for a specific user

#### CancelOrder
```protobuf
rpc CancelOrder(CancelOrderRequest) returns (CancelOrderResponse)
```
- Cancels an order

### Order Status Flow
```
PENDING → PROCESSING → SHIPPED → DELIVERED
    ↓
CANCELLED
```

---

## API Gateway (Node.js - REST)

**Port**: 3000  
**Protocol**: HTTP/REST  
**Purpose**: Translates REST API calls to gRPC

### Features
- REST to gRPC translation
- JSON request/response
- Error handling
- CORS support
- Health check endpoint

### REST API Endpoints

#### Health Check
```
GET /health
```
**Response:**
```json
{
  "status": "ok",
  "services": {
    "userService": "connected",
    "orderService": "connected"
  }
}
```

---

### User Endpoints

#### Create User
```
POST /users
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+1234567890",
  "address": "123 Main St"
}
```

#### Get User
```
GET /users/:id
```

#### Update User
```
PUT /users/:id
Content-Type: application/json

{
  "name": "John Updated",
  "email": "john.new@example.com"
}
```

#### Delete User
```
DELETE /users/:id
```

#### List Users
```
GET /users?page=1&limit=10
```

---

### Order Endpoints

#### Create Order
```
POST /orders
Content-Type: application/json

{
  "userId": 1,
  "items": [
    {
      "productName": "Laptop",
      "quantity": 1,
      "price": 999.99
    },
    {
      "productName": "Mouse",
      "quantity": 2,
      "price": 25.50
    }
  ]
}
```

#### Get Order
```
GET /orders/:id
```

#### Update Order Status
```
PATCH /orders/:id/status
Content-Type: application/json

{
  "status": "PROCESSING"
}
```
**Status values**: PENDING, PROCESSING, SHIPPED, DELIVERED, CANCELLED

#### List Orders
```
GET /orders?page=1&limit=10
```

#### Get User Orders
```
GET /users/:userId/orders
```

#### Cancel Order
```
POST /orders/:id/cancel
```

---

## Testing Examples

### Create User
```bash
curl -X POST http://localhost:3000/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Alice Smith",
    "email": "alice@example.com",
    "phone": "+1234567890",
    "address": "456 Oak Ave"
  }'
```

### Create Order
```bash
curl -X POST http://localhost:3000/orders \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1,
    "items": [
      {
        "productName": "Smartphone",
        "quantity": 1,
        "price": 699.99
      }
    ]
  }'
```

### Get User Orders
```bash
curl http://localhost:3000/users/1/orders
```

### Update Order Status
```bash
curl -X PATCH http://localhost:3000/orders/1/status \
  -H "Content-Type: application/json" \
  -d '{"status": "SHIPPED"}'
```

---

## Database Schema

### User Table
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(50),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Order Table
```sql
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    user_name VARCHAR(255),
    user_email VARCHAR(255),
    total_amount DECIMAL(10,2),
    status VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Order Items Table
```sql
CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id),
    product_name VARCHAR(255),
    quantity INTEGER,
    price DECIMAL(10,2)
);
```

