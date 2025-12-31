# AWS Deployment Guide

## Architecture Overview

```
Internet → ALB → ECS Fargate Cluster
                  ├── User Service (Task)
                  ├── Order Service (Task)
                  └── API Gateway (Task)
                         ↓
                    RDS PostgreSQL
```

## Prerequisites

- AWS Account
- AWS CLI configured
- Docker installed locally
- ECR repositories created

## Option 1: AWS ECS Fargate (Recommended)

### Step 1: Create ECR Repositories

```bash
# Create repositories for each service
aws ecr create-repository --repository-name user-service
aws ecr create-repository --repository-name order-service
aws ecr create-repository --repository-name api-gateway

# Get login token
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
```

### Step 2: Build and Push Docker Images

```bash
# Build images
docker build -t user-service ./user-service
docker build -t order-service ./order-service
docker build -t api-gateway ./api-gateway

# Tag images
docker tag user-service:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/user-service:latest
docker tag order-service:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/order-service:latest
docker tag api-gateway:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/api-gateway:latest

# Push images
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/user-service:latest
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/order-service:latest
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/api-gateway:latest
```

### Step 3: Create RDS PostgreSQL Instance

```bash
# Create RDS instance
aws rds create-db-instance \
  --db-instance-identifier grpc-microservices-db \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version 15.3 \
  --master-username postgres \
  --master-user-password <your-password> \
  --allocated-storage 20 \
  --vpc-security-group-ids <security-group-id> \
  --db-subnet-group-name <subnet-group> \
  --publicly-accessible \
  --backup-retention-period 7

# Create databases
psql -h <rds-endpoint> -U postgres
CREATE DATABASE userdb;
CREATE DATABASE orderdb;
```

### Step 4: Create ECS Cluster

```bash
# Create ECS cluster
aws ecs create-cluster --cluster-name grpc-microservices-cluster
```

### Step 5: Create Task Definitions

