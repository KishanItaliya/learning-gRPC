package main

import (
	"fmt"
	"log"
	"net"
	"os"
	"os/signal"
	"syscall"

	"order-service/client"
	"order-service/database"
	"order-service/models"
	pb "order-service/proto/order"
	"order-service/service"

	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
)

func main() {
	// Initialize database
	if err := database.InitDB(); err != nil {
		log.Fatalf("Failed to initialize database: %v", err)
	}
	defer database.CloseDB()

	// Initialize User Service client
	userClient, err := client.NewUserServiceClient()
	if err != nil {
		log.Fatalf("Failed to initialize user service client: %v", err)
	}
	defer userClient.Close()

	// Get port from environment or use default
	port := os.Getenv("GRPC_PORT")
	if port == "" {
		port = "50052"
	}

	// Create listener
	lis, err := net.Listen("tcp", fmt.Sprintf(":%s", port))
	if err != nil {
		log.Fatalf("Failed to listen: %v", err)
	}

	// Create gRPC server
	grpcServer := grpc.NewServer()

	// Create repository and service
	orderRepo := models.NewOrderRepository(database.DB)
	orderService := service.NewOrderServiceServer(orderRepo, userClient)

	// Register service
	pb.RegisterOrderServiceServer(grpcServer, orderService)

	// Register reflection service (for grpcurl and debugging)
	reflection.Register(grpcServer)

	// Handle graceful shutdown
	go func() {
		sigCh := make(chan os.Signal, 1)
		signal.Notify(sigCh, os.Interrupt, syscall.SIGTERM)
		<-sigCh
		log.Println("Shutting down gRPC server...")
		grpcServer.GracefulStop()
	}()

	log.Printf("Order Service gRPC server listening on port %s", port)
	if err := grpcServer.Serve(lis); err != nil {
		log.Fatalf("Failed to serve: %v", err)
	}
}

