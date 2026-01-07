package wizard

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"

	"github.com/ddmoney420/torrent-vpn-stack/internal/config"
)

// Wizard handles interactive setup
type Wizard struct {
	scanner *bufio.Scanner
	config  *config.Config
}

// New creates a new setup wizard
func New() *Wizard {
	return &Wizard{
		scanner: bufio.NewScanner(os.Stdin),
		config:  &config.Config{},
	}
}

// Run executes the interactive setup wizard
func (w *Wizard) Run() (*config.Config, error) {
	fmt.Println("╔═══════════════════════════════════════════════════════════╗")
	fmt.Println("║      Media Stack Setup Wizard - Interactive Setup        ║")
	fmt.Println("╚═══════════════════════════════════════════════════════════╝")
	fmt.Println()

	// Platform detection
	w.detectPlatform()

	// Step 1: Paths configuration
	if err := w.configurePaths(); err != nil {
		return nil, err
	}

	// Step 2: VPN configuration
	if err := w.configureVPN(); err != nil {
		return nil, err
	}

	// Step 3: Service selection
	if err := w.configureServices(); err != nil {
		return nil, err
	}

	// Step 4: Advanced settings (optional)
	if err := w.configureAdvanced(); err != nil {
		return nil, err
	}

	// Step 5: Review and confirm
	if err := w.reviewConfiguration(); err != nil {
		return nil, err
	}

	return w.config, nil
}

// detectPlatform detects the operating system
func (w *Wizard) detectPlatform() {
	fmt.Printf("Detected Platform: %s/%s\n", runtime.GOOS, runtime.GOARCH)
	fmt.Println()
}

// configurePaths sets up storage paths
func (w *Wizard) configurePaths() error {
	fmt.Println("═══ Storage Configuration ═══")
	fmt.Println()

	// Base path
	basePath := w.promptWithDefault(
		"Base directory for all media stack data",
		"/media-stack",
	)
	w.config.Paths.Base = basePath
	w.config.Paths.Media = filepath.Join(basePath, "media")
	w.config.Paths.Downloads = filepath.Join(basePath, "downloads")
	w.config.Paths.Config = filepath.Join(basePath, "config")

	fmt.Printf("\nDirectories that will be created:\n")
	fmt.Printf("  Media:     %s\n", w.config.Paths.Media)
	fmt.Printf("  Downloads: %s\n", w.config.Paths.Downloads)
	fmt.Printf("  Config:    %s\n", w.config.Paths.Config)
	fmt.Println()

	if !w.promptYesNo("Create these directories now?", true) {
		fmt.Println("Directories will need to be created manually before starting services.")
	} else {
		if err := w.createDirectories(); err != nil {
			return fmt.Errorf("failed to create directories: %w", err)
		}
		fmt.Println("✓ Directories created successfully")
	}
	fmt.Println()

	return nil
}

// configureVPN sets up VPN configuration
func (w *Wizard) configureVPN() error {
	fmt.Println("═══ VPN Configuration ═══")
	fmt.Println()

	w.config.VPN.Enabled = w.promptYesNo("Enable VPN for downloaders? (Highly recommended)", true)

	if !w.config.VPN.Enabled {
		fmt.Println("⚠️  WARNING: Running without VPN exposes your real IP address!")
		fmt.Println()
		return nil
	}

	// VPN provider
	fmt.Println("Supported VPN providers:")
	fmt.Println("  1. Mullvad")
	fmt.Println("  2. ProtonVPN")
	fmt.Println("  3. NordVPN")
	fmt.Println("  4. Other (custom)")
	fmt.Println()

	providerChoice := w.promptChoice("Select VPN provider", []string{"mullvad", "protonvpn", "nordvpn", "custom"}, "mullvad")
	w.config.VPN.ServiceProvider = providerChoice

	// VPN type
	vpnType := w.promptChoice("VPN type", []string{"wireguard", "openvpn"}, "wireguard")
	w.config.VPN.Type = vpnType

	// WireGuard configuration
	if vpnType == "wireguard" {
		fmt.Println("\nWireGuard Configuration:")
		fmt.Println("You'll need to obtain these from your VPN provider:")
		fmt.Printf("  - Mullvad: https://mullvad.net/en/account/wireguard-config\n")
		fmt.Printf("  - ProtonVPN: Account → Downloads → WireGuard\n")
		fmt.Printf("  - NordVPN: Dashboard → Manual Setup → WireGuard\n")
		fmt.Println()

		w.config.VPN.WireGuard.PrivateKey = w.prompt("WireGuard private key")
		w.config.VPN.WireGuard.Addresses = w.promptWithDefault("WireGuard addresses (CIDR)", "10.2.0.2/32")
	} else {
		// OpenVPN configuration
		fmt.Println("\nOpenVPN Configuration:")
		w.config.VPN.OpenVPN.User = w.prompt("OpenVPN username")
		w.config.VPN.OpenVPN.Password = w.promptPassword("OpenVPN password")
	}

	// Network configuration
	subnet := w.detectLocalSubnet()
	w.config.VPN.LocalSubnet = w.promptWithDefault("Local network subnet (CIDR)", subnet)

	fmt.Println("✓ VPN configuration complete")
	fmt.Println()

	return nil
}

