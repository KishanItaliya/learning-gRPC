# Windows Setup Quick Reference

## 🪟 Step-by-Step Windows Installation

### Step 1: Install Protocol Buffers Compiler (protoc)

**Option A: Using Chocolatey (Easiest)**
```powershell
# Open PowerShell as Administrator
choco install protoc

# Verify installation
protoc --version
```

**Option B: Manual Installation (Recommended if no Chocolatey)**

1. **Download protoc:**
   - Go to: https://github.com/protocolbuffers/protobuf/releases
   - Download the latest `protoc-XX.X-win64.zip` file
   - Example: `protoc-25.1-win64.zip`

2. **Extract the file:**
   - Extract to a permanent location (e.g., `C:\protoc\`)
   - You should see folders: `bin`, `include`

3. **Add to System PATH:**
   ```
   1. Press Win + X → System
   2. Click "Advanced system settings"
   3. Click "Environment Variables"
   4. Under "System variables", find "Path"
   5. Click "Edit"
   6. Click "New"
   7. Add: C:\protoc\bin (or wherever you extracted it)
   8. Click "OK" on all dialogs
   ```

4. **Verify Installation:**
   ```powershell
   # Close and reopen PowerShell/Terminal
   protoc --version
   # Should show: libprotoc 3.x.x or higher
   ```

### Step 2: Install Go Proto Tools

```powershell
# Install Go protobuf plugins
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# Add Go bin to PATH (if not already)
# Add this to your PowerShell profile or run each time:
$env:PATH += ";$env:USERPROFILE\go\bin"

# Verify
Get-Command protoc-gen-go
Get-Command protoc-gen-go-grpc
```

### Step 3: Run Setup Script

```powershell
# Navigate to project directory
cd D:\Learnings\gRPC

# Run setup script (use .\ prefix on Windows)
.\setup.bat

# If you see security warning, run:
PowerShell -ExecutionPolicy Bypass -File .\setup.bat
```

### Step 4: Start Services

**Using Docker (Recommended):**
```powershell
docker-compose up --build
```

**Manual Start (3 terminals):**
```powershell
# Terminal 1 - User Service
cd user-service
$env:DB_HOST="localhost"
$env:DB_PORT="5432"
$env:DB_USER="postgres"
$env:DB_PASSWORD="postgres"
$env:DB_NAME="userdb"
$env:GRPC_PORT="50051"
go run main.go

# Terminal 2 - Order Service
cd order-service
$env:DB_HOST="localhost"
$env:DB_PORT="5432"
$env:DB_USER="postgres"
$env:DB_PASSWORD="postgres"
$env:DB_NAME="orderdb"
$env:GRPC_PORT="50052"
$env:USER_SERVICE_URL="localhost:50051"
go run main.go

# Terminal 3 - API Gateway
cd api-gateway
$env:PORT="3000"
$env:USER_SERVICE_URL="localhost:50051"
$env:ORDER_SERVICE_URL="localhost:50052"
npm install
npm start
```

## 🔧 Common Windows Issues

### Issue 1: "setup.bat was not found"
**Solution:**
```powershell
# Use .\ prefix to run local scripts
.\setup.bat
```

### Issue 2: "protoc: command not found"
**Solution:**
```powershell
# 1. Check if protoc is installed
Get-Command protoc

# 2. If not found, install using Option A or B above

# 3. Verify PATH includes protoc
$env:PATH

# 4. Add to PATH manually (temporary):
$env:PATH += ";C:\protoc\bin"

# 5. For permanent PATH, use System Settings → Environment Variables
```

### Issue 3: "protoc-gen-go: command not found"
**Solution:**
```powershell
# 1. Install Go plugins
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# 2. Add Go bin to PATH
$env:PATH += ";$env:USERPROFILE\go\bin"

# 3. Verify
Get-Command protoc-gen-go
```

### Issue 4: PostgreSQL Connection Error
**Solution:**
```powershell
# Check if PostgreSQL is running
Get-Service -Name postgresql*

# If not running, start it:
Start-Service postgresql-x64-15  # Replace with your version

# Or use Docker instead:
docker run -d `
  --name postgres `
  -e POSTGRES_PASSWORD=postgres `
  -p 5432:5432 `
  postgres:15
```

### Issue 5: Port Already in Use
**Solution:**
```powershell
# Check what's using the port
netstat -ano | findstr :50051
netstat -ano | findstr :50052
netstat -ano | findstr :3000

# Kill the process (replace PID with actual process ID)
taskkill /PID <PID> /F
```

## 🎯 Quick Commands Reference

### Setup & Start
```powershell
# First time setup
.\setup.bat

# Start with Docker
docker-compose up --build

# Stop services
docker-compose down
```

### Testing
```powershell
# Test health
curl http://localhost:3000/health

# Create user
curl -X POST http://localhost:3000/users `
  -H "Content-Type: application/json" `
  -d '{"name":"John Doe","email":"john@example.com"}'

# Create order
curl -X POST http://localhost:3000/orders `
  -H "Content-Type: application/json" `
  -d '{\"userId\":1,\"items\":[{\"productName\":\"Laptop\",\"quantity\":1,\"price\":999.99}]}'
```

### Regenerate Proto Files
```powershell
# All services
.\setup.bat

# Individual services
cd user-service
bash setup-proto.sh  # Requires Git Bash

cd ..\order-service
bash setup-proto.sh

cd ..\api-gateway
bash sync-proto.sh
```

## 📋 Checklist Before Running

- [ ] Go 1.21+ installed (`go version`)
- [ ] Node.js 18+ installed (`node --version`)
- [ ] PostgreSQL 15+ installed or Docker available
- [ ] protoc installed (`protoc --version`)
- [ ] Go proto tools installed (`Get-Command protoc-gen-go`)
- [ ] PATH includes protoc bin directory
- [ ] PATH includes Go bin directory

## 🆘 Still Having Issues?

1. **Restart your terminal** after installing tools
2. **Check all PATH variables** are set correctly
3. **Use Docker** instead of manual setup (easier)
4. **Check firewall** isn't blocking ports 3000, 50051, 50052
5. **Run PowerShell as Administrator** if permission issues

## 📚 Additional Resources

- **protoc releases**: https://github.com/protocolbuffers/protobuf/releases
- **Go installation**: https://golang.org/doc/install
- **Node.js installation**: https://nodejs.org/
- **PostgreSQL for Windows**: https://www.postgresql.org/download/windows/
- **Docker Desktop**: https://www.docker.com/products/docker-desktop/

---

**Need more help?** Check the main guides:
- [01-LOCAL-SETUP.md](01-LOCAL-SETUP.md)
- [04-PROTO-GENERATION.md](04-PROTO-GENERATION.md)