**user-service-task.json:**
```json
{
  "family": "user-service",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [
    {
      "name": "user-service",
      "image": "<account-id>.dkr.ecr.us-east-1.amazonaws.com/user-service:latest",
      "portMappings": [
        {
          "containerPort": 50051,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {"name": "DB_HOST", "value": "<rds-endpoint>"},
        {"name": "DB_PORT", "value": "5432"},
        {"name": "DB_USER", "value": "postgres"},
        {"name": "DB_PASSWORD", "value": "<password>"},
        {"name": "DB_NAME", "value": "userdb"},
        {"name": "GRPC_PORT", "value": "50051"}
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/user-service",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

**order-service-task.json:**
```json
{
  "family": "order-service",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [
    {
      "name": "order-service",
      "image": "<account-id>.dkr.ecr.us-east-1.amazonaws.com/order-service:latest",
      "portMappings": [
        {
          "containerPort": 50052,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {"name": "DB_HOST", "value": "<rds-endpoint>"},
        {"name": "DB_PORT", "value": "5432"},
        {"name": "DB_USER", "value": "postgres"},
        {"name": "DB_PASSWORD", "value": "<password>"},
        {"name": "DB_NAME", "value": "orderdb"},
        {"name": "GRPC_PORT", "value": "50052"},
        {"name": "USER_SERVICE_URL", "value": "user-service.local:50051"}
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/order-service",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

**api-gateway-task.json:**
```json
{
  "family": "api-gateway",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [
    {
      "name": "api-gateway",
      "image": "<account-id>.dkr.ecr.us-east-1.amazonaws.com/api-gateway:latest",
      "portMappings": [
        {
          "containerPort": 3000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {"name": "PORT", "value": "3000"},
        {"name": "USER_SERVICE_URL", "value": "user-service.local:50051"},
        {"name": "ORDER_SERVICE_URL", "value": "order-service.local:50052"}
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/api-gateway",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

Register task definitions:
```bash
aws ecs register-task-definition --cli-input-json file://user-service-task.json
aws ecs register-task-definition --cli-input-json file://order-service-task.json
aws ecs register-task-definition --cli-input-json file://api-gateway-task.json
```

### Step 6: Create Services with Service Discovery

```bash
# Create Cloud Map namespace
aws servicediscovery create-private-dns-namespace \
  --name local \
  --vpc <vpc-id>

# Create services with service discovery
aws ecs create-service \
  --cluster grpc-microservices-cluster \
  --service-name user-service \
  --task-definition user-service \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[<subnet-1>,<subnet-2>],securityGroups=[<sg-id>],assignPublicIp=ENABLED}" \
  --service-registries "registryArn=<service-discovery-arn>"

aws ecs create-service \
  --cluster grpc-microservices-cluster \
  --service-name order-service \
  --task-definition order-service \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[<subnet-1>,<subnet-2>],securityGroups=[<sg-id>],assignPublicIp=ENABLED}" \
  --service-registries "registryArn=<service-discovery-arn>"
```

### Step 7: Create Application Load Balancer

```bash
# Create ALB
aws elbv2 create-load-balancer \
  --name grpc-microservices-alb \
  --subnets <subnet-1> <subnet-2> \
  --security-groups <sg-id>

# Create target group
aws elbv2 create-target-group \
  --name api-gateway-tg \
  --protocol HTTP \
  --port 3000 \
  --vpc-id <vpc-id> \
  --target-type ip

# Create listener
aws elbv2 create-listener \
  --load-balancer-arn <alb-arn> \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=<target-group-arn>

# Create API Gateway service with ALB
aws ecs create-service \
  --cluster grpc-microservices-cluster \
  --service-name api-gateway \
  --task-definition api-gateway \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[<subnet-1>,<subnet-2>],securityGroups=[<sg-id>]}" \
  --load-balancers "targetGroupArn=<target-group-arn>,containerName=api-gateway,containerPort=3000"
```

## Option 2: AWS EKS (Kubernetes)

### Step 1: Create EKS Cluster

```bash
eksctl create cluster \
  --name grpc-microservices \
  --region us-east-1 \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 1 \
  --nodes-max 4
```

### Step 2: Deploy Services

**user-service-deployment.yaml:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
    spec:
      containers:
      - name: user-service
        image: <account-id>.dkr.ecr.us-east-1.amazonaws.com/user-service:latest
        ports:
        - containerPort: 50051
        env:
        - name: DB_HOST
          value: "<rds-endpoint>"
        - name: DB_PORT
          value: "5432"
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: password
        - name: DB_NAME
          value: "userdb"
---
apiVersion: v1
kind: Service
metadata:
  name: user-service
spec:
  selector:
    app: user-service
  ports:
  - port: 50051
    targetPort: 50051
```

Apply deployments:
```bash
kubectl apply -f user-service-deployment.yaml
kubectl apply -f order-service-deployment.yaml
kubectl apply -f api-gateway-deployment.yaml
```

### Step 3: Expose API Gateway

```bash
kubectl expose deployment api-gateway --type=LoadBalancer --port=80 --target-port=3000
```

## Cost Optimization

- Use **t3.micro** for RDS (development)
- Use **Fargate Spot** for non-production
- Enable **auto-scaling** based on CPU/memory
- Use **reserved instances** for production

## Monitoring

```bash
# CloudWatch Logs
aws logs tail /ecs/user-service --follow
aws logs tail /ecs/order-service --follow
aws logs tail /ecs/api-gateway --follow
```

## Cleanup

```bash
# Delete ECS services
aws ecs delete-service --cluster grpc-microservices-cluster --service user-service --force
aws ecs delete-service --cluster grpc-microservices-cluster --service order-service --force
aws ecs delete-service --cluster grpc-microservices-cluster --service api-gateway --force

# Delete cluster
aws ecs delete-cluster --cluster grpc-microservices-cluster

# Delete RDS
aws rds delete-db-instance --db-instance-identifier grpc-microservices-db --skip-final-snapshot
```

