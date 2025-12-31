#!/bin/bash

echo "========================================"
echo "Order Service - Proto Generation"
echo "========================================"
echo ""
echo "📋 This service OWNS order.proto"
echo "📋 This service USES user.proto (copy from user-service)"
echo ""

# Create output directories
mkdir -p proto/order
mkdir -p proto/user

# Check if user.proto needs syncing
echo "Checking user.proto status..."
if [ -f "../proto/user.proto" ]; then
    echo "✅ user.proto found in parent proto directory"
else
    echo "⚠️  ../proto/user.proto not found"
    echo "Make sure proto/user.proto exists"
    echo ""
    echo "To get user.proto:"
    echo "  Local:  cp ../user-service/proto/user.proto ../proto/"
    echo "  Remote: curl -o ../proto/user.proto <repo-url>/raw/main/proto/user.proto"
    echo ""
    exit 1
fi

# Generate Go code for order service (this service owns this)
echo ""
echo "Generating Go code from order.proto (OWNED)..."
protoc --go_out=. --go_opt=paths=source_relative \
       --go-grpc_out=. --go-grpc_opt=paths=source_relative \
       ../proto/order.proto

if [ $? -ne 0 ]; then
    echo "❌ Failed to generate code from order.proto"
    exit 1
fi

# Generate Go code for user service client (uses user.proto)
echo "Generating Go code from user.proto (for gRPC client)..."
protoc --go_out=. --go_opt=paths=source_relative \
       --go-grpc_out=. --go-grpc_opt=paths=source_relative \
       ../proto/user.proto

if [ $? -ne 0 ]; then
    echo "❌ Failed to generate code from user.proto"
    exit 1
fi

echo ""
echo "✅ Proto code generated successfully!"
echo ""
echo "Generated files:"
echo "  - proto/order/order.pb.go      (from order.proto - OWNED)"
echo "  - proto/order/order_grpc.pb.go (from order.proto - OWNED)"
echo "  - proto/user/user.pb.go        (from user.proto - for gRPC client)"
echo "  - proto/user/user_grpc.pb.go   (from user.proto - for gRPC client)"
echo ""
echo "🔄 When user-service updates user.proto:"
echo "  1. Get new version: cp ../proto/user.proto ."
echo "  2. Run ./setup-proto.sh"
echo "  3. Update client code if needed"
echo "  4. Test and deploy"

