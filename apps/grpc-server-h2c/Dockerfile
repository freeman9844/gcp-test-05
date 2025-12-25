# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Install protoc and protoc-gen-go
RUN apk add --no-cache protobuf-dev git

# Copy go mod files
COPY go.mod go.sum* ./
RUN go mod download

# Install protoc plugins
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@latest && \
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# Copy proto files and generate code
COPY proto/ ./proto/
RUN protoc --go_out=. --go_opt=paths=source_relative \
    --go-grpc_out=. --go-grpc_opt=paths=source_relative \
    proto/helloworld.proto

# Copy source code
COPY main.go ./

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o server .

# Runtime stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

COPY --from=builder /app/server .

EXPOSE 50051

CMD ["./server"]
