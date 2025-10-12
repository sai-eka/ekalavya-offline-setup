#!/usr/bin/env bash
# Cross-platform GitHub Container Registry login helper

# Load .env variables in a cross-platform way
if [ -f ".env" ]; then
  # macOS / Linux
  if command -v bash >/dev/null 2>&1; then
    set -a
    # shellcheck disable=SC1091
    source .env
    set +a
  fi

  # Windows Git Bash / WSL
  export $(grep -v '^#' .env | xargs)
else
  echo ".env file not found!"
  exit 1
fi

# Ensure variables exist
if [ -z "$GITHUB_USERNAME" ] || [ -z "$GITHUB_PAT" ]; then
  echo "GITHUB_USERNAME or GITHUB_PAT is missing in .env"
  exit 1
fi

# Login to ghcr.io
echo "$GITHUB_PAT" | docker login ghcr.io -u "$GITHUB_USERNAME" --password-stdin
