const express = require('express');
const { orderService } = require('../grpc-clients');

const router = express.Router();

// Order status mapping
const OrderStatus = {
  PENDING: 0,
  PROCESSING: 1,
  SHIPPED: 2,
  DELIVERED: 3,
  CANCELLED: 4
};

// Create Order
router.post('/', async (req, res) => {
  try {
    const { user_id, items } = req.body;

    if (!user_id || !items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({
        error: 'user_id and items array are required'
      });
    }

    // Validate items
    for (const item of items) {
      if (!item.product_name || !item.quantity || !item.price) {
        return res.status(400).json({
          error: 'Each item must have product_name, quantity, and price'
        });
      }
    }

    const response = await orderService.createOrder({
      user_id: parseInt(user_id),
      items: items.map(item => ({
        product_name: item.product_name,
        quantity: parseInt(item.quantity),
        price: parseFloat(item.price)
      }))
    });

    res.status(201).json({
      success: true,
      data: response.order,
      message: response.message
    });
  } catch (error) {
    console.error('Error creating order:', error);
    
    if (error.code === 5) { // NOT_FOUND
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    res.status(500).json({
      success: false,
      error: error.details || 'Failed to create order'
    });
  }
});

// Get Order by ID
router.get('/:id', async (req, res) => {
  try {
    const id = parseInt(req.params.id);

    if (isNaN(id)) {
      return res.status(400).json({ error: 'Invalid order ID' });
    }

    const response = await orderService.getOrder({ id });

    res.json({
      success: true,
      data: response.order
    });
  } catch (error) {
    console.error('Error getting order:', error);
    
    if (error.code === 5) { // NOT_FOUND
      return res.status(404).json({
        success: false,
        error: 'Order not found'
      });
    }

    res.status(500).json({
      success: false,
      error: error.details || 'Failed to get order'
    });
  }
});

// Update Order Status
router.patch('/:id/status', async (req, res) => {
  try {
    const id = parseInt(req.params.id);
    const { status } = req.body;

    if (isNaN(id)) {
      return res.status(400).json({ error: 'Invalid order ID' });
    }

    if (status === undefined) {
      return res.status(400).json({ error: 'Status is required' });
    }

    // Accept status as string or number
    let statusValue;
    if (typeof status === 'string') {
      statusValue = OrderStatus[status.toUpperCase()];
      if (statusValue === undefined) {
        return res.status(400).json({
          error: 'Invalid status. Must be one of: PENDING, PROCESSING, SHIPPED, DELIVERED, CANCELLED'
        });
      }
    } else {
      statusValue = parseInt(status);
    }

    const response = await orderService.updateOrderStatus({
      id,
      status: statusValue
    });

    res.json({
      success: true,
      data: response.order,
      message: response.message
    });
  } catch (error) {
    console.error('Error updating order status:', error);
    
    if (error.code === 5) { // NOT_FOUND
      return res.status(404).json({
        success: false,
        error: 'Order not found'
      });
    }

    res.status(500).json({
      success: false,
      error: error.details || 'Failed to update order status'
    });
  }
});

// List Orders
router.get('/', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;

    const response = await orderService.listOrders({ page, limit });

    res.json({
      success: true,
      data: response.orders,
      pagination: {
        page,
        limit,
        total: response.total
      }
    });
  } catch (error) {
    console.error('Error listing orders:', error);
    res.status(500).json({
      success: false,
      error: error.details || 'Failed to list orders'
    });
  }
});

// Get User Orders
router.get('/user/:userId', async (req, res) => {
  try {
    const user_id = parseInt(req.params.userId);

    if (isNaN(user_id)) {
      return res.status(400).json({ error: 'Invalid user ID' });
    }

    const response = await orderService.getUserOrders({ user_id });

    res.json({
      success: true,
      data: response.orders,
      total: response.total
    });
  } catch (error) {
    console.error('Error getting user orders:', error);
    
    if (error.code === 5) { // NOT_FOUND
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    res.status(500).json({
      success: false,
      error: error.details || 'Failed to get user orders'
    });
  }
});

// Cancel Order
router.post('/:id/cancel', async (req, res) => {
  try {
    const id = parseInt(req.params.id);

    if (isNaN(id)) {
      return res.status(400).json({ error: 'Invalid order ID' });
    }

    const response = await orderService.cancelOrder({ id });

    res.json({
      success: response.success,
      message: response.message
    });
  } catch (error) {
    console.error('Error cancelling order:', error);
    
    if (error.code === 5) { // NOT_FOUND
      return res.status(404).json({
        success: false,
        error: 'Order not found'
      });
    }

    res.status(500).json({
      success: false,
      error: error.details || 'Failed to cancel order'
    });
  }
});

module.exports = router;

