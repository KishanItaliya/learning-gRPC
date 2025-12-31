package service

import (
	"context"
	"database/sql"
	"fmt"
	"log"

	"user-service/models"
	pb "user-service/proto/user"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type UserServiceServer struct {
	pb.UnimplementedUserServiceServer
	repo models.UserRepository
}

func NewUserServiceServer(repo models.UserRepository) *UserServiceServer {
	return &UserServiceServer{repo: repo}
}

func (s *UserServiceServer) CreateUser(ctx context.Context, req *pb.CreateUserRequest) (*pb.CreateUserResponse, error) {
	log.Printf("Creating user: %s", req.Name)

	if req.Name == "" || req.Email == "" {
		return nil, status.Error(codes.InvalidArgument, "name and email are required")
	}

	user := &models.User{
		Name:    req.Name,
		Email:   req.Email,
		Phone:   req.Phone,
		Address: req.Address,
	}

	if err := s.repo.Create(user); err != nil {
		log.Printf("Error creating user: %v", err)
		return nil, status.Error(codes.Internal, "failed to create user")
	}

	return &pb.CreateUserResponse{
		User:    modelToProto(user),
		Message: "User created successfully",
	}, nil
}

func (s *UserServiceServer) GetUser(ctx context.Context, req *pb.GetUserRequest) (*pb.GetUserResponse, error) {
	log.Printf("Getting user with ID: %d", req.Id)

	user, err := s.repo.GetByID(req.Id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, status.Error(codes.NotFound, "user not found")
		}
		log.Printf("Error getting user: %v", err)
		return nil, status.Error(codes.Internal, "failed to get user")
	}

	return &pb.GetUserResponse{
		User: modelToProto(user),
	}, nil
}

func (s *UserServiceServer) UpdateUser(ctx context.Context, req *pb.UpdateUserRequest) (*pb.UpdateUserResponse, error) {
	log.Printf("Updating user with ID: %d", req.Id)

	// Check if user exists
	existingUser, err := s.repo.GetByID(req.Id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, status.Error(codes.NotFound, "user not found")
		}
		return nil, status.Error(codes.Internal, "failed to get user")
	}

	// Update fields
	if req.Name != "" {
		existingUser.Name = req.Name
	}
	if req.Email != "" {
		existingUser.Email = req.Email
	}
	if req.Phone != "" {
		existingUser.Phone = req.Phone
	}
	if req.Address != "" {
		existingUser.Address = req.Address
	}

	if err := s.repo.Update(existingUser); err != nil {
		log.Printf("Error updating user: %v", err)
		return nil, status.Error(codes.Internal, "failed to update user")
	}

	return &pb.UpdateUserResponse{
		User:    modelToProto(existingUser),
		Message: "User updated successfully",
	}, nil
}

func (s *UserServiceServer) DeleteUser(ctx context.Context, req *pb.DeleteUserRequest) (*pb.DeleteUserResponse, error) {
	log.Printf("Deleting user with ID: %d", req.Id)

	if err := s.repo.Delete(req.Id); err != nil {
		if err == sql.ErrNoRows {
			return nil, status.Error(codes.NotFound, "user not found")
		}
		log.Printf("Error deleting user: %v", err)
		return nil, status.Error(codes.Internal, "failed to delete user")
	}

	return &pb.DeleteUserResponse{
		Message: "User deleted successfully",
		Success: true,
	}, nil
}

func (s *UserServiceServer) ListUsers(ctx context.Context, req *pb.ListUsersRequest) (*pb.ListUsersResponse, error) {
	log.Printf("Listing users: page=%d, limit=%d", req.Page, req.Limit)

	users, total, err := s.repo.List(req.Page, req.Limit)
	if err != nil {
		log.Printf("Error listing users: %v", err)
		return nil, status.Error(codes.Internal, "failed to list users")
	}

	pbUsers := make([]*pb.User, len(users))
	for i, user := range users {
		pbUsers[i] = modelToProto(user)
	}

	return &pb.ListUsersResponse{
		Users: pbUsers,
		Total: total,
	}, nil
}

func (s *UserServiceServer) ValidateUser(ctx context.Context, req *pb.ValidateUserRequest) (*pb.ValidateUserResponse, error) {
	log.Printf("Validating user with ID: %d", req.UserId)

	user, err := s.repo.GetByID(req.UserId)
	if err != nil {
		if err == sql.ErrNoRows {
			return &pb.ValidateUserResponse{
				IsValid: false,
				User:    nil,
			}, nil
		}
		log.Printf("Error validating user: %v", err)
		return nil, status.Error(codes.Internal, "failed to validate user")
	}

	return &pb.ValidateUserResponse{
		IsValid: true,
		User:    modelToProto(user),
	}, nil
}

func modelToProto(user *models.User) *pb.User {
	return &pb.User{
		Id:        user.ID,
		Name:      user.Name,
		Email:     user.Email,
		Phone:     user.Phone,
		Address:   user.Address,
		CreatedAt: user.CreatedAt.Format("2006-01-02 15:04:05"),
		UpdatedAt: user.UpdatedAt.Format("2006-01-02 15:04:05"),
	}
}