// configureServices selects which services to enable
func (w *Wizard) configureServices() error {
	fmt.Println("═══ Service Selection ═══")
	fmt.Println()

	fmt.Println("Core services (always enabled):")
	fmt.Println("  - Gluetun (VPN)")
	fmt.Println("  - qBittorrent (Torrent client)")
	fmt.Println("  - SABnzbd (Usenet client)")
	fmt.Println("  - Prowlarr (Indexer manager)")
	fmt.Println("  - Sonarr (TV show management)")
	fmt.Println("  - Radarr (Movie management)")
	fmt.Println()

	fmt.Println("Optional services:")
	w.config.Profiles.Music = w.promptYesNo("  Enable Lidarr (Music management)?", false)
	w.config.Profiles.Books = w.promptYesNo("  Enable Readarr (Book management)?", false)
	fmt.Println()

	// Request management
	fmt.Println("Request Management (user-facing request interface):")
	fmt.Println("  - Jellyseerr: For Jellyfin media server")
	fmt.Println("  - Overseerr: For Plex media server")

	requestChoice := w.promptChoice("Select request management (or 'none')", []string{"jellyseerr", "overseerr", "none"}, "none")
	w.config.Profiles.Jellyfin = (requestChoice == "jellyseerr")
	w.config.Profiles.Plex = (requestChoice == "overseerr")
	fmt.Println()

	// Infrastructure
	fmt.Println("Infrastructure services:")
	w.config.Profiles.Dashboard = w.promptYesNo("  Enable Heimdall (Application dashboard)?", false)
	w.config.Profiles.Proxy = w.promptYesNo("  Enable Traefik (Reverse proxy with SSL)?", false)
	w.config.Profiles.Auth = w.promptYesNo("  Enable Authentik (Authentication + MFA)?", false)
	w.config.Profiles.Transcoding = w.promptYesNo("  Enable Tdarr (Media transcoding)?", false)

	fmt.Println()
	return nil
}

// configureAdvanced configures advanced settings
func (w *Wizard) configureAdvanced() error {
	fmt.Println("═══ Advanced Settings ═══")
	fmt.Println()

	if !w.promptYesNo("Configure advanced settings?", false) {
		fmt.Println("Using defaults for advanced settings.")
		w.setAdvancedDefaults()
		return nil
	}

	// User/Group IDs
	fmt.Println("\nUser and Group IDs (for file permissions):")
	puid := w.getUserID()
	pgid := w.getGroupID()

	w.config.PUID = w.promptInt("PUID (User ID)", puid)
	w.config.PGID = w.promptInt("PGID (Group ID)", pgid)

	// Timezone
	w.config.Timezone = w.promptWithDefault("Timezone", "America/Los_Angeles")

	// Traefik settings (if enabled)
	if w.config.Profiles.Proxy {
		fmt.Println("\nTraefik Configuration:")
		w.config.Traefik.Domain = w.prompt("Domain name (for SSL certificates)")
		w.config.Traefik.ACMEEmail = w.prompt("Email for Let's Encrypt notifications")
	}

	// Authentik settings (if enabled)
	if w.config.Profiles.Auth {
		fmt.Println("\nAuthentik Configuration:")
		w.config.Authentik.PostgresPassword = w.promptPassword("PostgreSQL password")
		w.config.Authentik.SecretKey = w.generateSecretKey()
		fmt.Printf("Generated Authentik secret key: %s\n", w.config.Authentik.SecretKey)
	}

	fmt.Println()
	return nil
}

