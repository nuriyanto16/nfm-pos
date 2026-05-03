# ─── Stage 1: Build ──────────────────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm ci --silent

# Copy source code
COPY . .

# Accept build-time variables from docker-compose (overrides .env.production)
ARG VITE_API_URL
ARG VITE_CHATBOT_URL
ENV VITE_API_URL=$VITE_API_URL
ENV VITE_CHATBOT_URL=$VITE_CHATBOT_URL

# Build (Vite will embed VITE_* env vars into the bundle)
RUN npm run build

# ─── Stage 2: Serve with Nginx ───────────────────────────────────────────────
FROM nginx:alpine

# Copy built assets
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
