.PHONY: build test lint clean release

# Go parameters
GOCMD=go
GOBUILD=$(GOCMD) build
GOTEST=$(GOCMD) test
GOMOD=$(GOCMD) mod
GOFMT=$(GOCMD) fmt
BINARY_DAEMON=build/daemon
BINARY_CLI=build/mediastack
VERSION?=2.0.0-alpha

# Build targets
# Note: daemon is currently disabled as we've pivoted to orchestration approach
build: build-cli

build-daemon:
	@echo "Building daemon..."
	@mkdir -p build
	$(GOBUILD) -o $(BINARY_DAEMON) ./cmd/daemon

build-cli:
	@echo "Building CLI..."
	@mkdir -p build
	$(GOBUILD) -o $(BINARY_CLI) ./cmd/cli

# Test
test:
	@echo "Running tests..."
	$(GOTEST) -v -race -coverprofile=coverage.out ./...

# Lint
lint:
	@echo "Running linter..."
	@which golangci-lint > /dev/null || (echo "golangci-lint not installed. Run: brew install golangci-lint" && exit 1)
	golangci-lint run ./...

# Format
fmt:
	@echo "Formatting code..."
	$(GOFMT) ./...

# Clean
clean:
	@echo "Cleaning..."
	@rm -rf build/
	@rm -f coverage.out

# Dependencies
deps:
	@echo "Downloading dependencies..."
	$(GOMOD) download
	$(GOMOD) tidy

# Release builds for multiple platforms
release:
	@echo "Building release binaries..."
	@mkdir -p build/release

	# Linux amd64
	GOOS=linux GOARCH=amd64 $(GOBUILD) -o build/release/daemon-linux-amd64 ./cmd/daemon
	GOOS=linux GOARCH=amd64 $(GOBUILD) -o build/release/mediastack-linux-amd64 ./cmd/cli

	# macOS amd64 (Intel)
	GOOS=darwin GOARCH=amd64 $(GOBUILD) -o build/release/daemon-darwin-amd64 ./cmd/daemon
	GOOS=darwin GOARCH=amd64 $(GOBUILD) -o build/release/mediastack-darwin-amd64 ./cmd/cli

	# macOS arm64 (Apple Silicon)
	GOOS=darwin GOARCH=arm64 $(GOBUILD) -o build/release/daemon-darwin-arm64 ./cmd/daemon
	GOOS=darwin GOARCH=arm64 $(GOBUILD) -o build/release/mediastack-darwin-arm64 ./cmd/cli

	# Windows amd64
	GOOS=windows GOARCH=amd64 $(GOBUILD) -o build/release/daemon-windows-amd64.exe ./cmd/daemon
	GOOS=windows GOARCH=amd64 $(GOBUILD) -o build/release/mediastack-windows-amd64.exe ./cmd/cli

	@echo "Release binaries built in build/release/"

# Run daemon locally
run-daemon: build-daemon
	@echo "Starting daemon..."
	./$(BINARY_DAEMON)

# Run CLI locally
run-cli: build-cli
	@echo "Running CLI..."
	./$(BINARY_CLI)

# Help
help:
	@echo "Available targets:"
	@echo "  build        - Build daemon and CLI"
	@echo "  test         - Run tests"
	@echo "  lint         - Run linter"
	@echo "  fmt          - Format code"
	@echo "  clean        - Remove build artifacts"
	@echo "  deps         - Download dependencies"
	@echo "  release      - Build for all platforms"
	@echo "  run-daemon   - Build and run daemon"
	@echo "  run-cli      - Build and run CLI"
