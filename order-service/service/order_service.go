package service

import (
	"context"
	"database/sql"
	"fmt"
	"log"

	"order-service/client"
	"order-service/models"
	pb "order-service/proto/order"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type OrderServiceServer struct {
	pb.UnimplementedOrderServiceServer
	repo           models.OrderRepository
	userClient     *client.UserServiceClient
}

func NewOrderServiceServer(repo models.OrderRepository, userClient *client.UserServiceClient) *OrderServiceServer {
	return &OrderServiceServer{
		repo:       repo,
		userClient: userClient,
	}
}

func (s *OrderServiceServer) CreateOrder(ctx context.Context, req *pb.CreateOrderRequest) (*pb.CreateOrderResponse, error) {
	log.Printf("Creating order for user ID: %d", req.UserId)

	// Validate user through User Service
	isValid, user, err := s.userClient.ValidateUser(ctx, req.UserId)
	if err != nil {
		log.Printf("Error validating user: %v", err)
		return nil, status.Error(codes.Internal, "failed to validate user")
	}

	if !isValid {
		return nil, status.Error(codes.NotFound, "user not found")
	}

	// Calculate total amount
	var totalAmount float64
	items := make([]*models.OrderItem, len(req.Items))
	for i, item := range req.Items {
		totalAmount += item.Price * float64(item.Quantity)
		items[i] = &models.OrderItem{
			ProductName: item.ProductName,
			Quantity:    item.Quantity,
			Price:       item.Price,
		}
	}

	// Create order
	order := &models.Order{
		UserID:      req.UserId,
		UserName:    user.Name,
		UserEmail:   user.Email,
		Items:       items,
		TotalAmount: totalAmount,
		Status:      models.OrderStatusPending,
	}

	if err := s.repo.Create(order); err != nil {
		log.Printf("Error creating order: %v", err)
		return nil, status.Error(codes.Internal, "failed to create order")
	}

	return &pb.CreateOrderResponse{
		Order:   modelToProto(order),
		Message: "Order created successfully",
	}, nil
}

func (s *OrderServiceServer) GetOrder(ctx context.Context, req *pb.GetOrderRequest) (*pb.GetOrderResponse, error) {
	log.Printf("Getting order with ID: %d", req.Id)

	order, err := s.repo.GetByID(req.Id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, status.Error(codes.NotFound, "order not found")
		}
		log.Printf("Error getting order: %v", err)
		return nil, status.Error(codes.Internal, "failed to get order")
	}

	return &pb.GetOrderResponse{
		Order: modelToProto(order),
	}, nil
}

func (s *OrderServiceServer) UpdateOrderStatus(ctx context.Context, req *pb.UpdateOrderStatusRequest) (*pb.UpdateOrderStatusResponse, error) {
	log.Printf("Updating order status: ID=%d, Status=%v", req.Id, req.Status)

	// Check if order exists
	order, err := s.repo.GetByID(req.Id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, status.Error(codes.NotFound, "order not found")
		}
		return nil, status.Error(codes.Internal, "failed to get order")
	}

	// Update status
	order.Status = protoStatusToModel(req.Status)
	if err := s.repo.Update(order); err != nil {
		log.Printf("Error updating order status: %v", err)
		return nil, status.Error(codes.Internal, "failed to update order status")
	}

	return &pb.UpdateOrderStatusResponse{
		Order:   modelToProto(order),
		Message: "Order status updated successfully",
	}, nil
}

func (s *OrderServiceServer) ListOrders(ctx context.Context, req *pb.ListOrdersRequest) (*pb.ListOrdersResponse, error) {
	log.Printf("Listing orders: page=%d, limit=%d", req.Page, req.Limit)

	orders, total, err := s.repo.List(req.Page, req.Limit)
	if err != nil {
		log.Printf("Error listing orders: %v", err)
		return nil, status.Error(codes.Internal, "failed to list orders")
	}

	pbOrders := make([]*pb.Order, len(orders))
	for i, order := range orders {
		pbOrders[i] = modelToProto(order)
	}

	return &pb.ListOrdersResponse{
		Orders: pbOrders,
		Total:  total,
	}, nil
}

