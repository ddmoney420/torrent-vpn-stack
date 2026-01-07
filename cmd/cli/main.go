package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

const version = "2.0.0-alpha"

var rootCmd = &cobra.Command{
	Use:   "mediastack",
	Short: "Full media automation stack orchestrator",
	Long: `A comprehensive media automation platform orchestrator that manages:
- VPN-protected downloaders (qBittorrent, SABnzbd)
- Media management (*arr suite: Sonarr, Radarr, Lidarr, Readarr, Prowlarr)
- Request management (Jellyseerr, Overseerr)
- Infrastructure (Traefik, Authentik, Tdarr, dashboards)

Security-first with VPN kill-switch, least-privilege defaults, and modular architecture.`,
	Version: version,
}

// init - Interactive setup wizard
var initCmd = &cobra.Command{
	Use:   "init",
	Short: "Interactive setup wizard for media stack",
	Long: `Guided setup wizard that configures:
- VPN provider credentials (Mullvad, ProtonVPN, NordVPN, etc.)
- Storage paths (media library, downloads)
- Service selection (core, music, books, request management, etc.)
- Network settings

Generates .env configuration and docker-compose commands.`,
	Run: func(cmd *cobra.Command, args []string) {
		// TODO: Import and use wizard package
		// wizard := wizard.New()
		// cfg, err := wizard.Run()
		// if err != nil {
		//     fmt.Fprintf(os.Stderr, "Setup failed: %v\n", err)
		//     os.Exit(1)
		// }
		fmt.Println("🚀 Media Stack Setup Wizard")
		fmt.Println("(Full implementation in progress - wizard module created)")
		fmt.Println("\nFor now, please:")
		fmt.Println("  1. Copy .env.mediastack.example to .env")
		fmt.Println("  2. Edit .env with your VPN credentials and paths")
		fmt.Println("  3. Run: ./scripts/create-media-dirs.sh")
		fmt.Println("  4. Run: mediastack start")
	},
}

// start - Start services
var startCmd = &cobra.Command{
	Use:   "start [service]",
	Short: "Start all services or a specific service",
	Long: `Start the media stack or individual services.

Examples:
  mediastack start              # Start all configured services
  mediastack start sonarr       # Start only Sonarr
  mediastack start --profile music  # Start with music profile`,
	Run: func(cmd *cobra.Command, args []string) {
		// TODO: Import and use compose orchestrator
		// cfg, err := config.Load()
		// if err != nil {
		//     fmt.Fprintf(os.Stderr, "Failed to load config: %v\n", err)
		//     os.Exit(1)
		// }
		//
		// orchestrator, err := compose.NewOrchestrator(cfg)
		// if err != nil {
		//     fmt.Fprintf(os.Stderr, "Failed to create orchestrator: %v\n", err)
		//     os.Exit(1)
		// }
		//
		// profiles, _ := cmd.Flags().GetStringSlice("profile")
		// service := ""
		// if len(args) > 0 {
		//     service = args[0]
		// }
		//
		// if err := orchestrator.Start(context.Background(), service, profiles); err != nil {
		//     fmt.Fprintf(os.Stderr, "Failed to start services: %v\n", err)
		//     os.Exit(1)
		// }

		if len(args) == 0 {
			fmt.Println("Starting all services...")
			fmt.Println("(Docker Compose orchestrator implementation in progress)")
			fmt.Println("\nFor now, run manually:")
			fmt.Println("  docker compose -f compose/compose.core.yml -f compose/compose.media.yml up -d")
		} else {
			fmt.Printf("Starting service: %s\n", args[0])
			fmt.Println("(Not yet implemented)")
		}
	},
}

// stop - Stop services
var stopCmd = &cobra.Command{
	Use:   "stop [service]",
	Short: "Stop all services or a specific service",
	Long: `Stop the media stack or individual services.

Examples:
  mediastack stop              # Stop all services
  mediastack stop radarr       # Stop only Radarr`,
	Run: func(cmd *cobra.Command, args []string) {
		if len(args) == 0 {
			fmt.Println("Stopping all services... (not yet implemented)")
		} else {
			fmt.Printf("Stopping service: %s (not yet implemented)\n", args[0])
		}
	},
}

// restart - Restart services
var restartCmd = &cobra.Command{
	Use:   "restart [service]",
	Short: "Restart all services or a specific service",
	Run: func(cmd *cobra.Command, args []string) {
		if len(args) == 0 {
			fmt.Println("Restarting all services... (not yet implemented)")
		} else {
			fmt.Printf("Restarting service: %s (not yet implemented)\n", args[0])
		}
	},
}

