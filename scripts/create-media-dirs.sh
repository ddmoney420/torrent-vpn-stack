#!/usr/bin/env bash
set -euo pipefail

# Create directory structure for media stack
# Usage: ./scripts/create-media-dirs.sh [base_path]

BASE_PATH="${1:-/media-stack}"

echo "Creating media stack directory structure at: $BASE_PATH"

# Create base directories
mkdir -p "$BASE_PATH"/{media,downloads,config}

# Create media subdirectories
mkdir -p "$BASE_PATH"/media/{tv,movies,music,books}

# Create download subdirectories
mkdir -p "$BASE_PATH"/downloads/torrents/{complete,incomplete}
mkdir -p "$BASE_PATH"/downloads/usenet/{complete,incomplete}

echo "✅ Directory structure created:"
tree -L 3 "$BASE_PATH" 2>/dev/null || find "$BASE_PATH" -type d | sort

echo ""
echo "Update your .env file with:"
echo "  MEDIA_PATH=$BASE_PATH/media"
echo "  DOWNLOADS_PATH=$BASE_PATH/downloads"
