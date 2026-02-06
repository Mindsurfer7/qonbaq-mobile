#!/usr/bin/env bash
set -euo pipefail

SERVER="gituser@45.139.76.8"
REMOTE_DIR="/var/www/dev-qonbaq-mobile"
CONFIG_FILE=".env"

# Функция для чтения конфигурации и генерации --dart-define параметров
build_dart_defines() {
  local dart_defines=""
  
  if [ ! -f "$CONFIG_FILE" ]; then
    echo "⚠️  Warning: $CONFIG_FILE not found, using defaults"
    return
  fi
  
  while IFS= read -r line || [ -n "$line" ]; do
    # Пропускаем пустые строки и комментарии
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    
    # Убираем пробелы в начале и конце
    line=$(echo "$line" | xargs)
    
    # Пропускаем пустые строки после trim
    [[ -z "$line" ]] && continue
    
    # Проверяем формат KEY=VALUE
    if [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*=.*$ ]]; then
      if [ -z "$dart_defines" ]; then
        dart_defines="--dart-define=$line"
      else
        dart_defines="$dart_defines --dart-define=$line"
      fi
    else
      echo "⚠️  Warning: Invalid line format in $CONFIG_FILE: $line" >&2
    fi
  done < "$CONFIG_FILE"
  
  echo "$dart_defines"
}

# Генерируем параметры --dart-define из конфигурационного файла
DART_DEFINES=$(build_dart_defines)

echo "==> Build Flutter Web (DEV)"
if [ -z "$DART_DEFINES" ]; then
  echo "⚠️  No dart-define parameters found, building without them"
  flutter build web --release
else
  echo "📦 Using dart-define parameters from $CONFIG_FILE"
  flutter build web --release $DART_DEFINES
fi

echo "==> Upload to server (DEV: $REMOTE_DIR)"
rsync -az --delete build/web/ "${SERVER}:${REMOTE_DIR}/"

echo "✅ Frontend deployed to DEV"
if [ -f "$CONFIG_FILE" ]; then
  echo "📋 Used configuration from $CONFIG_FILE:"
  grep -v '^[[:space:]]*#' "$CONFIG_FILE" | grep -v '^[[:space:]]*$' | while IFS= read -r line; do
    echo "   $line"
  done
fi