// reviewConfiguration shows final configuration and confirms
func (w *Wizard) reviewConfiguration() error {
	fmt.Println("═══ Configuration Summary ═══")
	fmt.Println()

	fmt.Printf("Storage:\n")
	fmt.Printf("  Base:      %s\n", w.config.Paths.Base)
	fmt.Printf("  Media:     %s\n", w.config.Paths.Media)
	fmt.Printf("  Downloads: %s\n", w.config.Paths.Downloads)
	fmt.Println()

	fmt.Printf("VPN:\n")
	fmt.Printf("  Enabled:  %v\n", w.config.VPN.Enabled)
	if w.config.VPN.Enabled {
		fmt.Printf("  Provider: %s\n", w.config.VPN.ServiceProvider)
		fmt.Printf("  Type:     %s\n", w.config.VPN.Type)
	}
	fmt.Println()

	fmt.Printf("Services:\n")
	fmt.Printf("  Music (Lidarr):        %v\n", w.config.Profiles.Music)
	fmt.Printf("  Books (Readarr):       %v\n", w.config.Profiles.Books)
	fmt.Printf("  Jellyseerr:            %v\n", w.config.Profiles.Jellyfin)
	fmt.Printf("  Overseerr:             %v\n", w.config.Profiles.Plex)
	fmt.Printf("  Dashboard (Heimdall):  %v\n", w.config.Profiles.Dashboard)
	fmt.Printf("  Proxy (Traefik):       %v\n", w.config.Profiles.Proxy)
	fmt.Printf("  Auth (Authentik):      %v\n", w.config.Profiles.Auth)
	fmt.Printf("  Transcoding (Tdarr):   %v\n", w.config.Profiles.Transcoding)
	fmt.Println()

	if !w.promptYesNo("Proceed with this configuration?", true) {
		return fmt.Errorf("configuration cancelled by user")
	}

	// Generate .env file
	if err := w.generateEnvFile(); err != nil {
		return fmt.Errorf("failed to generate .env file: %w", err)
	}

	fmt.Println("\n✓ Configuration complete!")
	fmt.Println()
	fmt.Println("Next steps:")
	fmt.Println("  1. Review the generated .env file")
	fmt.Println("  2. Run: mediastack start")
	fmt.Println("  3. Check status: mediastack status")
	fmt.Println()

	return nil
}

// Helper methods

func (w *Wizard) prompt(question string) string {
	fmt.Printf("%s: ", question)
	w.scanner.Scan()
	return strings.TrimSpace(w.scanner.Text())
}

func (w *Wizard) promptWithDefault(question, defaultValue string) string {
	fmt.Printf("%s [%s]: ", question, defaultValue)
	w.scanner.Scan()
	value := strings.TrimSpace(w.scanner.Text())
	if value == "" {
		return defaultValue
	}
	return value
}

func (w *Wizard) promptYesNo(question string, defaultYes bool) bool {
	defaultStr := "y/N"
	if defaultYes {
		defaultStr = "Y/n"
	}

	fmt.Printf("%s [%s]: ", question, defaultStr)
	w.scanner.Scan()
	value := strings.ToLower(strings.TrimSpace(w.scanner.Text()))

	if value == "" {
		return defaultYes
	}

	return value == "y" || value == "yes"
}

func (w *Wizard) promptChoice(question string, choices []string, defaultChoice string) string {
	fmt.Printf("%s [%s]: ", question, defaultChoice)
	w.scanner.Scan()
	value := strings.ToLower(strings.TrimSpace(w.scanner.Text()))

	if value == "" {
		return defaultChoice
	}

	// Validate choice
	for _, choice := range choices {
		if value == choice {
			return value
		}
	}

	fmt.Printf("Invalid choice. Using default: %s\n", defaultChoice)
	return defaultChoice
}

func (w *Wizard) promptInt(question string, defaultValue int) int {
	defaultStr := strconv.Itoa(defaultValue)
	fmt.Printf("%s [%s]: ", question, defaultStr)
	w.scanner.Scan()
	value := strings.TrimSpace(w.scanner.Text())

	if value == "" {
		return defaultValue
	}

	intValue, err := strconv.Atoi(value)
	if err != nil {
		fmt.Printf("Invalid number. Using default: %d\n", defaultValue)
		return defaultValue
	}

	return intValue
}

func (w *Wizard) promptPassword(question string) string {
	// Note: This is a simple implementation. For production, use a proper
	// password input library that hides input.
	fmt.Printf("%s (input will be visible): ", question)
	w.scanner.Scan()
	return strings.TrimSpace(w.scanner.Text())
}

func (w *Wizard) getUserID() int {
	if runtime.GOOS == "windows" {
		return 1000
	}

	cmd := exec.Command("id", "-u")
	output, err := cmd.Output()
	if err != nil {
		return 1000
	}

	uid, err := strconv.Atoi(strings.TrimSpace(string(output)))
	if err != nil {
		return 1000
	}

	return uid
}

