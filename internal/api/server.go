package api

import (
	"encoding/json"
	"net/http"

	"github.com/ddmoney420/torrent-vpn-stack/internal/config"
	"github.com/ddmoney420/torrent-vpn-stack/internal/core"
)

// Server represents the API server
type Server struct {
	config  *config.Config
	queue   *core.JobQueue
	version string
}

// NewServer creates a new API server
func NewServer(cfg *config.Config, queue *core.JobQueue, version string) *Server {
	return &Server{
		config:  cfg,
		queue:   queue,
		version: version,
	}
}

// Router returns the HTTP router
func (s *Server) Router() http.Handler {
	mux := http.NewServeMux()

	// Health and version endpoints
	mux.HandleFunc("/healthz", s.handleHealth)
	mux.HandleFunc("/version", s.handleVersion)

	// Job endpoints
	mux.HandleFunc("/api/v1/jobs", s.handleJobs)
	mux.HandleFunc("/api/v1/jobs/", s.handleJobByID)

	// Provider endpoints
	mux.HandleFunc("/api/v1/providers", s.handleProviders)

	// VPN endpoints
	mux.HandleFunc("/api/v1/vpn/status", s.handleVPNStatus)

	return mux
}

func (s *Server) handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"status": "ok",
	})
}

func (s *Server) handleVersion(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"version": s.version,
	})
}

func (s *Server) handleJobs(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		jobs := s.queue.List()
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(jobs)
	case http.MethodPost:
		// TODO: Implement job creation
		http.Error(w, "Not implemented", http.StatusNotImplemented)
	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

func (s *Server) handleJobByID(w http.ResponseWriter, r *http.Request) {
	// TODO: Extract job ID from path and implement GET/DELETE
	http.Error(w, "Not implemented", http.StatusNotImplemented)
}

func (s *Server) handleProviders(w http.ResponseWriter, r *http.Request) {
	// TODO: Implement provider listing
	providers := []map[string]interface{}{
		{"name": "http", "enabled": s.config.Providers.HTTP.Enabled},
		{"name": "bittorrent", "enabled": s.config.Providers.BitTorrent.Enabled},
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(providers)
}

func (s *Server) handleVPNStatus(w http.ResponseWriter, r *http.Request) {
	// TODO: Implement VPN status
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"enabled":   s.config.VPN.Enabled,
		"connected": false,
		"provider":  s.config.VPN.Provider,
	})
}
