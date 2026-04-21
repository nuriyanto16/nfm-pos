# Build stage
FROM golang:alpine AS build

WORKDIR /app

# Copy go mod and sum files
COPY go.mod go.sum ./

# Download all dependencies.
RUN go mod download

# Copy the source code.
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -o main ./cmd/api

# Final stage
FROM alpine:edge
RUN apk add --no-cache tzdata

WORKDIR /root/

COPY --from=build /app/main .

EXPOSE 8080

CMD ["./main"]
