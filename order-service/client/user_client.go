package client

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	pb "order-service/proto/user"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

type UserServiceClient struct {
	client pb.UserServiceClient
	conn   *grpc.ClientConn
}

func NewUserServiceClient() (*UserServiceClient, error) {
	userServiceURL := os.Getenv("USER_SERVICE_URL")
	if userServiceURL == "" {
		userServiceURL = "localhost:50051"
	}

	log.Printf("Connecting to User Service at %s", userServiceURL)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	conn, err := grpc.DialContext(
		ctx,
		userServiceURL,
		grpc.WithTransportCredentials(insecure.NewCredentials()),
		grpc.WithBlock(),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to user service: %v", err)
	}

	client := pb.NewUserServiceClient(conn)

	log.Println("Successfully connected to User Service")

	return &UserServiceClient{
		client: client,
		conn:   conn,
	}, nil
}

func (c *UserServiceClient) ValidateUser(ctx context.Context, userID int32) (bool, *pb.User, error) {
	log.Printf("Validating user with ID: %d", userID)

	resp, err := c.client.ValidateUser(ctx, &pb.ValidateUserRequest{
		UserId: userID,
	})
	if err != nil {
		return false, nil, err
	}

	return resp.IsValid, resp.User, nil
}

func (c *UserServiceClient) GetUser(ctx context.Context, userID int32) (*pb.User, error) {
	log.Printf("Getting user with ID: %d", userID)

	resp, err := c.client.GetUser(ctx, &pb.GetUserRequest{
		Id: userID,
	})
	if err != nil {
		return nil, err
	}

	return resp.User, nil
}

func (c *UserServiceClient) Close() {
	if c.conn != nil {
		c.conn.Close()
	}
}

