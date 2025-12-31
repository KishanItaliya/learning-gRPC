# Local Development Setup Guide

## Prerequisites

- **Go**: 1.21 or higher
- **Node.js**: 18 or higher
- **PostgreSQL**: 15 or higher
- **Protocol Buffers Compiler** (`protoc`) - See installation below
- **Docker & Docker Compose** (for containerized setup)

## Installing Protocol Buffers Compiler (protoc)

### Windows

**Option 1: Using Chocolatey (Recommended)**
```bash
choco install protoc
```

**Option 2: Manual Installation**
1. Download the latest release from [GitHub Releases](https://github.com/protocolbuffers/protobuf/releases)
2. Download `protoc-<version>-win64.zip` (e.g., `protoc-25.1-win64.zip`)
3. Extract the ZIP file
4. Add the `bin` folder to your system PATH:
   - Copy the path to the extracted `bin` folder (e.g., `C:\protoc\bin`)
   - Press `Win + X` → System → Advanced system settings → Environment Variables
   - Under "System variables", find and edit `Path`
   - Click "New" and add the protoc `bin` path
   - Click "OK" to save
5. Restart your terminal and verify:
```bash
protoc --version
```

### macOS

```bash
brew install protobuf
```

### Linux (Ubuntu/Debian)

```bash
sudo apt-get update
sudo apt-get install -y protobuf-compiler
```

### Verify Installation

```bash
protoc --version
# Should output: libprotoc 3.x.x or higher
```

## Quick Start with Docker

```bash
# 1. Clone the repository
git clone <repository-url>
cd gRPC

# 2. Generate proto files
./setup.sh        # Linux/macOS
setup.bat         # Windows

# 3. Start all services
docker-compose up --build
```

Services will be available at:
- **User Service (gRPC)**: `localhost:50051`
- **Order Service (gRPC)**: `localhost:50052`
- **API Gateway (REST)**: `http://localhost:3000`

## Manual Setup (Without Docker)

### Step 1: Install Dependencies

```bash
# Install Go proto tools
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
```

### Step 2: Setup PostgreSQL

```bash
# Create databases
createdb userdb
createdb orderdb

# Or using psql
psql -U postgres
CREATE DATABASE userdb;
CREATE DATABASE orderdb;
```

### Step 3: Generate Proto Files

```bash
# Run main setup script
./setup.sh        # Linux/macOS
setup.bat         # Windows

# Or per-service:
cd user-service && ./setup-proto.sh
cd ../order-service && ./setup-proto.sh
cd ../api-gateway && ./sync-proto.sh
```

### Step 4: Start Services

**Terminal 1 - User Service:**
```bash
cd user-service
export DB_HOST=localhost
export DB_PORT=5432
export DB_USER=postgres
export DB_PASSWORD=postgres
export DB_NAME=userdb
export GRPC_PORT=50051
go run main.go
```

**Terminal 2 - Order Service:**
```bash
cd order-service
export DB_HOST=localhost
export DB_PORT=5432
export DB_USER=postgres
export DB_PASSWORD=postgres
export DB_NAME=orderdb
export GRPC_PORT=50052
export USER_SERVICE_URL=localhost:50051
go run main.go
```

**Terminal 3 - API Gateway:**
```bash
cd api-gateway
export PORT=3000
export USER_SERVICE_URL=localhost:50051
export ORDER_SERVICE_URL=localhost:50052
npm install
npm start
```

## Environment Variables

### User Service
```bash
DB_HOST=localhost          # Database host
DB_PORT=5432              # Database port
DB_USER=postgres          # Database user
DB_PASSWORD=postgres      # Database password
DB_NAME=userdb            # Database name
GRPC_PORT=50051           # gRPC server port
```

### Order Service
```bash
DB_HOST=localhost          # Database host
DB_PORT=5432              # Database port
DB_USER=postgres          # Database user
DB_PASSWORD=postgres      # Database password
DB_NAME=orderdb           # Database name
GRPC_PORT=50052           # gRPC server port
USER_SERVICE_URL=localhost:50051  # User service address
```

### API Gateway
```bash
PORT=3000                           # HTTP server port
USER_SERVICE_URL=localhost:50051    # User service address
ORDER_SERVICE_URL=localhost:50052   # Order service address
```

## Verify Setup

```bash
# Check health
curl http://localhost:3000/health

# Expected response:
# {"status":"ok","services":{"userService":"connected","orderService":"connected"}}
```

## Troubleshooting

### Proto generation fails

**Error: "protoc is not installed"**

Follow the installation steps above for your OS. For Windows:
1. Download protoc from https://github.com/protocolbuffers/protobuf/releases
2. Extract and add `bin` folder to PATH
3. Restart terminal
4. Verify: `protoc --version`

**Check protoc installation:**
```bash
# Windows (PowerShell)
Get-Command protoc

# Linux/macOS
which protoc

# All platforms
protoc --version
```

**Check Go proto tools:**
```bash
# Windows (PowerShell)
Get-Command protoc-gen-go
Get-Command protoc-gen-go-grpc

# Linux/macOS
which protoc-gen-go
which protoc-gen-go-grpc
```

**If missing, reinstall:**
```bash
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# Add Go bin to PATH (Windows)
$env:PATH += ";$env:USERPROFILE\go\bin"

# Add Go bin to PATH (Linux/macOS)
export PATH="$PATH:$(go env GOPATH)/bin"
```

### Database connection fails
```bash
# Check PostgreSQL is running
pg_isready

# Check databases exist
psql -U postgres -l

# Verify connection string in environment variables
```

### Service can't connect
```bash
# Check if services are running
ps aux | grep "go run"
ps aux | grep "node"

# Check ports are not in use
lsof -i :50051
lsof -i :50052
lsof -i :3000
```

## Using Makefile

```bash
# Generate proto files
make proto

# Build services
make build

# Run with Docker
make docker-up

# View logs
make logs

# Stop services
make docker-down

# Clean up
make docker-clean
```

