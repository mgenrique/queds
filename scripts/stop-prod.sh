#!/usr/bin/env bash
set -euo pipefail

# Stop production services (only stop — do not remove containers/networks/volumes)
COMPOSE_FILE="docker-compose.yml"

DC="docker compose"
if ! $DC ps >/dev/null 2>&1; then
  DC="docker-compose"
fi

echo "Stopping production services (compose file: $COMPOSE_FILE) — removing containers/networks"
$DC -f "$COMPOSE_FILE" down

echo "Production services stopped and removed (use --volumes with docker compose down to also remove volumes)."
