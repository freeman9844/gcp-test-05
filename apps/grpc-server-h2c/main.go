package main

import (
	"context"
	"fmt"
	"log"
	"net"
	"os"

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
	hostname, _ := os.Hostname()
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

	log.Printf("H2C gRPC server listening at %v (version: %s)", lis.Addr(), version)
	if err := s.Serve(lis); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}
