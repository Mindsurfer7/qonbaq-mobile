#!/usr/bin/env bash
set -euo pipefail

SERVER="gituser@45.139.76.8"
REMOTE_DIR="/var/www/qonbaq-mobile"

# === CONFIG ===
API_BASE_URL="https://api.qonbaq.com"

echo "==> Build Flutter Web"
flutter build web --release \
  --dart-define=API_BASE_URL=${API_BASE_URL}

echo "==> Upload to server"
rsync -az --delete build/web/ "${SERVER}:${REMOTE_DIR}/"

echo "✅ Frontend deployed"
echo "API_BASE_URL=${API_BASE_URL}"