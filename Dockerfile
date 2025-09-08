# Multi-stage Dockerfile for AutoBan project

# Backend build stage
FROM golang:1.24-alpine AS backend-builder
WORKDIR /backend
COPY backend/ .
# Download deps using go.mod for better cache
RUN go mod download
# Build backend binary (static)
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o main ./cmd/app

# Frontend deps stage (prod deps only)
FROM node:18-alpine AS frontend-deps
WORKDIR /frontend
COPY frontend/package*.json ./
RUN npm ci --omit=dev

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

# Copy backend binary and config
COPY --from=backend-builder /backend/main ./backend/
COPY --from=backend-builder /backend/config ./backend/config/

# Copy frontend build
COPY --from=frontend-builder /frontend/.next ./.next
COPY --from=frontend-builder /frontend/public ./public
COPY --from=frontend-builder /frontend/package.json ./package.json
COPY --from=frontend-deps /frontend/node_modules ./node_modules

# Expose ports
EXPOSE 3000 8080

# Start both services (backend on 8080, frontend on 3000)
CMD ["sh", "-c", "cd backend && ./main & npm start"]
