package main

import (
	"context"
	"fmt"
	"log"
	"net"
	"os"
	"os/signal"
	"syscall"

	pb "grpc-server/proto"

	"google.golang.org/grpc"
	"google.golang.org/grpc/health"
	"google.golang.org/grpc/health/grpc_health_v1"
	"google.golang.org/grpc/reflection"
)

const (
	port = ":50051"
)

// server is used to implement helloworld.GreeterServer.
type server struct {
	pb.UnimplementedGreeterServer
	version string
}

// SayHello implements helloworld.GreeterServer
func (s *server) SayHello(ctx context.Context, in *pb.HelloRequest) (*pb.HelloReply, error) {
	hostname, err := os.Hostname()
	if err != nil {
		log.Printf("Warning: failed to get hostname: %v", err)
		hostname = "unknown"
	}
	log.Printf("Received: %v", in.GetName())
	return &pb.HelloReply{
		Message:  fmt.Sprintf("Hello %s from H2C server!", in.GetName()),
		Version:  s.version,
		Hostname: hostname,
	}, nil
}

func main() {
	version := os.Getenv("VERSION")
	if version == "" {
		version = "v1"
	}

	lis, err := net.Listen("tcp", port)
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}

	s := grpc.NewServer()
	pb.RegisterGreeterServer(s, &server{version: version})

	// Register health check service
	healthServer := health.NewServer()
	grpc_health_v1.RegisterHealthServer(s, healthServer)
	healthServer.SetServingStatus("", grpc_health_v1.HealthCheckResponse_SERVING)

	// Register reflection service on gRPC server.
	reflection.Register(s)

	// Setup graceful shutdown
	go func() {
		log.Printf("H2C gRPC server listening at %v (version: %s)", lis.Addr(), version)
		if err := s.Serve(lis); err != nil {
			log.Fatalf("failed to serve: %v", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	log.Println("Shutting down gRPC server...")

	// Gracefully stop the server
	s.GracefulStop()
	log.Println("Server stopped gracefully")
}
