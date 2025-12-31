@echo off
REM Test Data Population Script for Windows
REM This script populates the databases with sample data for testing

echo ========================================
echo gRPC Microservices - Test Data Setup
echo ========================================
echo.

REM Configuration
set USER_SERVICE_URL=localhost:50051
set ORDER_SERVICE_URL=localhost:50052

REM Check if grpcurl is installed
where grpcurl >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Error: grpcurl is not installed
    echo Install it with: go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest
    exit /b 1
)

echo Creating test users...
echo.

echo Creating User 1: Alice Johnson
grpcurl -plaintext -d "{\"name\": \"Alice Johnson\", \"email\": \"alice.johnson@example.com\", \"phone\": \"+1-555-0101\", \"address\": \"123 Tech Street, San Francisco, CA 94102\"}" %USER_SERVICE_URL% user.UserService/CreateUser
echo.

echo Creating User 2: Bob Smith
grpcurl -plaintext -d "{\"name\": \"Bob Smith\", \"email\": \"bob.smith@example.com\", \"phone\": \"+1-555-0102\", \"address\": \"456 Innovation Avenue, New York, NY 10001\"}" %USER_SERVICE_URL% user.UserService/CreateUser
echo.

echo Creating User 3: Carol White
grpcurl -plaintext -d "{\"name\": \"Carol White\", \"email\": \"carol.white@example.com\", \"phone\": \"+1-555-0103\", \"address\": \"789 Developer Road, Austin, TX 73301\"}" %USER_SERVICE_URL% user.UserService/CreateUser
echo.

echo Creating User 4: David Brown
grpcurl -plaintext -d "{\"name\": \"David Brown\", \"email\": \"david.brown@example.com\", \"phone\": \"+1-555-0104\", \"address\": \"321 Startup Lane, Seattle, WA 98101\"}" %USER_SERVICE_URL% user.UserService/CreateUser
echo.

echo Creating User 5: Emma Davis
grpcurl -plaintext -d "{\"name\": \"Emma Davis\", \"email\": \"emma.davis@example.com\", \"phone\": \"+1-555-0105\", \"address\": \"654 Cloud Drive, Boston, MA 02101\"}" %USER_SERVICE_URL% user.UserService/CreateUser
echo.

echo Creating test orders...
echo.

echo Creating Order 1 for Alice: Electronics
grpcurl -plaintext -d "{\"user_id\": 1, \"items\": [{\"product_name\": \"MacBook Pro 16\"\"\", \"quantity\": 1, \"price\": 2499.99}, {\"product_name\": \"Magic Mouse\", \"quantity\": 1, \"price\": 79.99}]}" %ORDER_SERVICE_URL% order.OrderService/CreateOrder
echo.

echo Creating Order 2 for Alice: Accessories
grpcurl -plaintext -d "{\"user_id\": 1, \"items\": [{\"product_name\": \"USB-C Hub\", \"quantity\": 2, \"price\": 49.99}, {\"product_name\": \"Monitor Stand\", \"quantity\": 1, \"price\": 89.99}]}" %ORDER_SERVICE_URL% order.OrderService/CreateOrder
echo.

echo Creating Order 3 for Bob: Programming Books
grpcurl -plaintext -d "{\"user_id\": 2, \"items\": [{\"product_name\": \"Clean Code\", \"quantity\": 1, \"price\": 45.99}, {\"product_name\": \"Design Patterns\", \"quantity\": 1, \"price\": 54.99}]}" %ORDER_SERVICE_URL% order.OrderService/CreateOrder
echo.

echo Creating Order 4 for Carol: Office Setup
grpcurl -plaintext -d "{\"user_id\": 3, \"items\": [{\"product_name\": \"Ergonomic Chair\", \"quantity\": 1, \"price\": 399.99}, {\"product_name\": \"Standing Desk\", \"quantity\": 1, \"price\": 599.99}]}" %ORDER_SERVICE_URL% order.OrderService/CreateOrder
echo.

echo Creating Order 5 for David: Gaming Setup
grpcurl -plaintext -d "{\"user_id\": 4, \"items\": [{\"product_name\": \"Gaming Monitor 27\"\"\", \"quantity\": 2, \"price\": 349.99}, {\"product_name\": \"Mechanical Keyboard RGB\", \"quantity\": 1, \"price\": 159.99}]}" %ORDER_SERVICE_URL% order.OrderService/CreateOrder
echo.

echo Creating Order 6 for Emma: Mobile Devices
grpcurl -plaintext -d "{\"user_id\": 5, \"items\": [{\"product_name\": \"iPhone 15 Pro\", \"quantity\": 1, \"price\": 999.99}, {\"product_name\": \"AirPods Pro\", \"quantity\": 1, \"price\": 249.99}]}" %ORDER_SERVICE_URL% order.OrderService/CreateOrder
echo.

echo Updating some order statuses...
echo.

echo Updating Order 1 to PROCESSING
grpcurl -plaintext -d "{\"id\": 1, \"status\": 1}" %ORDER_SERVICE_URL% order.OrderService/UpdateOrderStatus
echo.

echo Updating Order 2 to SHIPPED
grpcurl -plaintext -d "{\"id\": 2, \"status\": 2}" %ORDER_SERVICE_URL% order.OrderService/UpdateOrderStatus
echo.

echo Updating Order 3 to DELIVERED
grpcurl -plaintext -d "{\"id\": 3, \"status\": 3}" %ORDER_SERVICE_URL% order.OrderService/UpdateOrderStatus
echo.

echo ========================================
echo Test Data Setup Complete!
echo ========================================
echo.
echo Summary:
echo   - Created 5 users
echo   - Created 6 orders
echo   - Updated 3 order statuses
echo.
echo You can now test with:
echo   - List users: grpcurl -plaintext -d "{\"page\": 1, \"limit\": 10}" %USER_SERVICE_URL% user.UserService/ListUsers
echo   - List orders: grpcurl -plaintext -d "{\"page\": 1, \"limit\": 10}" %ORDER_SERVICE_URL% order.OrderService/ListOrders
echo.

pause

