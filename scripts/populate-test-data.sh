#!/bin/bash

# Test Data Population Script
# This script populates the databases with sample data for testing

echo "========================================"
echo "gRPC Microservices - Test Data Setup"
echo "========================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
USER_SERVICE_URL=${USER_SERVICE_URL:-localhost:50051}
ORDER_SERVICE_URL=${ORDER_SERVICE_URL:-localhost:50052}

# Check if grpcurl is installed
if ! command -v grpcurl &> /dev/null; then
    echo -e "${RED}Error: grpcurl is not installed${NC}"
    echo "Install it with: go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest"
    exit 1
fi

echo -e "${YELLOW}Creating test users...${NC}"

# Create Users
echo -e "${GREEN}Creating User 1: Alice Johnson${NC}"
ALICE_ID=$(grpcurl -plaintext -d '{
  "name": "Alice Johnson",
  "email": "alice.johnson@example.com",
  "phone": "+1-555-0101",
  "address": "123 Tech Street, San Francisco, CA 94102"
}' $USER_SERVICE_URL user.UserService/CreateUser | grep -o '"id":[0-9]*' | grep -o '[0-9]*')
echo "Created user with ID: $ALICE_ID"

echo -e "${GREEN}Creating User 2: Bob Smith${NC}"
BOB_ID=$(grpcurl -plaintext -d '{
  "name": "Bob Smith",
  "email": "bob.smith@example.com",
  "phone": "+1-555-0102",
  "address": "456 Innovation Avenue, New York, NY 10001"
}' $USER_SERVICE_URL user.UserService/CreateUser | grep -o '"id":[0-9]*' | grep -o '[0-9]*')
echo "Created user with ID: $BOB_ID"

echo -e "${GREEN}Creating User 3: Carol White${NC}"
CAROL_ID=$(grpcurl -plaintext -d '{
  "name": "Carol White",
  "email": "carol.white@example.com",
  "phone": "+1-555-0103",
  "address": "789 Developer Road, Austin, TX 73301"
}' $USER_SERVICE_URL user.UserService/CreateUser | grep -o '"id":[0-9]*' | grep -o '[0-9]*')
echo "Created user with ID: $CAROL_ID"

echo -e "${GREEN}Creating User 4: David Brown${NC}"
DAVID_ID=$(grpcurl -plaintext -d '{
  "name": "David Brown",
  "email": "david.brown@example.com",
  "phone": "+1-555-0104",
  "address": "321 Startup Lane, Seattle, WA 98101"
}' $USER_SERVICE_URL user.UserService/CreateUser | grep -o '"id":[0-9]*' | grep -o '[0-9]*')
echo "Created user with ID: $DAVID_ID"

echo -e "${GREEN}Creating User 5: Emma Davis${NC}"
EMMA_ID=$(grpcurl -plaintext -d '{
  "name": "Emma Davis",
  "email": "emma.davis@example.com",
  "phone": "+1-555-0105",
  "address": "654 Cloud Drive, Boston, MA 02101"
}' $USER_SERVICE_URL user.UserService/CreateUser | grep -o '"id":[0-9]*' | grep -o '[0-9]*')
echo "Created user with ID: $EMMA_ID"

echo ""
echo -e "${YELLOW}Creating test orders...${NC}"

