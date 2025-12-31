# Makefile for gRPC Microservices

.PHONY: help setup proto build run-user run-order docker-up docker-down clean test

help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

setup: ## Run initial setup (install dependencies and generate proto files)
	@echo "Running setup..."
	@chmod +x setup.sh
	@./setup.sh

proto: ## Generate protobuf files
	@echo "Generating protobuf files..."
	@mkdir -p user-service/proto/user
	@mkdir -p order-service/proto/order
	@mkdir -p order-service/proto/user
	@protoc --go_out=user-service --go_opt=paths=source_relative \
		--go-grpc_out=user-service --go-grpc_opt=paths=source_relative \
		proto/user.proto
	@protoc --go_out=order-service --go_opt=paths=source_relative \
		--go-grpc_out=order-service --go-grpc_opt=paths=source_relative \
		proto/order.proto
	@protoc --go_out=order-service --go_opt=paths=source_relative \
		--go-grpc_out=order-service --go-grpc_opt=paths=source_relative \
		proto/user.proto
	@echo "Protobuf files generated successfully!"

build-user: ## Build User Service
	@echo "Building User Service..."
	@cd user-service && go build -o bin/user-service main.go

build-order: ## Build Order Service
	@echo "Building Order Service..."
	@cd order-service && go build -o bin/order-service main.go

build: build-user build-order ## Build both services

run-user: ## Run User Service locally
	@echo "Starting User Service..."
	@cd user-service && go run main.go

run-order: ## Run Order Service locally
	@echo "Starting Order Service..."
	@cd order-service && go run main.go

docker-up: ## Start all services with Docker Compose
	@echo "Starting services with Docker Compose..."
	@docker-compose up --build

docker-down: ## Stop all services
	@echo "Stopping services..."
	@docker-compose down

docker-clean: ## Stop services and remove volumes
	@echo "Cleaning up Docker resources..."
	@docker-compose down -v

clean: ## Clean build artifacts
	@echo "Cleaning build artifacts..."
	@rm -rf user-service/bin
	@rm -rf order-service/bin
	@rm -rf user-service/proto/**/*.pb.go
	@rm -rf order-service/proto/**/*.pb.go

logs-user: ## Show User Service logs
	@docker-compose logs -f user-service

logs-order: ## Show Order Service logs
	@docker-compose logs -f order-service

logs: ## Show all service logs
	@docker-compose logs -f

test-user: ## Test User Service
	@echo "Testing User Service..."
	@cd user-service && go test -v ./...

test-order: ## Test Order Service
	@echo "Testing Order Service..."
	@cd order-service && go test -v ./...

test: test-user test-order ## Run all tests

