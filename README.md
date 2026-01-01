# gRPC Microservices with Node.js API Gateway

A production-ready implementation of microservices architecture using gRPC for inter-service communication and REST API for client access.

## 🏗️ Architecture

```
Client (HTTP/REST)
       ↓
API Gateway (Node.js:3000)
       ↓
   ┌───┴────┐
   ↓        ↓
User Service  Order Service (Go gRPC)
   ↓            ↓
UserDB       OrderDB (PostgreSQL)
```

### Services

- **User Service** (Go - gRPC:50051): User CRUD operations
- **Order Service** (Go - gRPC:50052): Order management + User validation
- **API Gateway** (Node.js - REST:3000): REST to gRPC translation

### Communication

- **Client ↔ API Gateway**: HTTP/REST (JSON)
- **API Gateway ↔ Services**: gRPC
- **Order Service ↔ User Service**: gRPC (inter-service)

## 🚀 Quick Start

### With Docker (Recommended)

```bash
# Start all services (proto generation happens automatically in Docker build)
docker-compose up --build

# Test
curl http://localhost:3000/health
```

**Note:** When using Docker, proto files are automatically generated during the build process. No need to run setup scripts manually.

### Local Development (Without Docker)

```bash
# 1. Generate proto files locally
./setup.sh        # Linux/macOS
setup.bat         # Windows

# 2. Run services manually (see 01-LOCAL-SETUP.md for details)
```

**Windows Users:** See **[WINDOWS-SETUP.md](WINDOWS-SETUP.md)** for detailed Windows installation guide.

## 📚 Documentation

| Guide | Description |
|-------|-------------|
| **[WINDOWS-SETUP.md](WINDOWS-SETUP.md)** | Windows installation guide (start here on Windows!) |
| **[01-LOCAL-SETUP.md](01-LOCAL-SETUP.md)** | Local development setup |
| **[02-SERVICE-FEATURES.md](02-SERVICE-FEATURES.md)** | API routes and features |
| **[03-AWS-DEPLOYMENT.md](03-AWS-DEPLOYMENT.md)** | AWS deployment guide |
| **[04-PROTO-GENERATION.md](04-PROTO-GENERATION.md)** | Proto file management |
| **[05-INTER-SERVICE-COMMUNICATION.md](05-INTER-SERVICE-COMMUNICATION.md)** | Service communication patterns |

## 🛠️ Technologies

- **Go** 1.23+ (User & Order Services)
- **Node.js** 18+ (API Gateway)
- **gRPC** 1.70.0 (Inter-service communication)
- **Protocol Buffers** 3.0+ (Service definitions)
- **PostgreSQL** 15+ (Databases)
- **Docker & Docker Compose** (Containerization)

## 📋 Prerequisites

- Go 1.23+
- Node.js 18+
- PostgreSQL 15+
- Protocol Buffers Compiler (`protoc`) 3.0+
- Docker & Docker Compose (for containerized deployment)

## 🧪 Testing

### Create a User
```bash
curl -X POST http://localhost:3000/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com"}'
```

### Create an Order
```bash
curl -X POST http://localhost:3000/orders \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1,
    "items": [
      {"productName":"Laptop","quantity":1,"price":999.99}
    ]
  }'
```

### Get User Orders
```bash
curl http://localhost:3000/users/1/orders
```

## 📁 Project Structure

```
├── proto/                      # Proto definitions
│   ├── user.proto             # User service (owned by user-service)
│   └── order.proto            # Order service (owned by order-service)
│
├── user-service/              # User Service (Go)
│   ├── proto/user/            # Generated proto code
│   ├── service/               # gRPC implementation
│   ├── models/                # Data models
│   ├── database/              # DB connection
│   ├── main.go
│   ├── Dockerfile
│   └── setup-proto.sh         # Proto generation
│
├── order-service/             # Order Service (Go)
│   ├── proto/
│   │   ├── order/            # Generated proto code (owned)
│   │   └── user/             # Generated proto code (for client)
│   ├── service/              # gRPC implementation
│   ├── client/               # User service gRPC client
│   ├── models/               # Data models
│   ├── database/             # DB connection
│   ├── main.go
│   ├── Dockerfile
│   └── setup-proto.sh        # Proto generation
│
├── api-gateway/              # API Gateway (Node.js)
│   ├── proto/                # Proto files (copies)
│   ├── routes/               # REST routes
│   ├── grpc-clients.js       # gRPC clients
│   ├── server.js
│   ├── Dockerfile
│   └── sync-proto.sh         # Proto sync
│
├── scripts/                  # Utility scripts
├── docker-compose.yml        # Docker orchestration
├── Makefile                  # Build automation
├── setup.sh / setup.bat      # Setup scripts
│
└── Documentation/
    ├── 01-LOCAL-SETUP.md
    ├── 02-SERVICE-FEATURES.md
    ├── 03-AWS-DEPLOYMENT.md
    ├── 04-PROTO-GENERATION.md
    └── 05-INTER-SERVICE-COMMUNICATION.md
```

