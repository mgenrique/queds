PRODUCTION DEPLOYMENT
=====================

Este documento describe los pasos mínimos para arrancar el entorno de producción localmente usando los contenedores definidos en `docker-compose.yml`.

PRE-REQUISITOS
- Docker y Docker Compose instalados en la máquina.
- Archivos de configuración apropiados en `app/config` (por ejemplo `config.full`), y credenciales de base de datos correctamente configuradas.

Arrancar producción
--------------------

1. Desde la raíz del repo, arranca los servicios de producción:

```bash
./scripts/start-prod.sh
```

2. (Opcional) Ejecuta migraciones si necesitas crear o actualizar la base de datos:

```bash
./scripts/start-prod.sh --migrate
```

3. Verifica logs y estado:

```bash
docker compose -f docker-compose.yml ps
docker compose -f docker-compose.yml logs -f
```

Cómo parar producción
---------------------

Para detener y eliminar los contenedores y networks de producción:

```bash
./scripts/stop-prod.sh
```

Persistencia de la base de datos

- La base de datos usa el volumen nombrado `users_data` en `docker-compose.yml`. Por defecto `./scripts/stop-prod.sh` ejecuta `docker compose down` y no elimina volúmenes a menos que añadas `--volumes` cuando ejecutes `docker compose down` manualmente.

Deshacer y limpieza
-------------------

Para eliminar contenedores, networks y volúmenes asociados (si lo deseas):

```bash
docker compose -f docker-compose.yml down --volumes
```

Notas finales
- Estos pasos están orientados a ejecutar la pila en un entorno local (por ejemplo, staging o pruebas). Para un despliegue real en producción, usa un orquestador (Kubernetes, Nomad, ECS) o herramientas CI/CD y asegura las variables sensibles fuera del repositorio.
