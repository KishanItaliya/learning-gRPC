#!/bin/bash

echo "========================================"
echo "User Service - Proto Generation"
echo "========================================"
echo ""
echo "📋 This service OWNS user.proto"
echo "   Source of truth: proto/user.proto"
echo ""

# Create output directory
mkdir -p proto/user

# Generate Go code from proto
echo "Generating Go code from user.proto..."
protoc --go_out=. --go_opt=paths=source_relative \
       --go-grpc_out=. --go-grpc_opt=paths=source_relative \
       ../proto/user.proto

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Proto code generated successfully!"
    echo ""
    echo "Generated files:"
    echo "  - proto/user/user.pb.go"
    echo "  - proto/user/user_grpc.pb.go"
    echo ""
    echo "📦 For consumers (other services):"
    echo "  Local:  cp ../proto/user.proto <destination>/proto/"
    echo "  Remote: curl -O <repo-url>/raw/main/proto/user.proto"
    echo ""
    echo "🔄 When user.proto changes:"
    echo "  1. Edit ../proto/user.proto"
    echo "  2. Run ./setup-proto.sh"
    echo "  3. Update service code"
    echo "  4. Test and commit"
else
    echo ""
    echo "❌ Failed to generate proto code"
    exit 1
fi

