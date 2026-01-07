package config

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/spf13/viper"
)

// Config represents the media stack configuration
type Config struct {
	// General settings
	Timezone string
	PUID     int
	PGID     int

	// Paths
	Paths struct {
		Base      string
		Media     string
		Downloads string
		Config    string
	}

	// VPN configuration
	VPN struct {
		Enabled         bool
		ServiceProvider string // mullvad, protonvpn, nordvpn, etc.
		Type            string // wireguard, openvpn

		// WireGuard settings
		WireGuard struct {
			PrivateKey    string
			Addresses     string
			PublicKey     string
			PresharedKey  string
			EndpointIP    string
			EndpointPort  string
		}

		// OpenVPN settings
		OpenVPN struct {
			User     string
			Password string
		}

		// Server selection
		Server struct {
			Countries []string
			Cities    []string
			Hostnames []string
		}

		// Port forwarding
		PortForwarding struct {
			Enabled  bool
			Provider string
		}

		// Network settings
		LocalSubnet string
		TorrentPort int
	}

	// Service profiles (which optional services to enable)
	Profiles struct {
		Music       bool // Lidarr
		Books       bool // Readarr
		Jellyfin    bool // Jellyseerr
		Plex        bool // Overseerr
		Proxy       bool // Traefik
		Dashboard   bool // Heimdall
		DashboardAlt bool // Homepage
		Auth        bool // Authentik
		Transcoding bool // Tdarr
	}

	// Service ports
	Ports struct {
		GluetunControl int
		QBittorrent    int
		SABnzbd        int
		Prowlarr       int
		Sonarr         int
		Radarr         int
		Lidarr         int
		Readarr        int
		Jellyseerr     int
		Overseerr      int
		Traefik        int
		Heimdall       int
		Homepage       int
		AuthentikHTTP  int
		AuthentikHTTPS int
		TdarrServer    int
		TdarrWebUI     int
	}

	// Authentik settings (if auth profile enabled)
	Authentik struct {
		PostgresPassword string
		SecretKey        string
	}

	// Traefik settings (if proxy profile enabled)
	Traefik struct {
		Domain    string
		ACMEEmail string
	}

	// Docker Compose settings
	Compose struct {
		ProjectName string
		Files       []string // Compose files to use
	}

	// Logging
	LogLevel string
}

// Load reads configuration from file and environment variables
func Load() (*Config, error) {
	viper.SetConfigName("config")
	viper.SetConfigType("yaml")

	// Config file search paths (XDG-compliant)
	if configHome := os.Getenv("XDG_CONFIG_HOME"); configHome != "" {
		viper.AddConfigPath(filepath.Join(configHome, "mediastack"))
	}
	viper.AddConfigPath(filepath.Join(os.Getenv("HOME"), ".config", "mediastack"))
	viper.AddConfigPath(".")

	// Environment variable overrides
	viper.SetEnvPrefix("MEDIASTACK")
	viper.AutomaticEnv()

	// Set defaults
	setDefaults()

	// Read config file (optional)
	if err := viper.ReadInConfig(); err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); ok {
			// Config file not found; using defaults
			fmt.Println("No config file found, using defaults")
		} else {
			return nil, fmt.Errorf("error reading config: %w", err)
		}
	}

	var cfg Config
	if err := viper.Unmarshal(&cfg); err != nil {
		return nil, fmt.Errorf("error unmarshaling config: %w", err)
	}

	return &cfg, nil
}

func setDefaults() {
	// General
	viper.SetDefault("timezone", "America/Los_Angeles")
	viper.SetDefault("puid", 1000)
	viper.SetDefault("pgid", 1000)

	// Paths
	viper.SetDefault("paths.base", "/media-stack")
	viper.SetDefault("paths.media", "/media-stack/media")
	viper.SetDefault("paths.downloads", "/media-stack/downloads")
	viper.SetDefault("paths.config", "/media-stack/config")

	// VPN
	viper.SetDefault("vpn.enabled", true)
	viper.SetDefault("vpn.service_provider", "mullvad")
	viper.SetDefault("vpn.type", "wireguard")
	viper.SetDefault("vpn.local_subnet", "192.168.1.0/24")
	viper.SetDefault("vpn.torrent_port", 6881)
	viper.SetDefault("vpn.port_forwarding.enabled", false)

	// Profiles (all optional services disabled by default)
	viper.SetDefault("profiles.music", false)
	viper.SetDefault("profiles.books", false)
	viper.SetDefault("profiles.jellyfin", false)
	viper.SetDefault("profiles.plex", false)
	viper.SetDefault("profiles.proxy", false)
	viper.SetDefault("profiles.dashboard", false)
	viper.SetDefault("profiles.dashboard_alt", false)
	viper.SetDefault("profiles.auth", false)
	viper.SetDefault("profiles.transcoding", false)

	// Ports
	viper.SetDefault("ports.gluetun_control", 8000)
	viper.SetDefault("ports.qbittorrent", 8080)
	viper.SetDefault("ports.sabnzbd", 8081)
	viper.SetDefault("ports.prowlarr", 9696)
	viper.SetDefault("ports.sonarr", 8989)
	viper.SetDefault("ports.radarr", 7878)
	viper.SetDefault("ports.lidarr", 8686)
	viper.SetDefault("ports.readarr", 8787)
	viper.SetDefault("ports.jellyseerr", 5055)
	viper.SetDefault("ports.overseerr", 5055)
	viper.SetDefault("ports.traefik", 8083)
	viper.SetDefault("ports.heimdall", 8082)
	viper.SetDefault("ports.homepage", 3000)
	viper.SetDefault("ports.authentik_http", 9000)
	viper.SetDefault("ports.authentik_https", 9443)
	viper.SetDefault("ports.tdarr_server", 8266)
	viper.SetDefault("ports.tdarr_webui", 8265)

	// Docker Compose
	viper.SetDefault("compose.project_name", "media-stack")
	viper.SetDefault("compose.files", []string{
		"compose/compose.core.yml",
		"compose/compose.media.yml",
	})

	// Logging
	viper.SetDefault("log_level", "info")
}