func (s *OrderServiceServer) GetUserOrders(ctx context.Context, req *pb.GetUserOrdersRequest) (*pb.GetUserOrdersResponse, error) {
	log.Printf("Getting orders for user ID: %d", req.UserId)

	// Validate user
	isValid, _, err := s.userClient.ValidateUser(ctx, req.UserId)
	if err != nil {
		log.Printf("Error validating user: %v", err)
		return nil, status.Error(codes.Internal, "failed to validate user")
	}

	if !isValid {
		return nil, status.Error(codes.NotFound, "user not found")
	}

	orders, err := s.repo.GetByUserID(req.UserId)
	if err != nil {
		log.Printf("Error getting user orders: %v", err)
		return nil, status.Error(codes.Internal, "failed to get user orders")
	}

	pbOrders := make([]*pb.Order, len(orders))
	for i, order := range orders {
		pbOrders[i] = modelToProto(order)
	}

	return &pb.GetUserOrdersResponse{
		Orders: pbOrders,
		Total:  int32(len(orders)),
	}, nil
}

func (s *OrderServiceServer) CancelOrder(ctx context.Context, req *pb.CancelOrderRequest) (*pb.CancelOrderResponse, error) {
	log.Printf("Cancelling order with ID: %d", req.Id)

	// Check if order exists
	_, err := s.repo.GetByID(req.Id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, status.Error(codes.NotFound, "order not found")
		}
		return nil, status.Error(codes.Internal, "failed to get order")
	}

	if err := s.repo.Cancel(req.Id); err != nil {
		log.Printf("Error cancelling order: %v", err)
		return nil, status.Error(codes.Internal, "failed to cancel order")
	}

	return &pb.CancelOrderResponse{
		Message: "Order cancelled successfully",
		Success: true,
	}, nil
}

func modelToProto(order *models.Order) *pb.Order {
	items := make([]*pb.OrderItem, len(order.Items))
	for i, item := range order.Items {
		items[i] = &pb.OrderItem{
			Id:          item.ID,
			ProductName: item.ProductName,
			Quantity:    item.Quantity,
			Price:       item.Price,
		}
	}

	return &pb.Order{
		Id:          order.ID,
		UserId:      order.UserID,
		UserName:    order.UserName,
		UserEmail:   order.UserEmail,
		Items:       items,
		TotalAmount: order.TotalAmount,
		Status:      modelStatusToProto(order.Status),
		CreatedAt:   order.CreatedAt.Format("2006-01-02 15:04:05"),
		UpdatedAt:   order.UpdatedAt.Format("2006-01-02 15:04:05"),
	}
}

func modelStatusToProto(status models.OrderStatus) pb.OrderStatus {
	switch status {
	case models.OrderStatusPending:
		return pb.OrderStatus_PENDING
	case models.OrderStatusProcessing:
		return pb.OrderStatus_PROCESSING
	case models.OrderStatusShipped:
		return pb.OrderStatus_SHIPPED
	case models.OrderStatusDelivered:
		return pb.OrderStatus_DELIVERED
	case models.OrderStatusCancelled:
		return pb.OrderStatus_CANCELLED
	default:
		return pb.OrderStatus_PENDING
	}
}

func protoStatusToModel(status pb.OrderStatus) models.OrderStatus {
	switch status {
	case pb.OrderStatus_PENDING:
		return models.OrderStatusPending
	case pb.OrderStatus_PROCESSING:
		return models.OrderStatusProcessing
	case pb.OrderStatus_SHIPPED:
		return models.OrderStatusShipped
	case pb.OrderStatus_DELIVERED:
		return models.OrderStatusDelivered
	case pb.OrderStatus_CANCELLED:
		return models.OrderStatusCancelled
	default:
		return models.OrderStatusPending
	}
}

