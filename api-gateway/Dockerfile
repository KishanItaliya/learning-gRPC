FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY ./api-gateway/package*.json ./

# Install dependencies
RUN npm install --production

# Copy application files
COPY ./api-gateway .

# Note: Proto files are mounted via docker-compose volume
# See docker-compose.yml: - ./proto:/app/proto:ro
# This allows dynamic proto loading at runtime

# Expose port
EXPOSE 3000

# Start the application
CMD ["npm", "start"]

