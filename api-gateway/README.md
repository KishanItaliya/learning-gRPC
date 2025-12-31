# API Gateway - Node.js/Express REST API

A REST API Gateway built with Node.js and Express that communicates with Go-based gRPC microservices. This service demonstrates **polyglot microservices** architecture.

## Overview

The API Gateway provides a REST API interface that bridges HTTP/JSON requests to gRPC calls, making the microservices accessible via standard REST endpoints.

## Features

- ✅ **REST API** - Standard HTTP/JSON endpoints
- ✅ **gRPC Client** - Communicates with User and Order services via gRPC
- ✅ **Express Framework** - Fast, unopinionated web framework
- ✅ **CORS Enabled** - Cross-Origin Resource Sharing support
- ✅ **Error Handling** - Proper error responses and status codes
- ✅ **Auto Documentation** - Self-documenting API endpoints
- ✅ **Health Checks** - Service health monitoring endpoint

## Architecture

```
Client (Browser/App)
        │
        │ HTTP/JSON
        ▼
   API Gateway (Node.js/Express)
        │
        ├──────gRPC────► User Service (Go)
        │                      │
        │                      ▼
        │                   UserDB
        │
        └──────gRPC────► Order Service (Go)
                               │
                               ▼
                            OrderDB
```

## API Endpoints

### User Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/users` | Create a new user |
| GET | `/api/users` | List all users (paginated) |
| GET | `/api/users/:id` | Get user by ID |
| PUT | `/api/users/:id` | Update user |
| DELETE | `/api/users/:id` | Delete user |
| GET | `/api/users/:id/validate` | Validate user exists |

### Order Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/orders` | Create a new order |
| GET | `/api/orders` | List all orders (paginated) |
| GET | `/api/orders/:id` | Get order by ID |
| PATCH | `/api/orders/:id/status` | Update order status |
| GET | `/api/orders/user/:userId` | Get orders for user |
| POST | `/api/orders/:id/cancel` | Cancel an order |

### System Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | API documentation |
| GET | `/health` | Health check |

## Installation

### Prerequisites

- Node.js 18+
- npm or yarn
- Running User and Order services

### Setup

```bash
cd api-gateway

# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Edit .env if needed
# USER_SERVICE_URL=localhost:50051
# ORDER_SERVICE_URL=localhost:50052
```

## Running

### Development Mode

```bash
npm run dev
```

### Production Mode

```bash
npm start
```

### With Docker

```bash
# Already configured in docker-compose.yml
docker-compose up api-gateway
```

## Usage Examples

### Create User

```bash
curl -X POST http://localhost:3000/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "+1234567890",
    "address": "123 Main St"
  }'
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "+1234567890",
    "address": "123 Main St",
    "created_at": "2024-01-01 12:00:00",
    "updated_at": "2024-01-01 12:00:00"
  },
  "message": "User created successfully"
}
```

### Get User

```bash
curl http://localhost:3000/api/users/1
```

### List Users

```bash
curl "http://localhost:3000/api/users?page=1&limit=10"
```

### Create Order

```bash
curl -X POST http://localhost:3000/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 1,
    "items": [
      {
        "product_name": "Laptop",
        "quantity": 1,
        "price": 999.99
      },
      {
        "product_name": "Mouse",
        "quantity": 2,
        "price": 25.50
      }
    ]
  }'
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "user_id": 1,
    "user_name": "John Doe",
    "user_email": "john@example.com",
    "items": [
      {
        "id": 1,
        "product_name": "Laptop",
        "quantity": 1,
        "price": 999.99
      },
      {
        "id": 2,
        "product_name": "Mouse",
        "quantity": 2,
        "price": 25.50
      }
    ],
    "total_amount": 1050.99,
    "status": "PENDING",
    "created_at": "2024-01-01 12:00:00",
    "updated_at": "2024-01-01 12:00:00"
  },
  "message": "Order created successfully"
}
```

### Update Order Status

