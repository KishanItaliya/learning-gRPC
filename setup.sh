#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}gRPC Microservices Setup Script${NC}"
echo -e "${GREEN}Self-Contained Services Pattern${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if protoc is installed
if ! command -v protoc &> /dev/null; then
    echo -e "${RED}Error: protoc is not installed${NC}"
    echo "Please install Protocol Buffers compiler:"
    echo "  - macOS: brew install protobuf"
    echo "  - Linux: sudo apt-get install protobuf-compiler"
    echo "  - Windows: Download from https://github.com/protocolbuffers/protobuf/releases"
    exit 1
fi

echo -e "${YELLOW}Installing Go proto tools...${NC}"

# Install protoc-gen-go
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# Add GOPATH/bin to PATH if not already there
export PATH="$PATH:$(go env GOPATH)/bin"

echo ""
echo -e "${GREEN}=== USER SERVICE ===${NC}"
echo -e "${YELLOW}User Service OWNS user.proto${NC}"
echo -e "${YELLOW}Generating protobuf code...${NC}"
mkdir -p user-service/proto/user
protoc --go_out=user-service --go_opt=paths=source_relative \
       --go-grpc_out=user-service --go-grpc_opt=paths=source_relative \
       proto/user.proto

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ User Service proto code generated${NC}"
else
    echo -e "${RED}❌ Failed to generate User Service proto code${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}=== ORDER SERVICE ===${NC}"
echo -e "${YELLOW}Order Service OWNS order.proto${NC}"
echo -e "${YELLOW}Order Service USES user.proto (copy)${NC}"
echo -e "${YELLOW}Generating protobuf code...${NC}"
mkdir -p order-service/proto/order
mkdir -p order-service/proto/user

# Generate for order.proto (this service owns)
protoc --go_out=order-service --go_opt=paths=source_relative \
       --go-grpc_out=order-service --go-grpc_opt=paths=source_relative \
       proto/order.proto

# Generate for user.proto (for gRPC client)
protoc --go_out=order-service --go_opt=paths=source_relative \
       --go-grpc_out=order-service --go-grpc_opt=paths=source_relative \
       proto/user.proto

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Order Service proto code generated${NC}"
else
    echo -e "${RED}❌ Failed to generate Order Service proto code${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}=== API GATEWAY ===${NC}"
echo -e "${YELLOW}API Gateway USES both protos (copies)${NC}"
echo -e "${YELLOW}Syncing proto files...${NC}"
mkdir -p api-gateway/proto
cp proto/user.proto api-gateway/proto/
cp proto/order.proto api-gateway/proto/
echo -e "${GREEN}✅ API Gateway proto files synced${NC}"

echo ""
echo -e "${YELLOW}Installing Go dependencies for User Service...${NC}"
cd user-service
go mod tidy
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ User Service dependencies installed${NC}"
fi
cd ..

echo ""
echo -e "${YELLOW}Installing Go dependencies for Order Service...${NC}"
cd order-service
go mod tidy
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Order Service dependencies installed${NC}"
fi
cd ..

echo ""
echo -e "${YELLOW}Installing Node.js dependencies for API Gateway...${NC}"
cd api-gateway
if [ -f "package.json" ]; then
    npm install
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ API Gateway dependencies installed${NC}"
    fi
fi
cd ..

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Setup completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}📁 Proto Ownership:${NC}"
echo "  • user.proto  → user-service (OWNS)"
echo "  • order.proto → order-service (OWNS)"
echo ""
echo -e "${YELLOW}📋 Next steps:${NC}"
echo "1. Start all services with Docker:"
echo "   docker-compose up --build"
echo ""
echo "2. OR run services individually:"
echo "   Terminal 1: cd user-service && go run main.go"
echo "   Terminal 2: cd order-service && go run main.go"  
echo "   Terminal 3: cd api-gateway && npm start"
echo ""
echo "3. Test the system:"
echo "   curl http://localhost:3000/health"
echo ""
echo -e "${YELLOW}📚 Documentation:${NC}"
echo "  • Self-contained pattern: SELF_CONTAINED_SERVICES.md"
echo "  • Complete guide: NEW_STRUCTURE_SUMMARY.md"
echo "  • Quick reference: SELF_CONTAINED_QUICK_REF.md"

