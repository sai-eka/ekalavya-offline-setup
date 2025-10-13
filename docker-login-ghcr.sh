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

# ----------------------------
# Add hosts entry
# ----------------------------
HOST_ENTRY="127.0.0.1 ekalavya-files-service"

# Detect OS
OS_TYPE="$(uname -s)"

if [[ "$OS_TYPE" == "Linux" || "$OS_TYPE" == "Darwin" ]]; then
  HOSTS_FILE="/etc/hosts"
elif [[ "$OS_TYPE" == "MINGW"* || "$OS_TYPE" == "CYGWIN"* || "$OS_TYPE" == "MSYS"* ]]; then
  # Git Bash / Windows
  HOSTS_FILE="/c/Windows/System32/drivers/etc/hosts"
else
  echo "Unsupported OS: $OS_TYPE"
  exit 1
fi

# Add entry if not already present
if grep -q "$HOST_ENTRY" "$HOSTS_FILE"; then
  echo "Hosts entry already exists."
else
  echo "Adding hosts entry: $HOST_ENTRY"
  # Needs sudo on Linux/macOS, Admin on Windows
  if [[ "$OS_TYPE" == "Linux" || "$OS_TYPE" == "Darwin" ]]; then
    sudo -- sh -c "echo '$HOST_ENTRY' >> $HOSTS_FILE"
  else
    echo "$HOST_ENTRY" | tee -a "$HOSTS_FILE" >nul
    echo "You may need to run Git Bash as Administrator on Windows."
  fi
fi

echo "Done!"
