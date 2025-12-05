#!/usr/bin/env bash
set -euo pipefail

# Stop development services (only stop — do not remove containers/networks/volumes)
COMPOSE_FILE="docker-compose.yml"

DC="docker compose"
if ! $DC ps >/dev/null 2>&1; then
  DC="docker-compose"
fi

echo "Stopping development services — removing containers/networks"
$DC -f "$COMPOSE_FILE" down

echo "Dev services stopped and removed (use --volumes with docker compose down to also remove volumes)."
