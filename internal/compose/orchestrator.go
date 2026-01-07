package compose

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/ddmoney420/torrent-vpn-stack/internal/config"
)

// Orchestrator manages Docker Compose stacks
type Orchestrator struct {
	config      *config.Config
	projectRoot string
}

// NewOrchestrator creates a new Docker Compose orchestrator
func NewOrchestrator(cfg *config.Config) (*Orchestrator, error) {
	// Get project root (where compose files are located)
	wd, err := os.Getwd()
	if err != nil {
		return nil, fmt.Errorf("failed to get working directory: %w", err)
	}

	return &Orchestrator{
		config:      cfg,
		projectRoot: wd,
	}, nil
}

// Start starts services using Docker Compose
func (o *Orchestrator) Start(ctx context.Context, service string, profiles []string) error {
	args := o.buildComposeArgs(profiles)
	args = append(args, "up", "-d")

	if service != "" {
		args = append(args, service)
	}

	return o.runDockerCompose(ctx, args...)
}

// Stop stops services
func (o *Orchestrator) Stop(ctx context.Context, service string) error {
	args := o.buildComposeArgs(nil)
	args = append(args, "stop")

	if service != "" {
		args = append(args, service)
	}

	return o.runDockerCompose(ctx, args...)
}

// Down stops and removes containers
func (o *Orchestrator) Down(ctx context.Context) error {
	args := o.buildComposeArgs(nil)
	args = append(args, "down")

	return o.runDockerCompose(ctx, args...)
}

// Restart restarts services
func (o *Orchestrator) Restart(ctx context.Context, service string) error {
	args := o.buildComposeArgs(nil)
	args = append(args, "restart")

	if service != "" {
		args = append(args, service)
	}

	return o.runDockerCompose(ctx, args...)
}

// Pull pulls latest images
func (o *Orchestrator) Pull(ctx context.Context, service string) error {
	args := o.buildComposeArgs(nil)
	args = append(args, "pull")

	if service != "" {
		args = append(args, service)
	}

	return o.runDockerCompose(ctx, args...)
}

// Logs shows logs for services
func (o *Orchestrator) Logs(ctx context.Context, service string, follow bool, tail int) error {
	args := o.buildComposeArgs(nil)
	args = append(args, "logs")

	if follow {
		args = append(args, "-f")
	}

	if tail > 0 {
		args = append(args, fmt.Sprintf("--tail=%d", tail))
	}

	if service != "" {
		args = append(args, service)
	}

	return o.runDockerCompose(ctx, args...)
}

// PS shows service status
func (o *Orchestrator) PS(ctx context.Context) ([]byte, error) {
	args := o.buildComposeArgs(nil)
	args = append(args, "ps", "--format", "json")

	cmd := exec.CommandContext(ctx, "docker", args...)
	cmd.Dir = o.projectRoot

	return cmd.CombinedOutput()
}

// buildComposeArgs builds the base docker compose arguments
func (o *Orchestrator) buildComposeArgs(profiles []string) []string {
	args := []string{"compose"}

	// Add compose files from config
	for _, file := range o.config.Compose.Files {
		args = append(args, "-f", filepath.Join(o.projectRoot, file))
	}

	// Add additional compose files based on profiles
	if o.config.Profiles.Jellyfin || o.config.Profiles.Plex {
		args = append(args, "-f", filepath.Join(o.projectRoot, "compose/compose.request.yml"))
	}

	if o.config.Profiles.Dashboard || o.config.Profiles.DashboardAlt ||
	   o.config.Profiles.Proxy || o.config.Profiles.Auth ||
	   o.config.Profiles.Transcoding {
		args = append(args, "-f", filepath.Join(o.projectRoot, "compose/compose.infrastructure.yml"))
	}

	// Add project name
	args = append(args, "-p", o.config.Compose.ProjectName)

	// Add profile flags
	enabledProfiles := o.getEnabledProfiles()
	enabledProfiles = append(enabledProfiles, profiles...)
	for _, profile := range enabledProfiles {
		args = append(args, "--profile", profile)
	}

	return args
}

// getEnabledProfiles returns list of enabled profile names
func (o *Orchestrator) getEnabledProfiles() []string {
	var profiles []string

	if o.config.Profiles.Music {
		profiles = append(profiles, "music")
	}
	if o.config.Profiles.Books {
		profiles = append(profiles, "books")
	}
	if o.config.Profiles.Jellyfin {
		profiles = append(profiles, "jellyfin")
	}
	if o.config.Profiles.Plex {
		profiles = append(profiles, "plex")
	}
	if o.config.Profiles.Proxy {
		profiles = append(profiles, "proxy")
	}
	if o.config.Profiles.Dashboard {
		profiles = append(profiles, "dashboard")
	}
	if o.config.Profiles.DashboardAlt {
		profiles = append(profiles, "dashboard-alt")
	}
	if o.config.Profiles.Auth {
		profiles = append(profiles, "auth")
	}
	if o.config.Profiles.Transcoding {
		profiles = append(profiles, "transcoding")
	}

	return profiles
}

// runDockerCompose executes a docker compose command
func (o *Orchestrator) runDockerCompose(ctx context.Context, args ...string) error {
	cmd := exec.CommandContext(ctx, "docker", args...)
	cmd.Dir = o.projectRoot
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	fmt.Printf("Running: docker %s\n", strings.Join(args, " "))

	if err := cmd.Run(); err != nil {
		return fmt.Errorf("docker compose command failed: %w", err)
	}

	return nil
}

// CheckDockerInstalled verifies Docker is installed and accessible
func CheckDockerInstalled() error {
	cmd := exec.Command("docker", "version")
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("docker is not installed or not accessible: %w", err)
	}
	return nil
}

// CheckComposeInstalled verifies Docker Compose is installed
func CheckComposeInstalled() error {
	cmd := exec.Command("docker", "compose", "version")
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("docker compose is not installed or not accessible: %w", err)
	}
	return nil
}
