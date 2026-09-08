# ==============================================================================
# STAGE 1: Builder - Build Flutter Web Bundle
# ==============================================================================
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Enable web support
RUN flutter config --enable-web

# Copy dependency specifications first for Docker layer caching
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy full application source code
COPY . .

# Build the production Flutter Web release bundle
RUN flutter build web --release

# ==============================================================================
# STAGE 2: Runner - Serve with Nginx Alpine (Lightweight & High Performance)
# ==============================================================================
FROM nginx:1.27-alpine AS runner

# Remove default nginx static files
RUN rm -rf /usr/share/nginx/html/*

# Copy built web artifacts from the builder stage
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copy custom Nginx configuration optimized for Flutter SPA
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Health check to ensure container is healthy
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:80/healthz || exit 1

# Expose port 80
EXPOSE 80

# Start Nginx in foreground
CMD ["nginx", "-g", "daemon off;"]
