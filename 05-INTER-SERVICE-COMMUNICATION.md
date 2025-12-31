# Inter-Service Communication Guide

## Architecture Overview

```
Client
  │
  ▼
API Gateway (Node.js - REST)
  │
  ├──► User Service (Go - gRPC)
  │        │
  │        └──► PostgreSQL (userdb)
  │
  └──► Order Service (Go - gRPC)
           │
           ├──► User Service (gRPC client)
           │
           └──► PostgreSQL (orderdb)
```

## Communication Protocols

### 1. REST → gRPC (API Gateway to Services)

**API Gateway** translates HTTP/REST requests to gRPC calls.

#### Example: Create User Flow

**REST Request:**
```bash
POST http://localhost:3000/users
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com"
}
```

**API Gateway Translation:**
```javascript
// api-gateway/routes/users.js
const { userClient } = require('../grpc-clients');

router.post('/', async (req, res) => {
  const request = {
    name: req.body.name,
    email: req.body.email,
    phone: req.body.phone || '',
    address: req.body.address || ''
  };

  userClient.CreateUser(request, (error, response) => {
    if (error) {
      return res.status(500).json({ error: error.message });
    }
    res.status(201).json(response);
  });
});
```

**gRPC Call to User Service:**
```
CreateUser(CreateUserRequest) → CreateUserResponse
```

---

### 2. gRPC → gRPC (Order Service to User Service)

**Order Service** calls **User Service** directly via gRPC client.

#### Example: Create Order with User Validation

**Flow:**
```
1. Client → API Gateway: POST /orders
2. API Gateway → Order Service: CreateOrder(gRPC)
3. Order Service → User Service: ValidateUser(gRPC)
4. User Service → Order Service: User data
5. Order Service → API Gateway: Order created
6. API Gateway → Client: JSON response
```

**Order Service Code:**
```go
// order-service/service/order_service.go
func (s *OrderServiceServer) CreateOrder(ctx context.Context, req *pb.CreateOrderRequest) (*pb.CreateOrderResponse, error) {
    // Validate user through User Service via gRPC
    isValid, user, err := s.userClient.ValidateUser(ctx, req.UserId)
    if err != nil {
        return nil, status.Error(codes.Internal, "failed to validate user")
    }

    if !isValid {
        return nil, status.Error(codes.NotFound, "user not found")
    }

    // Create order with user information
    order := &models.Order{
        UserID:    req.UserId,
        UserName:  user.Name,
        UserEmail: user.Email,
        Items:     items,
        // ...
    }
    
    // Save to database
    if err := s.repo.Create(order); err != nil {
        return nil, status.Error(codes.Internal, "failed to create order")
    }

    return &pb.CreateOrderResponse{
        Order:   modelToProto(order),
        Message: "Order created successfully",
    }, nil
}
```

**User Service Client:**
```go
// order-service/client/user_client.go
type UserServiceClient struct {
    client pb.UserServiceClient
    conn   *grpc.ClientConn
}

func NewUserServiceClient() (*UserServiceClient, error) {
    userServiceURL := os.Getenv("USER_SERVICE_URL")
    if userServiceURL == "" {
        userServiceURL = "localhost:50051"
    }

    conn, err := grpc.Dial(
        userServiceURL,
        grpc.WithTransportCredentials(insecure.NewCredentials()),
    )
    if err != nil {
        return nil, err
    }

    client := pb.NewUserServiceClient(conn)
    return &UserServiceClient{client: client, conn: conn}, nil
}

func (c *UserServiceClient) ValidateUser(ctx context.Context, userID int32) (bool, *pb.User, error) {
    resp, err := c.client.ValidateUser(ctx, &pb.ValidateUserRequest{
        UserId: userID,
    })
    if err != nil {
        return false, nil, err
    }

    return resp.IsValid, resp.User, nil
}
```

---

## Service Discovery

### Local Development

Services use **environment variables** for service discovery:

```bash
# Order Service
export USER_SERVICE_URL=localhost:50051

# API Gateway
export USER_SERVICE_URL=localhost:50051
export ORDER_SERVICE_URL=localhost:50052
```

### Docker Compose

Services use **service names** as hostnames:

```yaml
# docker-compose.yml
services:
  user-service:
    # ...
    
  order-service:
    environment:
      USER_SERVICE_URL: user-service:50051
    depends_on:
      - user-service
      
  api-gateway:
    environment:
      USER_SERVICE_URL: user-service:50051
      ORDER_SERVICE_URL: order-service:50052
    depends_on:
      - user-service
      - order-service
```

### AWS ECS

Services use **AWS Cloud Map** for service discovery:

```bash
# Service Discovery creates DNS records
user-service.local → resolves to user-service tasks
order-service.local → resolves to order-service tasks

# Environment variables in tasks
USER_SERVICE_URL=user-service.local:50051
ORDER_SERVICE_URL=order-service.local:50052
```

---

## gRPC Client Configuration

### Connection Options

```go
// Production-ready client with retry and timeout
conn, err := grpc.Dial(
    userServiceURL,
    grpc.WithTransportCredentials(insecure.NewCredentials()),
    grpc.WithBlock(),
    grpc.WithTimeout(5*time.Second),
    grpc.WithUnaryInterceptor(retryInterceptor),
)
```

### Context with Timeout

```go
// Set deadline for gRPC call
ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
defer cancel()

resp, err := client.ValidateUser(ctx, &pb.ValidateUserRequest{
    UserId: userID,
})
```

---

## Error Handling

### gRPC Error Codes

