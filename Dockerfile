# Multi-stage Dockerfile for AutoBan project

# Backend build stage
FROM golang:1.21-alpine AS backend-builder
WORKDIR /backend
COPY backend/ .
RUN go mod download
RUN go build -o main .

# Frontend build stage
FROM node:18-alpine AS frontend-builder
WORKDIR /frontend
COPY frontend/package*.json ./
RUN npm ci
COPY frontend/ .
RUN npm run build

# Final runtime stage
FROM node:18-alpine
WORKDIR /app

# Install Go runtime for backend
RUN apk add --no-cache go

# Copy backend binary and config
COPY --from=backend-builder /backend/main ./backend/
COPY --from=backend-builder /backend/config ./backend/config/

# Copy frontend build
COPY --from=frontend-builder /frontend/.next ./.next
COPY --from=frontend-builder /frontend/public ./public
COPY --from=frontend-builder /frontend/package.json ./package.json
COPY --from=frontend-builder /frontend/node_modules ./node_modules

# Expose ports
EXPOSE 3000 8080

# Start both services
CMD ["sh", "-c", "cd backend && ./main & npm start"]