```bash
curl -X PATCH http://localhost:3000/api/orders/1/status \
  -H "Content-Type: application/json" \
  -d '{"status": "PROCESSING"}'

# Or with numeric status
curl -X PATCH http://localhost:3000/api/orders/1/status \
  -H "Content-Type: application/json" \
  -d '{"status": 1}'
```

**Status Values:**
- `PENDING` or `0`
- `PROCESSING` or `1`
- `SHIPPED` or `2`
- `DELIVERED` or `3`
- `CANCELLED` or `4`

### Get User Orders

```bash
curl http://localhost:3000/api/orders/user/1
```

### Health Check

```bash
curl http://localhost:3000/health
```

**Response:**
```json
{
  "status": "ok",
  "service": "api-gateway",
  "timestamp": "2024-01-01T12:00:00.000Z"
}
```

## Environment Variables

```env
# Server Configuration
PORT=3000
NODE_ENV=development

# gRPC Service URLs
USER_SERVICE_URL=localhost:50051
ORDER_SERVICE_URL=localhost:50052
```

## Project Structure

```
api-gateway/
├── server.js              # Main server file
├── grpc-clients.js        # gRPC client setup
├── routes/
│   ├── users.js          # User endpoints
│   └── orders.js         # Order endpoints
├── package.json          # Dependencies
├── Dockerfile            # Container configuration
└── .env.example          # Environment template
```

## Error Handling

The API Gateway properly handles gRPC errors and converts them to appropriate HTTP status codes:

| gRPC Code | HTTP Status | Description |
|-----------|-------------|-------------|
| OK (0) | 200 | Success |
| NOT_FOUND (5) | 404 | Resource not found |
| INVALID_ARGUMENT (3) | 400 | Bad request |
| INTERNAL (13) | 500 | Internal server error |

## Testing with Postman/Insomnia

Import the following collection:

```json
{
  "name": "gRPC Microservices API",
  "requests": [
    {
      "name": "Create User",
      "method": "POST",
      "url": "http://localhost:3000/api/users",
      "body": {
        "name": "Alice",
        "email": "alice@example.com"
      }
    },
    {
      "name": "Create Order",
      "method": "POST",
      "url": "http://localhost:3000/api/orders",
      "body": {
        "user_id": 1,
        "items": [
          {"product_name": "Item", "quantity": 1, "price": 99.99}
        ]
      }
    }
  ]
}
```

## Benefits of API Gateway Pattern

1. **Protocol Translation** - REST to gRPC conversion
2. **Single Entry Point** - Unified API for clients
3. **Technology Agnostic** - Clients don't need gRPC knowledge
4. **Browser Compatibility** - Works with standard HTTP
5. **Easier Testing** - Use curl, Postman, browser
6. **Rate Limiting** - Can add rate limiting at gateway
7. **Authentication** - Centralized auth logic

## Polyglot Microservices

This project demonstrates polyglot microservices:
- **Go Services** - User & Order services (gRPC servers)
- **Node.js Service** - API Gateway (gRPC client + REST server)

Both languages communicate seamlessly via gRPC!

## Next Steps

1. **Add Authentication** - JWT tokens
2. **Rate Limiting** - Protect APIs
3. **Caching** - Redis for frequently accessed data
4. **WebSockets** - Real-time updates
5. **GraphQL** - Alternative API layer
6. **API Versioning** - v1, v2 endpoints

## Troubleshooting

### Cannot connect to gRPC services

Check if User and Order services are running:
```bash
grpcurl -plaintext localhost:50051 list
grpcurl -plaintext localhost:50052 list
```

### Module not found errors

Reinstall dependencies:
```bash
rm -rf node_modules package-lock.json
npm install
```

### Port already in use

Change port in `.env`:
```env
PORT=3001
```

## Resources

- [Express Documentation](https://expressjs.com/)
- [gRPC Node.js Guide](https://grpc.io/docs/languages/node/)
- [@grpc/grpc-js](https://www.npmjs.com/package/@grpc/grpc-js)
- [@grpc/proto-loader](https://www.npmjs.com/package/@grpc/proto-loader)

---

**Happy API Building! 🚀**

