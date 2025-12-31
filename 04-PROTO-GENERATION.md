# Proto Generation Guide

## Proto Ownership Model

```
user.proto  → OWNED by user-service
order.proto → OWNED by order-service

Consumers:
- order-service USES user.proto (for gRPC client)
- api-gateway USES both (for REST translation)
```

## Proto Files Location

```
proto/
├── user.proto      # Owned by user-service
└── order.proto     # Owned by order-service
```

## Quick Start

### Generate All Proto Files

```bash
# Linux/macOS
./setup.sh

# Windows
setup.bat
```

This will:
1. Install Go proto tools
2. Generate proto code for user-service
3. Generate proto code for order-service
4. Sync proto files to api-gateway

### Per-Service Generation

**User Service** (owns user.proto):
```bash
cd user-service
./setup-proto.sh
```

**Order Service** (owns order.proto, uses user.proto):
```bash
cd order-service
./setup-proto.sh
```

**API Gateway** (uses both protos):
```bash
cd api-gateway
./sync-proto.sh
```

## Manual Proto Generation

### Install Required Tools

```bash
# Install protoc-gen-go
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest

# Install protoc-gen-go-grpc
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# Add to PATH
export PATH="$PATH:$(go env GOPATH)/bin"
```

### User Service

```bash
cd user-service

# Create output directory
mkdir -p proto/user

# Generate Go code
protoc --go_out=. --go_opt=paths=source_relative \
       --go-grpc_out=. --go-grpc_opt=paths=source_relative \
       ../proto/user.proto
```

**Generated files:**
- `proto/user/user.pb.go` - Protocol buffer messages
- `proto/user/user_grpc.pb.go` - gRPC service code

### Order Service

```bash
cd order-service

# Create output directories
mkdir -p proto/order
mkdir -p proto/user

# Generate for order.proto (owned)
protoc --go_out=. --go_opt=paths=source_relative \
       --go-grpc_out=. --go-grpc_opt=paths=source_relative \
       ../proto/order.proto

# Generate for user.proto (for gRPC client)
protoc --go_out=. --go_opt=paths=source_relative \
       --go-grpc_out=. --go-grpc_opt=paths=source_relative \
       ../proto/user.proto
```

**Generated files:**
- `proto/order/order.pb.go` - Order messages
- `proto/order/order_grpc.pb.go` - Order service code
- `proto/user/user.pb.go` - User messages (for client)
- `proto/user/user_grpc.pb.go` - User service client code

### API Gateway

```bash
cd api-gateway

# Create proto directory
mkdir -p proto

# Copy proto files
cp ../proto/user.proto proto/
cp ../proto/order.proto proto/
```

**Note:** API Gateway uses `@grpc/proto-loader` to load proto files dynamically at runtime. No code generation needed.

## When Proto Files Change

### Scenario 1: user.proto Changes

1. **Update user.proto** (owned by user-service)
   ```bash
   vim proto/user.proto
   ```

2. **Regenerate in user-service**
   ```bash
   cd user-service
   ./setup-proto.sh
   ```

3. **Update order-service** (consumer)
   ```bash
   cd order-service
   ./setup-proto.sh
   ```

4. **Update api-gateway** (consumer)
   ```bash
   cd api-gateway
   ./sync-proto.sh
   npm restart
   ```

5. **Test all services**
   ```bash
   docker-compose up --build
   ```

### Scenario 2: order.proto Changes

1. **Update order.proto** (owned by order-service)
   ```bash
   vim proto/order.proto
   ```

2. **Regenerate in order-service**
   ```bash
   cd order-service
   ./setup-proto.sh
   ```

3. **Update api-gateway** (consumer)
   ```bash
   cd api-gateway
   ./sync-proto.sh
   npm restart
   ```

## Docker Build Integration

Proto code generation is automatically handled in Dockerfiles:

### User Service Dockerfile
```dockerfile
# Install tools
RUN apk add protobuf protobuf-dev && \
    go install google.golang.org/protobuf/cmd/protoc-gen-go@latest && \
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# Copy proto and generate
COPY ../proto /proto
RUN protoc ... /proto/user.proto
```

### Order Service Dockerfile
```dockerfile
# Generate for both protos
RUN protoc ... /proto/order.proto && \
    protoc ... /proto/user.proto
```

### API Gateway Dockerfile
```dockerfile
# Proto files mounted via docker-compose volume
# See docker-compose.yml: - ./proto:/app/proto:ro
```

## Proto File Structure

### user.proto
```protobuf
syntax = "proto3";

package user;
option go_package = "user-service/proto/user";

service UserService {
  rpc CreateUser(CreateUserRequest) returns (CreateUserResponse);
  rpc GetUser(GetUserRequest) returns (GetUserResponse);
  rpc UpdateUser(UpdateUserRequest) returns (UpdateUserResponse);
  rpc DeleteUser(DeleteUserRequest) returns (DeleteUserResponse);
  rpc ListUsers(ListUsersRequest) returns (ListUsersResponse);
  rpc ValidateUser(ValidateUserRequest) returns (ValidateUserResponse);
}

message User {
  int32 id = 1;
  string name = 2;
  string email = 3;
  string phone = 4;
  string address = 5;
  string created_at = 6;
  string updated_at = 7;
}
```

### order.proto
```protobuf
syntax = "proto3";

package order;
option go_package = "order-service/proto/order";

service OrderService {
  rpc CreateOrder(CreateOrderRequest) returns (CreateOrderResponse);
  rpc GetOrder(GetOrderRequest) returns (GetOrderResponse);
  rpc UpdateOrderStatus(UpdateOrderStatusRequest) returns (UpdateOrderStatusResponse);
  rpc ListOrders(ListOrdersRequest) returns (ListOrdersResponse);
  rpc GetUserOrders(GetUserOrdersRequest) returns (GetUserOrdersResponse);
  rpc CancelOrder(CancelOrderRequest) returns (CancelOrderResponse);
}

enum OrderStatus {
  PENDING = 0;
  PROCESSING = 1;
  SHIPPED = 2;
  DELIVERED = 3;
  CANCELLED = 4;
}
```

## Import Paths in Go Code

### User Service
```go
import pb "user-service/proto/user"
```

### Order Service
```go
import (
    pb "order-service/proto/order"      // For order operations
    userpb "order-service/proto/user"   // For user service client
)
```

## Troubleshooting

### "protoc: command not found"
```bash
# macOS
brew install protobuf

# Ubuntu/Debian
sudo apt-get install protobuf-compiler

# Verify
protoc --version
```

### "protoc-gen-go: command not found"
```bash
# Install tools
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# Add to PATH
export PATH="$PATH:$(go env GOPATH)/bin"

# Verify
which protoc-gen-go
which protoc-gen-go-grpc
```

### Import errors after generation
```bash
# Make sure go.mod is up to date
cd user-service && go mod tidy
cd ../order-service && go mod tidy

# Rebuild
go build
```

### Generated files not found
```bash
# Check generated files exist
ls -la user-service/proto/user/
ls -la order-service/proto/order/
ls -la order-service/proto/user/

# If missing, regenerate
./setup.sh
```

## Best Practices

1. **Always regenerate after proto changes**
2. **Commit proto files, not generated code**
3. **Use setup scripts for consistency**
4. **Test after regeneration**
5. **Update all consumers when proto changes**
6. **Use semantic versioning for breaking changes**
7. **Document proto ownership clearly**

