# Gunakan image Flutter yang sudah stabil dan siap pakai
FROM ghcr.io/cirruslabs/flutter:stable AS build-env

# Set working directory
WORKDIR /app

# Copy file project
COPY . .

# Ambil dependencies
RUN flutter pub get

# Build Flutter Web
RUN flutter build web --release

# Stage 2: Serve dengan Nginx
FROM nginx:alpine
COPY --from=build-env /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
