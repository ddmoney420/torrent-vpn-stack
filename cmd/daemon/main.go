package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/ddmoney420/torrent-vpn-stack/internal/api"
	"github.com/ddmoney420/torrent-vpn-stack/internal/config"
	"github.com/ddmoney420/torrent-vpn-stack/internal/core"
)

const version = "2.0.0-alpha"

func main() {
	log.Printf("Media Downloader Daemon v%s starting...", version)

	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	// Initialize job queue
	queue := core.NewJobQueue(cfg.Downloads.ConcurrentJobs)
	defer queue.Stop()

	// Initialize API server
	apiServer := api.NewServer(cfg, queue, version)

	// Start HTTP server
	srv := &http.Server{
		Addr:    fmt.Sprintf("%s:%d", cfg.Server.Host, cfg.Server.Port),
		Handler: apiServer.Router(),
	}

	// Graceful shutdown handling
	go func() {
		log.Printf("API server listening on %s", srv.Addr)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("HTTP server error: %v", err)
		}
	}()

	// Wait for interrupt signal
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down daemon...")

	// Graceful shutdown with 30s timeout
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}

	log.Println("Daemon stopped")
}