// status - Show service health
var statusCmd = &cobra.Command{
	Use:   "status",
	Short: "Show health status of all services",
	Long: `Display health status of all running services including:
- Service state (running/stopped/unhealthy)
- VPN connection status and IP
- Container resource usage
- Recent errors or warnings`,
	Run: func(cmd *cobra.Command, args []string) {
		// TODO: Import and use health monitor
		// cfg, err := config.Load()
		// if err != nil {
		//     fmt.Fprintf(os.Stderr, "Failed to load config: %v\n", err)
		//     os.Exit(1)
		// }
		//
		// monitor := health.NewMonitor(cfg)
		// statuses, err := monitor.CheckAll(context.Background())
		// if err != nil {
		//     fmt.Fprintf(os.Stderr, "Failed to check service health: %v\n", err)
		//     os.Exit(1)
		// }
		//
		// fmt.Println(health.FormatStatusTable(statuses))

		fmt.Println("Service Status Dashboard")
		fmt.Println("(Health monitoring implementation in progress)")
		fmt.Println("\nFor now, check manually:")
		fmt.Println("  docker compose -f compose/compose.core.yml ps")
	},
}

// logs - View service logs
var logsCmd = &cobra.Command{
	Use:   "logs [service]",
	Short: "View logs for services",
	Long: `View aggregated logs from services.

Examples:
  mediastack logs              # All service logs
  mediastack logs gluetun      # VPN logs only
  mediastack logs --follow     # Stream logs in real-time`,
	Run: func(cmd *cobra.Command, args []string) {
		if len(args) == 0 {
			fmt.Println("Showing all logs... (not yet implemented)")
		} else {
			fmt.Printf("Showing logs for: %s (not yet implemented)\n", args[0])
		}
	},
}

// update - Update containers
var updateCmd = &cobra.Command{
	Use:   "update [service]",
	Short: "Pull latest images and update services",
	Long: `Pull latest container images and recreate services.

Examples:
  mediastack update            # Update all services
  mediastack update sonarr     # Update only Sonarr`,
	Run: func(cmd *cobra.Command, args []string) {
		if len(args) == 0 {
			fmt.Println("Updating all services... (not yet implemented)")
		} else {
			fmt.Printf("Updating service: %s (not yet implemented)\n", args[0])
		}
	},
}

// vpn - VPN management
var vpnCmd = &cobra.Command{
	Use:   "vpn",
	Short: "VPN connection management",
}

var vpnStatusCmd = &cobra.Command{
	Use:   "status",
	Short: "Show VPN connection status and public IP",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("VPN Status: (not yet implemented)")
		fmt.Println("  Connection: Connected")
		fmt.Println("  Provider: Mullvad")
		fmt.Println("  Server: se-sto-wg-001")
		fmt.Println("  Public IP: 185.65.134.xxx")
	},
}

var vpnStartCmd = &cobra.Command{
	Use:   "start",
	Short: "Start VPN connection (Gluetun container)",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("Starting VPN... (not yet implemented)")
	},
}

var vpnStopCmd = &cobra.Command{
	Use:   "stop",
	Short: "Stop VPN connection",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("Stopping VPN... (not yet implemented)")
	},
}

// config - Configuration management
var configCmd = &cobra.Command{
	Use:   "config",
	Short: "Configuration management",
}

var configShowCmd = &cobra.Command{
	Use:   "show",
	Short: "Display current configuration",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("Current Configuration: (not yet implemented)")
	},
}

var configEditCmd = &cobra.Command{
	Use:   "edit",
	Short: "Edit configuration in $EDITOR",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("Opening configuration in editor... (not yet implemented)")
	},
}

var configValidateCmd = &cobra.Command{
	Use:   "validate",
	Short: "Validate configuration file",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("Validating configuration... (not yet implemented)")
	},
}

func init() {
	// Top-level commands
	rootCmd.AddCommand(initCmd)
	rootCmd.AddCommand(startCmd)
	rootCmd.AddCommand(stopCmd)
	rootCmd.AddCommand(restartCmd)
	rootCmd.AddCommand(statusCmd)
	rootCmd.AddCommand(logsCmd)
	rootCmd.AddCommand(updateCmd)
	rootCmd.AddCommand(vpnCmd)
	rootCmd.AddCommand(configCmd)

	// VPN subcommands
	vpnCmd.AddCommand(vpnStatusCmd)
	vpnCmd.AddCommand(vpnStartCmd)
	vpnCmd.AddCommand(vpnStopCmd)

	// Config subcommands
	configCmd.AddCommand(configShowCmd)
	configCmd.AddCommand(configEditCmd)
	configCmd.AddCommand(configValidateCmd)

	// Flags for start command
	startCmd.Flags().StringSliceP("profile", "p", []string{}, "Enable profiles (music, books, jellyfin, plex, proxy, dashboard, auth, transcoding)")

	// Flags for logs command
	logsCmd.Flags().BoolP("follow", "f", false, "Follow log output")
	logsCmd.Flags().IntP("tail", "n", 100, "Number of lines to show from the end of logs")
}

func main() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
