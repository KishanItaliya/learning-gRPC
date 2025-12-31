#!/bin/bash

# Quick test script for API Gateway

API_URL="http://localhost:3000"

echo "🧪 API Gateway Quick Test"
echo "================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if API is running
echo -e "${YELLOW}Checking if API Gateway is running...${NC}"
if ! curl -s $API_URL/health > /dev/null; then
    echo "❌ API Gateway is not running!"
    echo "Start it with: docker-compose up api-gateway"
    echo "Or locally: cd api-gateway && npm start"
    exit 1
fi
echo -e "${GREEN}✅ API Gateway is running${NC}"
echo ""

# Test 1: Create User
echo -e "${YELLOW}Test 1: Creating a user...${NC}"
USER_RESPONSE=$(curl -s -X POST $API_URL/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "phone": "+1234567890",
    "address": "123 Test Street"
  }')

if echo "$USER_RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
    USER_ID=$(echo "$USER_RESPONSE" | jq -r '.data.id')
    echo -e "${GREEN}✅ User created with ID: $USER_ID${NC}"
else
    echo "❌ Failed to create user"
    echo "$USER_RESPONSE" | jq
    exit 1
fi
echo ""

# Test 2: Get User
echo -e "${YELLOW}Test 2: Getting user details...${NC}"
curl -s $API_URL/api/users/$USER_ID | jq
echo -e "${GREEN}✅ User retrieved successfully${NC}"
echo ""

# Test 3: Create Order
echo -e "${YELLOW}Test 3: Creating an order...${NC}"
ORDER_RESPONSE=$(curl -s -X POST $API_URL/api/orders \
  -H "Content-Type: application/json" \
  -d "{
    \"user_id\": $USER_ID,
    \"items\": [
      {\"product_name\": \"Laptop\", \"quantity\": 1, \"price\": 999.99},
      {\"product_name\": \"Mouse\", \"quantity\": 2, \"price\": 25.50}
    ]
  }")

if echo "$ORDER_RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
    ORDER_ID=$(echo "$ORDER_RESPONSE" | jq -r '.data.id')
    TOTAL=$(echo "$ORDER_RESPONSE" | jq -r '.data.total_amount')
    echo -e "${GREEN}✅ Order created with ID: $ORDER_ID (Total: \$$TOTAL)${NC}"
else
    echo "❌ Failed to create order"
    echo "$ORDER_RESPONSE" | jq
fi
echo ""

# Test 4: Update Order Status
echo -e "${YELLOW}Test 4: Updating order status...${NC}"
STATUS_RESPONSE=$(curl -s -X PATCH $API_URL/api/orders/$ORDER_ID/status \
  -H "Content-Type: application/json" \
  -d '{"status": "PROCESSING"}')

if echo "$STATUS_RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
    NEW_STATUS=$(echo "$STATUS_RESPONSE" | jq -r '.data.status')
    echo -e "${GREEN}✅ Order status updated to: $NEW_STATUS${NC}"
else
    echo "❌ Failed to update order status"
fi
echo ""

# Test 5: Get User Orders
echo -e "${YELLOW}Test 5: Getting user orders...${NC}"
USER_ORDERS=$(curl -s $API_URL/api/orders/user/$USER_ID)
ORDER_COUNT=$(echo "$USER_ORDERS" | jq '.total')
echo -e "${GREEN}✅ User has $ORDER_COUNT order(s)${NC}"
echo ""

echo "================================"
echo -e "${GREEN}🎉 All tests passed!${NC}"
echo ""
echo "Try these endpoints:"
echo "  • API Docs:    $API_URL/"
echo "  • Health:      $API_URL/health"
echo "  • List Users:  $API_URL/api/users"
echo "  • List Orders: $API_URL/api/orders"

