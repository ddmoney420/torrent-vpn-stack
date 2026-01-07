package vpn

import (
	"context"
)

// Controller defines the interface for VPN lifecycle management
type Controller interface {
	Start(ctx context.Context, cfg *Config) error
	Stop(ctx context.Context) error
	Status() (*Status, error)
	HealthCheck() error
}

// Config represents VPN configuration
type Config struct {
	Provider   string // wireguard, openvpn
	ConfigPath string // /etc/wireguard/wg0.conf
	KillSwitch bool
}

// Status represents VPN connection status
type Status struct {
	Connected bool
	PublicIP  string
	ServerIP  string
	UptimeS   int64
}
