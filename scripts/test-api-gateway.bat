@echo off
REM Quick test script for API Gateway

set API_URL=http://localhost:3000

echo ================================
echo API Gateway Quick Test
echo ================================
echo.

REM Check if API is running
echo Checking if API Gateway is running...
curl -s %API_URL%/health >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Error: API Gateway is not running!
    echo Start it with: docker-compose up api-gateway
    echo Or locally: cd api-gateway ^&^& npm start
    exit /b 1
)
echo API Gateway is running
echo.

REM Test 1: Create User
echo Test 1: Creating a user...
curl -s -X POST %API_URL%/api/users ^
  -H "Content-Type: application/json" ^
  -d "{\"name\": \"Test User\", \"email\": \"test@example.com\", \"phone\": \"+1234567890\", \"address\": \"123 Test Street\"}"
echo.
echo.

REM Test 2: List Users
echo Test 2: Listing users...
curl -s "%API_URL%/api/users?page=1&limit=5"
echo.
echo.

REM Test 3: Create Order
echo Test 3: Creating an order...
curl -s -X POST %API_URL%/api/orders ^
  -H "Content-Type: application/json" ^
  -d "{\"user_id\": 1, \"items\": [{\"product_name\": \"Laptop\", \"quantity\": 1, \"price\": 999.99}]}"
echo.
echo.

REM Test 4: List Orders
echo Test 4: Listing orders...
curl -s "%API_URL%/api/orders?page=1&limit=5"
echo.
echo.

echo ================================
echo Tests Complete!
echo ================================
echo.
echo Try these endpoints:
echo   - API Docs:    %API_URL%/
echo   - Health:      %API_URL%/health
echo   - List Users:  %API_URL%/api/users
echo   - List Orders: %API_URL%/api/orders
echo.

pause

