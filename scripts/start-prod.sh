#!/usr/bin/env bash
set -euo pipefail

# Start production services using docker compose (production config = docker-compose.yml)
# Usage: ./scripts/start-prod.sh [--migrate] [--build]

COMPOSE_FILE="docker-compose.yml"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is not installed or not on PATH" >&2
  exit 1
fi

DC="docker compose"
if ! $DC ps >/dev/null 2>&1; then
  # fallback to legacy docker-compose
  DC="docker-compose"
fi

MIGRATE=false
BUILD=false
for arg in "$@"; do
  case "$arg" in
    --migrate) MIGRATE=true ;;
    --build) BUILD=true ;;
    -h|--help)
      echo "Usage: $0 [--migrate]" && exit 0 ;;
  esac
done

echo "Starting production services (compose file: $COMPOSE_FILE) — recreating containers"
if [ "$BUILD" = true ]; then
  echo "Forzando build de imágenes (--build)"
  $DC -f "$COMPOSE_FILE" up -d --build
else
  $DC -f "$COMPOSE_FILE" up -d
fi

if [ "$MIGRATE" = true ]; then
  echo "Running database migrations (alembic)"
  $DC -f "$COMPOSE_FILE" run --rm migrate alembic -c /usr/src/models/migrations/alembic.ini upgrade head
fi

echo "Production services started. Check logs with: $DC -f $COMPOSE_FILE logs -f"