# Create Orders for Alice (Electronics)
echo -e "${GREEN}Creating Order 1 for Alice: Electronics${NC}"
grpcurl -plaintext -d "{
  \"user_id\": $ALICE_ID,
  \"items\": [
    {\"product_name\": \"MacBook Pro 16\\\"\", \"quantity\": 1, \"price\": 2499.99},
    {\"product_name\": \"Magic Mouse\", \"quantity\": 1, \"price\": 79.99},
    {\"product_name\": \"Magic Keyboard\", \"quantity\": 1, \"price\": 129.99}
  ]
}" $ORDER_SERVICE_URL order.OrderService/CreateOrder > /dev/null
echo "Created electronics order for Alice"

# Create Orders for Alice (Accessories)
echo -e "${GREEN}Creating Order 2 for Alice: Accessories${NC}"
grpcurl -plaintext -d "{
  \"user_id\": $ALICE_ID,
  \"items\": [
    {\"product_name\": \"USB-C Hub\", \"quantity\": 2, \"price\": 49.99},
    {\"product_name\": \"Monitor Stand\", \"quantity\": 1, \"price\": 89.99}
  ]
}" $ORDER_SERVICE_URL order.OrderService/CreateOrder > /dev/null
echo "Created accessories order for Alice"

# Create Order for Bob (Books)
echo -e "${GREEN}Creating Order 3 for Bob: Programming Books${NC}"
grpcurl -plaintext -d "{
  \"user_id\": $BOB_ID,
  \"items\": [
    {\"product_name\": \"Clean Code\", \"quantity\": 1, \"price\": 45.99},
    {\"product_name\": \"Design Patterns\", \"quantity\": 1, \"price\": 54.99},
    {\"product_name\": \"Refactoring\", \"quantity\": 1, \"price\": 49.99},
    {\"product_name\": \"The Pragmatic Programmer\", \"quantity\": 1, \"price\": 39.99}
  ]
}" $ORDER_SERVICE_URL order.OrderService/CreateOrder > /dev/null
echo "Created books order for Bob"

# Create Order for Carol (Office Supplies)
echo -e "${GREEN}Creating Order 4 for Carol: Office Setup${NC}"
grpcurl -plaintext -d "{
  \"user_id\": $CAROL_ID,
  \"items\": [
    {\"product_name\": \"Ergonomic Chair\", \"quantity\": 1, \"price\": 399.99},
    {\"product_name\": \"Standing Desk\", \"quantity\": 1, \"price\": 599.99},
    {\"product_name\": \"Desk Lamp\", \"quantity\": 2, \"price\": 45.99},
    {\"product_name\": \"Cable Management Kit\", \"quantity\": 1, \"price\": 29.99}
  ]
}" $ORDER_SERVICE_URL order.OrderService/CreateOrder > /dev/null
echo "Created office supplies order for Carol"

# Create Order for David (Gaming)
echo -e "${GREEN}Creating Order 5 for David: Gaming Setup${NC}"
grpcurl -plaintext -d "{
  \"user_id\": $DAVID_ID,
  \"items\": [
    {\"product_name\": \"Gaming Monitor 27\\\"\", \"quantity\": 2, \"price\": 349.99},
    {\"product_name\": \"Mechanical Keyboard RGB\", \"quantity\": 1, \"price\": 159.99},
    {\"product_name\": \"Gaming Mouse\", \"quantity\": 1, \"price\": 79.99},
    {\"product_name\": \"Gaming Headset\", \"quantity\": 1, \"price\": 129.99}
  ]
}" $ORDER_SERVICE_URL order.OrderService/CreateOrder > /dev/null
echo "Created gaming order for David"

# Create Order for Emma (Mobile Devices)
echo -e "${GREEN}Creating Order 6 for Emma: Mobile Devices${NC}"
grpcurl -plaintext -d "{
  \"user_id\": $EMMA_ID,
  \"items\": [
    {\"product_name\": \"iPhone 15 Pro\", \"quantity\": 1, \"price\": 999.99},
    {\"product_name\": \"AirPods Pro\", \"quantity\": 1, \"price\": 249.99},
    {\"product_name\": \"MagSafe Charger\", \"quantity\": 1, \"price\": 39.99},
    {\"product_name\": \"Phone Case\", \"quantity\": 2, \"price\": 29.99}
  ]
}" $ORDER_SERVICE_URL order.OrderService/CreateOrder > /dev/null
echo "Created mobile devices order for Emma"

# Create Order for Bob (Second Order - Software)
echo -e "${GREEN}Creating Order 7 for Bob: Software Licenses${NC}"
grpcurl -plaintext -d "{
  \"user_id\": $BOB_ID,
  \"items\": [
    {\"product_name\": \"JetBrains All Products Pack\", \"quantity\": 1, \"price\": 649.00},
    {\"product_name\": \"Adobe Creative Cloud\", \"quantity\": 1, \"price\": 599.88}
  ]
}" $ORDER_SERVICE_URL order.OrderService/CreateOrder > /dev/null
echo "Created software order for Bob"

# Create Order for David (Second Order - Components)
echo -e "${GREEN}Creating Order 8 for David: PC Components${NC}"
grpcurl -plaintext -d "{
  \"user_id\": $DAVID_ID,
  \"items\": [
    {\"product_name\": \"RTX 4080 Graphics Card\", \"quantity\": 1, \"price\": 1199.99},
    {\"product_name\": \"32GB DDR5 RAM\", \"quantity\": 2, \"price\": 179.99},
    {\"product_name\": \"2TB NVMe SSD\", \"quantity\": 1, \"price\": 199.99}
  ]
}" $ORDER_SERVICE_URL order.OrderService/CreateOrder > /dev/null
echo "Created PC components order for David"

echo ""
echo -e "${YELLOW}Updating some order statuses...${NC}"

# Update order statuses
echo -e "${GREEN}Updating Order 1 to PROCESSING${NC}"
grpcurl -plaintext -d '{"id": 1, "status": 1}' $ORDER_SERVICE_URL order.OrderService/UpdateOrderStatus > /dev/null

echo -e "${GREEN}Updating Order 2 to SHIPPED${NC}"
grpcurl -plaintext -d '{"id": 2, "status": 2}' $ORDER_SERVICE_URL order.OrderService/UpdateOrderStatus > /dev/null

echo -e "${GREEN}Updating Order 3 to DELIVERED${NC}"
grpcurl -plaintext -d '{"id": 3, "status": 3}' $ORDER_SERVICE_URL order.OrderService/UpdateOrderStatus > /dev/null

echo -e "${GREEN}Updating Order 4 to PROCESSING${NC}"
grpcurl -plaintext -d '{"id": 4, "status": 1}' $ORDER_SERVICE_URL order.OrderService/UpdateOrderStatus > /dev/null

echo ""
echo -e "${GREEN}========================================"
echo "Test Data Setup Complete!"
echo "========================================${NC}"
echo ""
echo "Summary:"
echo "  • Created 5 users"
echo "  • Created 8 orders"
echo "  • Updated 4 order statuses"
echo ""
echo "You can now test with:"
echo "  • List users: grpcurl -plaintext -d '{\"page\": 1, \"limit\": 10}' $USER_SERVICE_URL user.UserService/ListUsers"
echo "  • List orders: grpcurl -plaintext -d '{\"page\": 1, \"limit\": 10}' $ORDER_SERVICE_URL order.OrderService/ListOrders"
echo "  • Get user orders: grpcurl -plaintext -d '{\"user_id\": 1}' $ORDER_SERVICE_URL order.OrderService/GetUserOrders"
echo ""

