# Build stage
FROM golang:1.23-alpine AS builder

WORKDIR /app

# Install protobuf compiler and protoc-gen-go tools
RUN apk add --no-cache git protobuf protobuf-dev && \
    go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.34.2 && \
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.5.1

# Copy parent proto directory (user.proto source of truth)
COPY ./proto ./proto

# Generate protobuf code (this service OWNS user.proto)
# Do this BEFORE copying source code to avoid conflicts  
RUN mkdir -p user-service/proto/user && \
    protoc --proto_path=./proto \
           --go_out=./user-service \
           --go-grpc_out=./user-service \
           ./proto/user.proto && \
    echo "=== Proto files generated ===" && \
    find user-service -name "*.pb.go" -exec ls -lh {} \;

# Copy go mod files
COPY ./user-service/go.mod ./user-service/

# Download dependencies
WORKDIR /app/user-service
RUN go mod tidy && go mod download && go get github.com/lib/pq

# Copy source code (excluding proto directory to avoid overwriting generated files)
COPY ./user-service/*.go ./
COPY ./user-service/database ./database/
COPY ./user-service/models ./models/
COPY ./user-service/service ./service/

# Debug: Check generated proto files
RUN echo "=== Checking proto files in /app/user-service/proto/ ===" && \
    ls -la proto/ || echo "proto dir not found" && \
    echo "=== Checking proto/user subdirectory ===" && \
    ls -la proto/user/ || echo "user dir not found" && \
    echo "=== Checking for *.pb.go in current dir ===" && \
    ls -la *.pb.go 2>/dev/null || echo "no pb.go in current dir"

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Final stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy the binary from builder
COPY --from=builder /app/user-service/main .

# Expose the gRPC port
EXPOSE 50051

# Run the application
CMD ["./main"]

