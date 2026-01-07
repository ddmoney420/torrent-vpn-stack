package health

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"github.com/ddmoney420/torrent-vpn-stack/internal/config"
)

// Status represents the health status of a service
type Status struct {
	Service   string
	Healthy   bool
	Message   string
	Timestamp time.Time
}

// VPNStatus represents VPN connection information
type VPNStatus struct {
	Connected bool
	PublicIP  string
	Provider  string
	Server    string
}

// Monitor monitors service health
type Monitor struct {
	config *config.Config
}

// NewMonitor creates a new health monitor
func NewMonitor(cfg *config.Config) *Monitor {
	return &Monitor{
		config: cfg,
	}
}

// CheckAll checks health of all services
func (m *Monitor) CheckAll(ctx context.Context) ([]Status, error) {
	var statuses []Status

	// Check VPN (Gluetun)
	if m.config.VPN.Enabled {
		vpnStatus := m.checkVPN(ctx)
		statuses = append(statuses, vpnStatus)
	}

	// Check core services
	statuses = append(statuses, m.checkService(ctx, "qBittorrent", m.config.Ports.QBittorrent))
	statuses = append(statuses, m.checkService(ctx, "SABnzbd", m.config.Ports.SABnzbd))
	statuses = append(statuses, m.checkService(ctx, "Prowlarr", m.config.Ports.Prowlarr))

	// Check media management services
	statuses = append(statuses, m.checkService(ctx, "Sonarr", m.config.Ports.Sonarr))
	statuses = append(statuses, m.checkService(ctx, "Radarr", m.config.Ports.Radarr))

	if m.config.Profiles.Music {
		statuses = append(statuses, m.checkService(ctx, "Lidarr", m.config.Ports.Lidarr))
	}

	if m.config.Profiles.Books {
		statuses = append(statuses, m.checkService(ctx, "Readarr", m.config.Ports.Readarr))
	}

	// Check request management
	if m.config.Profiles.Jellyfin {
		statuses = append(statuses, m.checkService(ctx, "Jellyseerr", m.config.Ports.Jellyseerr))
	}

	if m.config.Profiles.Plex {
		statuses = append(statuses, m.checkService(ctx, "Overseerr", m.config.Ports.Overseerr))
	}

	// Check infrastructure
	if m.config.Profiles.Dashboard {
		statuses = append(statuses, m.checkService(ctx, "Heimdall", m.config.Ports.Heimdall))
	}

	if m.config.Profiles.Proxy {
		statuses = append(statuses, m.checkService(ctx, "Traefik", m.config.Ports.Traefik))
	}

	return statuses, nil
}

// checkVPN checks VPN (Gluetun) health and connection
func (m *Monitor) checkVPN(ctx context.Context) Status {
	status := Status{
		Service:   "Gluetun (VPN)",
		Timestamp: time.Now(),
	}

	// Check Gluetun control server
	url := fmt.Sprintf("http://localhost:%d/v1/publicip/ip", m.config.Ports.GluetunControl)

	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		status.Healthy = false
		status.Message = fmt.Sprintf("Failed to create request: %v", err)
		return status
	}

	client := &http.Client{Timeout: 5 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		status.Healthy = false
		status.Message = fmt.Sprintf("Connection failed: %v", err)
		return status
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		status.Healthy = false
		status.Message = fmt.Sprintf("HTTP %d", resp.StatusCode)
		return status
	}

	// Parse public IP response
	var result struct {
		PublicIP string `json:"public_ip"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		status.Healthy = false
		status.Message = fmt.Sprintf("Failed to parse response: %v", err)
		return status
	}

	status.Healthy = true
	status.Message = fmt.Sprintf("Connected - Public IP: %s", result.PublicIP)

	return status
}

// checkService performs a basic HTTP health check on a service
func (m *Monitor) checkService(ctx context.Context, name string, port int) Status {
	status := Status{
		Service:   name,
		Timestamp: time.Now(),
	}

	url := fmt.Sprintf("http://localhost:%d", port)

	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		status.Healthy = false
		status.Message = fmt.Sprintf("Failed to create request: %v", err)
		return status
	}

	client := &http.Client{Timeout: 5 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		status.Healthy = false
		status.Message = fmt.Sprintf("Not responding: %v", err)
		return status
	}
	defer resp.Body.Close()

	status.Healthy = true
	status.Message = fmt.Sprintf("Running (HTTP %d)", resp.StatusCode)

	return status
}

// GetVPNStatus gets detailed VPN status from Gluetun
func (m *Monitor) GetVPNStatus(ctx context.Context) (*VPNStatus, error) {
	vpnStatus := &VPNStatus{}

	// Get public IP
	url := fmt.Sprintf("http://localhost:%d/v1/publicip/ip", m.config.Ports.GluetunControl)
	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	client := &http.Client{Timeout: 5 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		vpnStatus.Connected = false
		return vpnStatus, nil
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		vpnStatus.Connected = false
		return vpnStatus, nil
	}

	var result struct {
		PublicIP string `json:"public_ip"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, fmt.Errorf("failed to parse public IP: %w", err)
	}

	vpnStatus.Connected = true
	vpnStatus.PublicIP = result.PublicIP
	vpnStatus.Provider = m.config.VPN.ServiceProvider

	// Try to get detailed status
	statusURL := fmt.Sprintf("http://localhost:%d/v1/openvpn/status", m.config.Ports.GluetunControl)
	statusReq, err := http.NewRequestWithContext(ctx, "GET", statusURL, nil)
	if err == nil {
		statusResp, err := client.Do(statusReq)
		if err == nil {
			defer statusResp.Body.Close()
			if statusResp.StatusCode == http.StatusOK {
				var statusResult struct {
					Status string `json:"status"`
					Server string `json:"server,omitempty"`
				}
				if err := json.NewDecoder(statusResp.Body).Decode(&statusResult); err == nil {
					vpnStatus.Server = statusResult.Server
				}
			}
		}
	}

	return vpnStatus, nil
}

// FormatStatusTable formats status information as a table
func FormatStatusTable(statuses []Status) string {
	var result string
	result += fmt.Sprintf("%-20s %-10s %s\n", "SERVICE", "STATUS", "MESSAGE")
	result += fmt.Sprintf("%s\n", "-----------------------------------------------------------")

	for _, s := range statuses {
		statusStr := "HEALTHY"
		if !s.Healthy {
			statusStr = "UNHEALTHY"
		}
		result += fmt.Sprintf("%-20s %-10s %s\n", s.Service, statusStr, s.Message)
	}

	return result
}
