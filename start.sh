#!/bin/bash
set -e

echo ""
echo "🧰 Checking for Docker..."
if ! command -v docker &> /dev/null; then
  echo "⚠️ Docker not found! Please install Docker Desktop first:"
  echo "👉 https://www.docker.com/get-started"
  exit 1
fi

if ! command -v docker-compose &> /dev/null; then
  echo "⚠️ docker-compose not found! Docker Desktop should include it."
  exit 1
fi

echo ""
echo "🔑 Enter your GitHub Personal Access Token (PAT) for private repos:"
echo "(This token will not be saved; it's only used for cloning)"
read -s -p "Token: " GITHUB_TOKEN
echo ""

# --- Your GitHub org name ---
ORG="ekalavya-io"

# --- List of repositories to clone ---
REPOS=(
  "ekalavya-web"
  "ekalavya-users-service"
  "ekalavya-content-service"
  "ekalavya-erp-service"
  "ekalavya-notifications-service"
  "ekalavya-files-service"
  "ekalavya-scratch-editor"
)

# --- Create project folder ---
mkdir -p project
cd project

# --- Clone repos ---
for REPO in "${REPOS[@]}"; do
  if [ -d "$REPO" ]; then
    echo "✅ $REPO already exists, skipping"
  else
    echo "⬇️ Downloading $REPO..."
    curl -L -H "Authorization: token ${GITHUB_TOKEN}" \
      -o "${REPO}.zip" \
      "https://api.github.com/repos/${ORG}/${REPO}/zipball/develop"

    mkdir "$REPO"
    unzip -q "${REPO}.zip" -d "${REPO}_tmp"
    mv ${REPO}_tmp/*/* "$REPO" 2>/dev/null || mv ${REPO}_tmp/* "$REPO"
    rm -rf "${REPO}_tmp" "${REPO}.zip"
  fi
done

echo ""
echo "🎉 All repositories cloned successfully!"

# --- Start Docker Compose ---
echo "Building Docker images and starting services..."
docker compose build --build-arg GITHUB_PAT=${GITHUB_TOKEN}

unset GITHUB_TOKEN

docker compose up -d

echo "Setup complete! All services are running."
