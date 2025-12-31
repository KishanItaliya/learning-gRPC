require('dotenv').config();
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');

// Import routes
const userRoutes = require('./routes/users');
const orderRoutes = require('./routes/orders');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'api-gateway',
    timestamp: new Date().toISOString()
  });
});

// API documentation endpoint
app.get('/', (req, res) => {
  res.json({
    service: 'API Gateway',
    version: '1.0.0',
    description: 'REST API Gateway for gRPC Microservices',
    endpoints: {
      users: {
        'POST /api/users': 'Create a new user',
        'GET /api/users': 'List all users (supports ?page=1&limit=10)',
        'GET /api/users/:id': 'Get user by ID',
        'PUT /api/users/:id': 'Update user',
        'DELETE /api/users/:id': 'Delete user',
        'GET /api/users/:id/validate': 'Validate user exists'
      },
      orders: {
        'POST /api/orders': 'Create a new order',
        'GET /api/orders': 'List all orders (supports ?page=1&limit=10)',
        'GET /api/orders/:id': 'Get order by ID',
        'PATCH /api/orders/:id/status': 'Update order status',
        'GET /api/orders/user/:userId': 'Get orders for specific user',
        'POST /api/orders/:id/cancel': 'Cancel an order'
      }
    },
    examples: {
      createUser: {
        method: 'POST',
        url: '/api/users',
        body: {
          name: 'John Doe',
          email: 'john@example.com',
          phone: '+1234567890',
          address: '123 Main St'
        }
      },
      createOrder: {
        method: 'POST',
        url: '/api/orders',
        body: {
          user_id: 1,
          items: [
            { product_name: 'Laptop', quantity: 1, price: 999.99 },
            { product_name: 'Mouse', quantity: 2, price: 25.50 }
          ]
        }
      }
    }
  });
});

// Routes
app.use('/api/users', userRoutes);
app.use('/api/orders', orderRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: `Cannot ${req.method} ${req.path}`,
    availableEndpoints: [
      'GET /',
      'GET /health',
      'POST /api/users',
      'GET /api/users',
      'POST /api/orders',
      'GET /api/orders'
    ]
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(err.status || 500).json({
    error: err.message || 'Internal Server Error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});

// Start server
app.listen(PORT, () => {
  console.log('='.repeat(50));
  console.log('🚀 API Gateway Server Started!');
  console.log('='.repeat(50));
  console.log(`📍 Server running on port ${PORT}`);
  console.log(`🌍 URL: http://localhost:${PORT}`);
  console.log(`📚 API Docs: http://localhost:${PORT}/`);
  console.log(`❤️  Health Check: http://localhost:${PORT}/health`);
  console.log('='.repeat(50));
  console.log('📡 Connected to gRPC Services:');
  console.log(`   User Service: ${process.env.USER_SERVICE_URL || 'localhost:50051'}`);
  console.log(`   Order Service: ${process.env.ORDER_SERVICE_URL || 'localhost:50052'}`);
  console.log('='.repeat(50));
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
  });
});

