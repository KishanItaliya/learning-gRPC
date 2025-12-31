@echo off
echo ========================================
echo gRPC Microservices Setup Script
echo Self-Contained Services Pattern
echo ========================================
echo.

REM Check if protoc is installed
where protoc >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Error: protoc is not installed
    echo Please install Protocol Buffers compiler:
    echo   Download from https://github.com/protocolbuffers/protobuf/releases
    echo   Add to PATH after installation
    exit /b 1
)

echo Installing Go proto tools...
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

echo.
echo === USER SERVICE ===
echo User Service OWNS user.proto
echo Generating protobuf code...
if not exist "user-service\proto\user" mkdir user-service\proto\user
protoc --go_out=user-service --go_opt=paths=source_relative --go-grpc_out=user-service --go-grpc_opt=paths=source_relative proto/user.proto

if %ERRORLEVEL% EQU 0 (
    echo [OK] User Service proto code generated
) else (
    echo [ERROR] Failed to generate User Service proto code
    exit /b 1
)

echo.
echo === ORDER SERVICE ===
echo Order Service OWNS order.proto
echo Order Service USES user.proto ^(copy^)
echo Generating protobuf code...
if not exist "order-service\proto\order" mkdir order-service\proto\order
if not exist "order-service\proto\user" mkdir order-service\proto\user

REM Generate for order.proto (this service owns)
protoc --go_out=order-service --go_opt=paths=source_relative --go-grpc_out=order-service --go-grpc_opt=paths=source_relative proto/order.proto

REM Generate for user.proto (for gRPC client)
protoc --go_out=order-service --go_opt=paths=source_relative --go-grpc_out=order-service --go-grpc_opt=paths=source_relative proto/user.proto

if %ERRORLEVEL% EQU 0 (
    echo [OK] Order Service proto code generated
) else (
    echo [ERROR] Failed to generate Order Service proto code
    exit /b 1
)

echo.
echo === API GATEWAY ===
echo API Gateway USES both protos ^(copies^)
echo Syncing proto files...
if not exist "api-gateway\proto" mkdir api-gateway\proto
copy proto\user.proto api-gateway\proto\ >nul
copy proto\order.proto api-gateway\proto\ >nul
echo [OK] API Gateway proto files synced

echo.
echo Installing Go dependencies for User Service...
cd user-service
go mod tidy
if %ERRORLEVEL% EQU 0 (
    echo [OK] User Service dependencies installed
)
cd ..

echo.
echo Installing Go dependencies for Order Service...
cd order-service
go mod tidy
if %ERRORLEVEL% EQU 0 (
    echo [OK] Order Service dependencies installed
)
cd ..

echo.
echo Installing Node.js dependencies for API Gateway...
cd api-gateway
if exist "package.json" (
    call npm install
    if %ERRORLEVEL% EQU 0 (
        echo [OK] API Gateway dependencies installed
    )
)
cd ..

echo.
echo ========================================
echo Setup completed successfully!
echo ========================================
echo.
echo Proto Ownership:
echo   - user.proto  --^> user-service ^(OWNS^)
echo   - order.proto --^> order-service ^(OWNS^)
echo.
echo Next steps:
echo 1. Start all services with Docker:
echo    docker-compose up --build
echo.
echo 2. OR run services individually:
echo    Terminal 1: cd user-service ^&^& go run main.go
echo    Terminal 2: cd order-service ^&^& go run main.go
echo    Terminal 3: cd api-gateway ^&^& npm start
echo.
echo 3. Test the system:
echo    curl http://localhost:3000/health
echo.
echo Documentation:
echo   - Self-contained pattern: SELF_CONTAINED_SERVICES.md
echo   - Complete guide: NEW_STRUCTURE_SUMMARY.md
echo   - Quick reference: SELF_CONTAINED_QUICK_REF.md
