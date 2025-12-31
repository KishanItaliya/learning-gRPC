#!/bin/bash

echo "========================================"
echo "API Gateway - Proto Sync"
echo "========================================"
echo ""
echo "📋 This service USES both protos (copies)"
echo "   - user.proto  (from user-service)"
echo "   - order.proto (from order-service)"
echo ""

# Create proto directory
mkdir -p proto

# Track success
SUCCESS=true

# Sync user.proto
echo "Syncing user.proto..."
if [ -f "../proto/user.proto" ]; then
    cp ../proto/user.proto proto/
    echo "✅ user.proto synced from ../proto/"
else
    echo "⚠️  ../proto/user.proto not found"
    echo ""
    echo "To get user.proto:"
    echo "  Local:  cp ../user-service/proto/user.proto proto/"
    echo "  Remote: curl -o proto/user.proto <user-service-repo>/raw/main/proto/user.proto"
    echo ""
    SUCCESS=false
fi

# Sync order.proto
echo "Syncing order.proto..."
if [ -f "../proto/order.proto" ]; then
    cp ../proto/order.proto proto/
    echo "✅ order.proto synced from ../proto/"
else
    echo "⚠️  ../proto/order.proto not found"
    echo ""
    echo "To get order.proto:"
    echo "  Local:  cp ../order-service/proto/order.proto proto/"
    echo "  Remote: curl -o proto/order.proto <order-service-repo>/raw/main/proto/order.proto"
    echo ""
    SUCCESS=false
fi

echo ""
if [ "$SUCCESS" = true ]; then
    echo "✅ Proto files synced successfully!"
    echo ""
    echo "Available proto files:"
    echo "  - proto/user.proto  (from user-service)"
    echo "  - proto/order.proto (from order-service)"
    echo ""
    echo "📝 Note: These are copies."
    echo "   Node.js loads them dynamically with @grpc/proto-loader"
    echo ""
    echo "🔄 When services update their protos:"
    echo "   Run ./sync-proto.sh to get latest versions"
else
    echo "❌ Some proto files could not be synced"
    echo "   Make sure the source proto files exist"
    exit 1
fi

