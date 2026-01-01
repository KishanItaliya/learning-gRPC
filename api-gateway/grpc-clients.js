const grpc = require('@grpc/grpc-js');
const protoLoader = require('@grpc/proto-loader');
const path = require('path');

// Load proto files
const USER_PROTO_PATH = path.join(__dirname, 'proto/user.proto');
const ORDER_PROTO_PATH = path.join(__dirname, 'proto/order.proto');

const packageDefinition = protoLoader.loadSync(
  [USER_PROTO_PATH, ORDER_PROTO_PATH],
  {
    keepCase: true,
    longs: String,
    enums: String,
    defaults: true,
    oneofs: true
  }
);

const protoDescriptor = grpc.loadPackageDefinition(packageDefinition);

// Get service URLs from environment
const USER_SERVICE_URL = process.env.USER_SERVICE_URL || 'localhost:50051';
const ORDER_SERVICE_URL = process.env.ORDER_SERVICE_URL || 'localhost:50052';

// Create gRPC clients
const userClient = new protoDescriptor.user.UserService(
  USER_SERVICE_URL,
  grpc.credentials.createInsecure()
);

const orderClient = new protoDescriptor.order.OrderService(
  ORDER_SERVICE_URL,
  grpc.credentials.createInsecure()
);

// Helper function to promisify gRPC calls
const promisifyGrpcCall = (client, method) => {
  return (request) => {
    return new Promise((resolve, reject) => {
      client[method](request, (error, response) => {
        if (error) {
          reject(error);
        } else {
          resolve(response);
        }
      });
    });
  };
};

// User Service methods
const userService = {
  createUser: promisifyGrpcCall(userClient, 'CreateUser'),
  getUser: promisifyGrpcCall(userClient, 'GetUser'),
  updateUser: promisifyGrpcCall(userClient, 'UpdateUser'),
  deleteUser: promisifyGrpcCall(userClient, 'DeleteUser'),
  listUsers: promisifyGrpcCall(userClient, 'ListUsers'),
  validateUser: promisifyGrpcCall(userClient, 'ValidateUser')
};

// Order Service methods
const orderService = {
  createOrder: promisifyGrpcCall(orderClient, 'CreateOrder'),
  getOrder: promisifyGrpcCall(orderClient, 'GetOrder'),
  updateOrderStatus: promisifyGrpcCall(orderClient, 'UpdateOrderStatus'),
  listOrders: promisifyGrpcCall(orderClient, 'ListOrders'),
  getUserOrders: promisifyGrpcCall(orderClient, 'GetUserOrders'),
  cancelOrder: promisifyGrpcCall(orderClient, 'CancelOrder')
};

module.exports = {
  userService,
  orderService
};

