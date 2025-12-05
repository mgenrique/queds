#!/usr/bin/env bash
set -euo pipefail

# Start development services (db, redis, backend-dev, frontend-dev, optional devcontainer)
# Usage: ./scripts/start-dev.sh [--with-devcontainer] [--migrate]

COMPOSE_FILE="docker-compose.yml"

DC="docker compose"
if ! $DC ps >/dev/null 2>&1; then
  DC="docker-compose"
fi

WITH_DEVCONTAINER=false
MIGRATE=false
for arg in "$@"; do
  case "$arg" in
    --with-devcontainer) WITH_DEVCONTAINER=true ;;
    --migrate) MIGRATE=true ;;
    -h|--help)
      echo "Usage: $0 [--with-devcontainer] [--migrate]" && exit 0 ;;
  esac
done

SERVICES=(db redis backend-dev backend frontend-dev)
if [ "$WITH_DEVCONTAINER" = true ]; then
  SERVICES+=(devcontainer)
fi

echo "Starting development services: ${SERVICES[*]} — recreating containers"
$DC -f "$COMPOSE_FILE" up -d "${SERVICES[@]}"

if [ "$MIGRATE" = true ]; then
  echo "Running database migrations (alembic)"
  $DC -f "$COMPOSE_FILE" run --rm migrate alembic -c /usr/src/models/migrations/alembic.ini upgrade head
fi

# Run idempotent seeder to ensure demo data exists. Non-fatal (won't stop the script on error).
echo "Running idempotent seed (if available)"
$DC -f "$COMPOSE_FILE" run --rm seed || echo "Seed step failed or returned non-zero (continuing)"

echo "Dev services started. Frontend (Vite) available at http://localhost:5173 by default." 
echo "To follow logs: $DC -f $COMPOSE_FILE logs -f frontend-dev backend-dev db" 
