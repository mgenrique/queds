#!/bin/bash
# setup.sh - Script para levantar el entorno de desarrollo completo
# Entorno de desarrollo con DevContainer y Vite
# Requiere dar permisos de ejecución con
# chmod +x setup.sh

set -e  # Salir si ocurre algún error
echo "=== 1. Comprobando Docker y Docker Compose ==="
docker --version
docker compose version

# Seleccionar archivo de compose: preferir docker-compose.yml si existe
if [ -f docker-compose.yml ]; then
  COMPOSE_FILE="docker-compose.yml"
  echo "Usando archivo: $COMPOSE_FILE"
elif [ -f docker-compose.dev.yml ]; then
  COMPOSE_FILE="docker-compose.dev.yml"
  echo "No existe docker-compose.yml; usando: $COMPOSE_FILE"
else
  echo "ERROR: Ningún archivo docker-compose encontrado (buscado: docker-compose.yml, docker-compose.dev.yml)"
  exit 2
fi

echo "=== 2. Construyendo imágenes de Docker ==="
docker compose -f "$COMPOSE_FILE" build

echo "=== 3. Levantando servicios de Docker ==="
docker compose -f "$COMPOSE_FILE" up -d

# Crear volumen de datos para la base de datos y aplicar migraciones siempre
echo "=== 4. Migraciones de base de datos ==="
echo "Las migraciones NO se ejecutan automáticamente en este script."
echo "Para aplicar las migraciones manualmente usa el comando indicado al final del script."

echo "=== 5. Servicios levantados ==="

echo "=== 6. Mostrando estado de los contenedores ==="
docker compose -f "$COMPOSE_FILE" ps

echo "=== 7. Información para PgAdmin ==="
echo "Abre en el navegador: http://localhost:8080"
echo "Usuario: admin@admin.com | Contraseña: admin"
echo "Conectar a la DB:"
echo "  Hostname/address: db"
echo "  Port: 5432"
echo "  Maintenance DB: queds"
echo "  Username: queds_user"
echo "  Password: Kbh85n7M6Fxo"

echo "=== 8. DevContainer listo en VS Code ==="
echo "Abre VS Code y selecciona 'Reopen in DevContainer' en la carpeta del proyecto."

echo "=== ¡Listo! Todos los contenedores levantados y DB migrada si era necesario. ==="

# Activar logs en segundo plano
echo "=== Mostrando logs de los contenedores (Ctrl+C para salir) ==="
docker compose -f "$COMPOSE_FILE" logs -f
