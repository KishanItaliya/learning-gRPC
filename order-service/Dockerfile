# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Install protobuf compiler and protoc-gen-go tools
RUN apk add --no-cache git protobuf protobuf-dev && \
    go install google.golang.org/protobuf/cmd/protoc-gen-go@latest && \
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# Copy parent proto directory (contains order.proto and user.proto)
COPY ../proto /proto

# Copy go mod files
COPY go.mod go.sum* ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Generate protobuf code
# - order.proto: this service OWNS it
# - user.proto: copy for gRPC client to user-service
RUN mkdir -p proto/order proto/user && \
    protoc --go_out=. --go_opt=paths=source_relative \
           --go-grpc_out=. --go-grpc_opt=paths=source_relative \
           /proto/order.proto && \
    protoc --go_out=. --go_opt=paths=source_relative \
           --go-grpc_out=. --go-grpc_opt=paths=source_relative \
           /proto/user.proto

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Final stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy the binary from builder
COPY --from=builder /app/main .

# Expose the gRPC port
EXPOSE 50052

# Run the application
CMD ["./main"]

