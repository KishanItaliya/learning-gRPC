package models

import (
	"database/sql"
	"time"
)

type OrderStatus string

const (
	OrderStatusPending    OrderStatus = "PENDING"
	OrderStatusProcessing OrderStatus = "PROCESSING"
	OrderStatusShipped    OrderStatus = "SHIPPED"
	OrderStatusDelivered  OrderStatus = "DELIVERED"
	OrderStatusCancelled  OrderStatus = "CANCELLED"
)

type OrderItem struct {
	ID          int32
	OrderID     int32
	ProductName string
	Quantity    int32
	Price       float64
	CreatedAt   time.Time
}

type Order struct {
	ID          int32
	UserID      int32
	UserName    string
	UserEmail   string
	Items       []*OrderItem
	TotalAmount float64
	Status      OrderStatus
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

type OrderRepository interface {
	Create(order *Order) error
	GetByID(id int32) (*Order, error)
	Update(order *Order) error
	List(page, limit int32) ([]*Order, int32, error)
	GetByUserID(userID int32) ([]*Order, error)
	UpdateStatus(id int32, status OrderStatus) error
	Cancel(id int32) error
}

type orderRepository struct {
	db *sql.DB
}

func NewOrderRepository(db *sql.DB) OrderRepository {
	return &orderRepository{db: db}
}

func (r *orderRepository) Create(order *Order) error {
	// Start transaction
	tx, err := r.db.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback()

	// Insert order
	query := `
		INSERT INTO orders (user_id, user_name, user_email, total_amount, status)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id, created_at, updated_at
	`
	err = tx.QueryRow(query, order.UserID, order.UserName, order.UserEmail, order.TotalAmount, order.Status).
		Scan(&order.ID, &order.CreatedAt, &order.UpdatedAt)
	if err != nil {
		return err
	}

	// Insert order items
	itemQuery := `
		INSERT INTO order_items (order_id, product_name, quantity, price)
		VALUES ($1, $2, $3, $4)
		RETURNING id, created_at
	`
	for _, item := range order.Items {
		item.OrderID = order.ID
		err = tx.QueryRow(itemQuery, order.ID, item.ProductName, item.Quantity, item.Price).
			Scan(&item.ID, &item.CreatedAt)
		if err != nil {
			return err
		}
	}

	return tx.Commit()
}

func (r *orderRepository) GetByID(id int32) (*Order, error) {
	query := `
		SELECT id, user_id, user_name, user_email, total_amount, status, created_at, updated_at
		FROM orders
		WHERE id = $1
	`
	order := &Order{}
	err := r.db.QueryRow(query, id).Scan(
		&order.ID, &order.UserID, &order.UserName, &order.UserEmail,
		&order.TotalAmount, &order.Status, &order.CreatedAt, &order.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}

	// Get order items
	items, err := r.getOrderItems(order.ID)
	if err != nil {
		return nil, err
	}
	order.Items = items

	return order, nil
}

func (r *orderRepository) getOrderItems(orderID int32) ([]*OrderItem, error) {
	query := `
		SELECT id, order_id, product_name, quantity, price, created_at
		FROM order_items
		WHERE order_id = $1
	`
	rows, err := r.db.Query(query, orderID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []*OrderItem
	for rows.Next() {
		item := &OrderItem{}
		err := rows.Scan(&item.ID, &item.OrderID, &item.ProductName, &item.Quantity, &item.Price, &item.CreatedAt)
		if err != nil {
			return nil, err
		}
		items = append(items, item)
	}

	return items, nil
}

func (r *orderRepository) Update(order *Order) error {
	query := `
		UPDATE orders
		SET user_name = $1, user_email = $2, total_amount = $3, status = $4, updated_at = CURRENT_TIMESTAMP
		WHERE id = $5
		RETURNING updated_at
	`
	return r.db.QueryRow(query, order.UserName, order.UserEmail, order.TotalAmount, order.Status, order.ID).
		Scan(&order.UpdatedAt)
}

func (r *orderRepository) List(page, limit int32) ([]*Order, int32, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 10
	}

	offset := (page - 1) * limit

	// Get total count
	var total int32
	countQuery := `SELECT COUNT(*) FROM orders`
	err := r.db.QueryRow(countQuery).Scan(&total)
	if err != nil {
		return nil, 0, err
	}

	// Get orders
	query := `
		SELECT id, user_id, user_name, user_email, total_amount, status, created_at, updated_at
		FROM orders
		ORDER BY created_at DESC
		LIMIT $1 OFFSET $2
	`
	rows, err := r.db.Query(query, limit, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var orders []*Order
	for rows.Next() {
		order := &Order{}
		err := rows.Scan(
			&order.ID, &order.UserID, &order.UserName, &order.UserEmail,
			&order.TotalAmount, &order.Status, &order.CreatedAt, &order.UpdatedAt,
		)
		if err != nil {
			return nil, 0, err
		}

		// Get order items
		items, err := r.getOrderItems(order.ID)
		if err != nil {
			return nil, 0, err
		}
		order.Items = items

		orders = append(orders, order)
	}

	return orders, total, nil
}

func (r *orderRepository) GetByUserID(userID int32) ([]*Order, error) {
	query := `
		SELECT id, user_id, user_name, user_email, total_amount, status, created_at, updated_at
		FROM orders
		WHERE user_id = $1
		ORDER BY created_at DESC
	`
	rows, err := r.db.Query(query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var orders []*Order
	for rows.Next() {
		order := &Order{}
		err := rows.Scan(
			&order.ID, &order.UserID, &order.UserName, &order.UserEmail,
			&order.TotalAmount, &order.Status, &order.CreatedAt, &order.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}

		// Get order items
		items, err := r.getOrderItems(order.ID)
		if err != nil {
			return nil, err
		}
		order.Items = items

		orders = append(orders, order)
	}

	return orders, nil
}

func (r *orderRepository) UpdateStatus(id int32, status OrderStatus) error {
	query := `
		UPDATE orders
		SET status = $1, updated_at = CURRENT_TIMESTAMP
		WHERE id = $2
	`
	result, err := r.db.Exec(query, status, id)
	if err != nil {
		return err
	}

	rows, err := result.RowsAffected()
	if err != nil {
		return err
	}

	if rows == 0 {
		return sql.ErrNoRows
	}

	return nil
}

func (r *orderRepository) Cancel(id int32) error {
	return r.UpdateStatus(id, OrderStatusCancelled)
}

