# Build stage
FROM golang:1.23-alpine AS builder

WORKDIR /app

# Install protobuf compiler and protoc-gen-go tools
RUN apk add --no-cache git protobuf protobuf-dev && \
    go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.34.2 && \
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.5.1

# Copy parent proto directory (contains order.proto and user.proto)
COPY ./proto ./proto

# Generate protobuf code
# - order.proto: this service OWNS it
# - user.proto: copy for gRPC client to user-service
# Do this BEFORE copying source code to avoid conflicts
RUN mkdir -p order-service/proto/order order-service/proto/user && \
    protoc --proto_path=./proto \
           --go_out=./order-service \
           --go-grpc_out=./order-service \
           ./proto/order.proto && \
    protoc --proto_path=./proto \
           --go_out=./order-service \
           --go-grpc_out=./order-service \
           ./proto/user.proto && \
    echo "=== Proto files generated ===" && \
    find order-service -name "*.pb.go" -exec ls -lh {} \;

# Copy go mod files
COPY ./order-service/go.mod ./order-service/

# Download dependencies
WORKDIR /app/order-service
RUN go mod tidy && go mod download && go get github.com/lib/pq

# Copy source code (excluding proto directory to avoid overwriting generated files)
COPY ./order-service/*.go ./
COPY ./order-service/client ./client/
COPY ./order-service/database ./database/
COPY ./order-service/models ./models/
COPY ./order-service/service ./service/

# Debug: Check generated proto files
RUN echo "=== Checking proto files in /app/order-service/proto/ ===" && \
    ls -la proto/ || echo "proto dir not found"

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Final stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy the binary from builder
COPY --from=builder /app/order-service/main .

# Expose the gRPC port
EXPOSE 50052

# Run the application
CMD ["./main"]