## 🔧 Proto Generation

Each service manages its own proto definitions:

- **user-service** owns `user.proto`
- **order-service** owns `order.proto`
- Consumers copy proto files they need

```bash
# Generate all
./setup.sh

# Or per-service
cd user-service && ./setup-proto.sh
cd order-service && ./setup-proto.sh
cd api-gateway && ./sync-proto.sh
```

See **[04-PROTO-GENERATION.md](04-PROTO-GENERATION.md)** for details.

## 🚀 Deployment

### Local
```bash
docker-compose up --build
```

### AWS ECS Fargate
See **[03-AWS-DEPLOYMENT.md](03-AWS-DEPLOYMENT.md)** for complete guide.

Key steps:
1. Create ECR repositories
2. Build and push Docker images
3. Create RDS PostgreSQL instance
4. Deploy to ECS Fargate with ALB

## 📊 Service Ports

| Service | Protocol | Port |
|---------|----------|------|
| User Service | gRPC | 50051 |
| Order Service | gRPC | 50052 |
| API Gateway | HTTP | 3000 |
| UserDB | PostgreSQL | 5432 |
| OrderDB | PostgreSQL | 5433 |

## 🔍 Health Check

```bash
curl http://localhost:3000/health
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

## 🐛 Troubleshooting

### Proto generation fails
```bash
# Install protoc
brew install protobuf                    # macOS
sudo apt-get install protobuf-compiler   # Linux
# Windows: Download from https://github.com/protocolbuffers/protobuf/releases

# Install Go tools (pinned versions for compatibility)
go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.34.2
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.5.1
```

### Docker build fails with Go version errors
```bash
# The project uses Go 1.23 and gRPC 1.70.0
# Ensure your go.mod files have:
# - go 1.23
# - google.golang.org/grpc v1.70.0
# - google.golang.org/protobuf v1.36.0
```

### Database connection fails
```bash
# Check PostgreSQL is running
pg_isready

# Verify environment variables
echo $DB_HOST $DB_PORT $DB_NAME
```

### Service can't connect
```bash
# Check services are running
docker-compose ps

# Check logs
docker-compose logs user-service
docker-compose logs order-service
docker-compose logs api-gateway
```

## 📝 Environment Variables

### User Service
```bash
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=userdb
GRPC_PORT=50051
```

### Order Service
```bash
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=orderdb
GRPC_PORT=50052
USER_SERVICE_URL=localhost:50051
```

### API Gateway
```bash
PORT=3000
USER_SERVICE_URL=localhost:50051
ORDER_SERVICE_URL=localhost:50052
```

## 🎯 Key Features

- ✅ Polyglot microservices (Go + Node.js)
- ✅ gRPC inter-service communication
- ✅ REST API Gateway pattern
- ✅ Database per service
- ✅ Self-contained proto definitions
- ✅ Docker containerization with multi-stage builds
- ✅ AWS deployment ready
- ✅ Production-ready error handling
- ✅ Health checks
- ✅ Graceful shutdown
- ✅ Version-pinned dependencies for stability

## 📖 Learn More

- **Local Setup**: [01-LOCAL-SETUP.md](01-LOCAL-SETUP.md)
- **API Reference**: [02-SERVICE-FEATURES.md](02-SERVICE-FEATURES.md)
- **AWS Deployment**: [03-AWS-DEPLOYMENT.md](03-AWS-DEPLOYMENT.md)
- **Proto Management**: [04-PROTO-GENERATION.md](04-PROTO-GENERATION.md)
- **Service Communication**: [05-INTER-SERVICE-COMMUNICATION.md](05-INTER-SERVICE-COMMUNICATION.md)

## 📄 License

MIT License - feel free to use this project for learning and production purposes.

---

**Built with ❤️ using Go, Node.js, gRPC, and PostgreSQL**