```go
import "google.golang.org/grpc/codes"
import "google.golang.org/grpc/status"

// Return error with proper gRPC code
if user == nil {
    return nil, status.Error(codes.NotFound, "user not found")
}

if req.Email == "" {
    return nil, status.Error(codes.InvalidArgument, "email is required")
}

if err := db.Query() {
    return nil, status.Error(codes.Internal, "database error")
}
```

### API Gateway Error Translation

```javascript
// Translate gRPC errors to HTTP status codes
userClient.GetUser(request, (error, response) => {
  if (error) {
    let statusCode = 500;
    
    if (error.code === grpc.status.NOT_FOUND) {
      statusCode = 404;
    } else if (error.code === grpc.status.INVALID_ARGUMENT) {
      statusCode = 400;
    }
    
    return res.status(statusCode).json({
      error: error.details || error.message
    });
  }
  
  res.json(response);
});
```

---

## Request/Response Flow

### Example: Create Order with User Validation

**Step 1: Client Request**
```bash
curl -X POST http://localhost:3000/orders \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1,
    "items": [
      {"productName": "Laptop", "quantity": 1, "price": 999.99}
    ]
  }'
```

**Step 2: API Gateway → Order Service (gRPC)**
```javascript
const request = {
  userId: req.body.userId,
  items: req.body.items
};

orderClient.CreateOrder(request, callback);
```

**Step 3: Order Service → User Service (gRPC)**
```go
// Validate user exists
isValid, user, err := s.userClient.ValidateUser(ctx, req.UserId)
```

**Step 4: User Service Response**
```go
return &pb.ValidateUserResponse{
    IsValid: true,
    User: &pb.User{
        Id:    1,
        Name:  "John Doe",
        Email: "john@example.com",
    },
}, nil
```

**Step 5: Order Service Creates Order**
```go
order := &models.Order{
    UserID:    req.UserId,
    UserName:  user.Name,
    UserEmail: user.Email,
    Items:     items,
    TotalAmount: 999.99,
    Status:    models.OrderStatusPending,
}
s.repo.Create(order)
```

**Step 6: Order Service Response**
```go
return &pb.CreateOrderResponse{
    Order: modelToProto(order),
    Message: "Order created successfully",
}, nil
```

**Step 7: API Gateway → Client (JSON)**
```json
{
  "order": {
    "id": 1,
    "userId": 1,
    "userName": "John Doe",
    "userEmail": "john@example.com",
    "items": [...],
    "totalAmount": 999.99,
    "status": "PENDING",
    "createdAt": "2025-12-30T10:00:00Z"
  },
  "message": "Order created successfully"
}
```

---

## Load Balancing

### gRPC Load Balancing

```go
// Client-side load balancing
conn, err := grpc.Dial(
    "dns:///user-service.local:50051",
    grpc.WithBalancerName("round_robin"),
    grpc.WithTransportCredentials(insecure.NewCredentials()),
)
```

### API Gateway Load Balancing

Use Application Load Balancer (ALB) or Nginx:

```nginx
upstream api_gateway {
    server api-gateway-1:3000;
    server api-gateway-2:3000;
    server api-gateway-3:3000;
}

server {
    listen 80;
    location / {
        proxy_pass http://api_gateway;
    }
}
```

---

## Health Checks

### API Gateway Health Check

```javascript
// api-gateway/server.js
app.get('/health', (req, res) => {
  const health = {
    status: 'ok',
    services: {
      userService: 'connected',
      orderService: 'connected'
    }
  };
  
  res.json(health);
});
```

### gRPC Health Check

```go
// Implement health check service
import "google.golang.org/grpc/health"
import healthpb "google.golang.org/grpc/health/grpc_health_v1"

healthServer := health.NewServer()
healthpb.RegisterHealthServer(grpcServer, healthServer)
healthServer.SetServingStatus("", healthpb.HealthCheckResponse_SERVING)
```

---

## Security

### TLS/SSL for gRPC

```go
// Load TLS credentials
creds, err := credentials.NewServerTLSFromFile(certFile, keyFile)
if err != nil {
    log.Fatalf("Failed to setup TLS: %v", err)
}

// Create server with TLS
grpcServer := grpc.NewServer(grpc.Creds(creds))
```

### API Gateway Authentication

```javascript
// Add authentication middleware
app.use('/api', authenticateToken);

function authenticateToken(req, res, next) {
  const token = req.headers['authorization'];
  
  if (!token) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  
  // Verify token
  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ error: 'Forbidden' });
    req.user = user;
    next();
  });
}
```

---

## Monitoring & Logging

### Request Logging

```go
// gRPC interceptor for logging
func loggingInterceptor(ctx context.Context, req interface{}, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (interface{}, error) {
    start := time.Now()
    
    log.Printf("Request: %s", info.FullMethod)
    
    resp, err := handler(ctx, req)
    
    log.Printf("Response: %s (took %v)", info.FullMethod, time.Since(start))
    
    return resp, err
}

// Register interceptor
grpcServer := grpc.NewServer(
    grpc.UnaryInterceptor(loggingInterceptor),
)
```

---

## Best Practices

1. **Use connection pooling** for gRPC clients
2. **Implement retry logic** for transient failures
3. **Set timeouts** for all gRPC calls
4. **Use proper error codes** (gRPC status codes)
5. **Implement circuit breakers** for failing services
6. **Add request tracing** (correlation IDs)
7. **Monitor service health** regularly
8. **Use service discovery** in production
9. **Implement graceful shutdown**
10. **Log all inter-service calls**