func (w *Wizard) getGroupID() int {
	if runtime.GOOS == "windows" {
		return 1000
	}

	cmd := exec.Command("id", "-g")
	output, err := cmd.Output()
	if err != nil {
		return 1000
	}

	gid, err := strconv.Atoi(strings.TrimSpace(string(output)))
	if err != nil {
		return 1000
	}

	return gid
}

func (w *Wizard) detectLocalSubnet() string {
	// Simple default, could be enhanced with actual network detection
	return "192.168.1.0/24"
}

func (w *Wizard) generateSecretKey() string {
	// Generate a random secret key (simple implementation)
	return fmt.Sprintf("secret_%d", os.Getpid())
}

func (w *Wizard) setAdvancedDefaults() {
	w.config.PUID = w.getUserID()
	w.config.PGID = w.getGroupID()
	w.config.Timezone = "America/Los_Angeles"
}

func (w *Wizard) createDirectories() error {
	dirs := []string{
		w.config.Paths.Base,
		filepath.Join(w.config.Paths.Media, "tv"),
		filepath.Join(w.config.Paths.Media, "movies"),
		filepath.Join(w.config.Paths.Media, "music"),
		filepath.Join(w.config.Paths.Media, "books"),
		filepath.Join(w.config.Paths.Downloads, "torrents", "complete"),
		filepath.Join(w.config.Paths.Downloads, "torrents", "incomplete"),
		filepath.Join(w.config.Paths.Downloads, "usenet", "complete"),
		filepath.Join(w.config.Paths.Downloads, "usenet", "incomplete"),
		w.config.Paths.Config,
	}

	for _, dir := range dirs {
		if err := os.MkdirAll(dir, 0755); err != nil {
			return fmt.Errorf("failed to create %s: %w", dir, err)
		}
	}

	return nil
}

func (w *Wizard) generateEnvFile() error {
	// Generate .env file from configuration
	envPath := ".env"

	f, err := os.Create(envPath)
	if err != nil {
		return fmt.Errorf("failed to create .env file: %w", err)
	}
	defer f.Close()

	fmt.Fprintf(f, "# Media Stack Configuration\n")
	fmt.Fprintf(f, "# Generated by mediastack setup wizard\n\n")

	fmt.Fprintf(f, "# General\n")
	fmt.Fprintf(f, "TZ=%s\n", w.config.Timezone)
	fmt.Fprintf(f, "PUID=%d\n", w.config.PUID)
	fmt.Fprintf(f, "PGID=%d\n\n", w.config.PGID)

	fmt.Fprintf(f, "# Paths\n")
	fmt.Fprintf(f, "BASE_PATH=%s\n", w.config.Paths.Base)
	fmt.Fprintf(f, "MEDIA_PATH=%s\n", w.config.Paths.Media)
	fmt.Fprintf(f, "DOWNLOADS_PATH=%s\n\n", w.config.Paths.Downloads)

	if w.config.VPN.Enabled {
		fmt.Fprintf(f, "# VPN Configuration\n")
		fmt.Fprintf(f, "VPN_SERVICE_PROVIDER=%s\n", w.config.VPN.ServiceProvider)
		fmt.Fprintf(f, "VPN_TYPE=%s\n", w.config.VPN.Type)

		if w.config.VPN.Type == "wireguard" {
			fmt.Fprintf(f, "WIREGUARD_PRIVATE_KEY=%s\n", w.config.VPN.WireGuard.PrivateKey)
			fmt.Fprintf(f, "WIREGUARD_ADDRESSES=%s\n", w.config.VPN.WireGuard.Addresses)
		} else {
			fmt.Fprintf(f, "OPENVPN_USER=%s\n", w.config.VPN.OpenVPN.User)
			fmt.Fprintf(f, "OPENVPN_PASSWORD=%s\n", w.config.VPN.OpenVPN.Password)
		}

		fmt.Fprintf(f, "LOCAL_SUBNET=%s\n\n", w.config.VPN.LocalSubnet)
	}

	if w.config.Profiles.Proxy {
		fmt.Fprintf(f, "# Traefik\n")
		fmt.Fprintf(f, "DOMAIN=%s\n", w.config.Traefik.Domain)
		fmt.Fprintf(f, "ACME_EMAIL=%s\n\n", w.config.Traefik.ACMEEmail)
	}

	if w.config.Profiles.Auth {
		fmt.Fprintf(f, "# Authentik\n")
		fmt.Fprintf(f, "AUTHENTIK_PG_PASS=%s\n", w.config.Authentik.PostgresPassword)
		fmt.Fprintf(f, "AUTHENTIK_SECRET_KEY=%s\n\n", w.config.Authentik.SecretKey)
	}

	fmt.Printf("✓ Configuration saved to %s\n", envPath)

	return nil
}
