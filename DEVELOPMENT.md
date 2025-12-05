DEVELOPMENT ENVIRONMENT (Dev Containers)
========================================

Resumen
-------
Este repositorio soporta un entorno de desarrollo independiente del entorno de producción usando Docker Compose y un único contenedor para editar/ejecutar código (`devcontainer`).

Objetivos cubiertos
- Separar entornos `production` / `development`.
- Mantener servicios auxiliares (Postgres, Redis) en `docker-compose.yml`.
- Añadir servicios de desarrollo `backend-dev` y `frontend-dev` sin tocar servicios de producción.
- Un único contenedor `devcontainer` para desarrollar (monta el workspace).
- Comunicación por red interna de Docker usando nombres de servicio:
  - backend (producción) → `db` (postgres)
  - backend (producción) → `redis`
  - frontend (dev) → `http://backend-dev:8000`

Archivos añadidos
- `docker-compose.yml` (se añadieron servicios `backend-dev`, `frontend-dev`, `devcontainer`)
- `.devcontainer/Dockerfile` (imagen base para VS Code devcontainer)
- `.devcontainer/devcontainer.json` (configuración del Dev Container)
- `frontend/.env.development` (Vite apunta a `backend-dev`)

Cómo usar (paso a paso)
-----------------------

Requisitos
- Docker y Docker Compose instalados.
- VS Code con extensión "Remote - Containers" (Dev Containers).

Opción A — Abrir con VS Code Dev Container (recomendado)
1. Abre VS Code en la carpeta del proyecto.
2. Ejecuta "Remote-Containers: Open Folder in Container..." y selecciona la carpeta del repo.
   - VS Code usará `.devcontainer/devcontainer.json` y levantará la `devcontainer` service junto a las dependencias del `docker-compose.yml`.
3. Espera a que el contenedor arranque. El `postStartCommand` intentará instalar dependencias básicas (`pip` y `npm`).
4. Dentro del contenedor puedes:
   - Ejecutar el backend en modo desarrollo (si quieres ejecutarlo desde el devcontainer):

```bash
# Desde /workspaces/queds/app
python app.py run -h 0.0.0.0
# o especificando el puerto 8000 (el frontend-dev espera backend en 8000)
PORT=8000 python app.py run -h 0.0.0.0
```

   - O bien usar el servicio `backend-dev` provisto por `docker-compose`:

```bash
docker compose up -d backend-dev
# revisa logs
docker compose logs -f backend-dev
```

   - Levantar el frontend-dev (Vite) con:

```bash
docker compose up -d frontend-dev
docker compose logs -f frontend-dev
```

Opción B — Levantar dependencias con docker compose (sin abrir en Dev Container)
1. Desde la raíz del repo:

```bash
docker compose up -d db redis backend-dev frontend-dev
```

2. Verifica que `db` y `redis` estén accesibles desde `backend-dev`:

```bash
docker compose logs -f backend-dev
```

Puntos importantes
- El servicio `backend-dev` expone internamente el puerto `8000` (por eso `frontend-dev` está configurado con `VITE_APP_BACKEND_URL=http://backend-dev:8000`).
- No se debe modificar o eliminar los servicios de producción (`api`, `backend`, `frontend`, `nginx`) — los servicios `*-dev` son sólo para desarrollo.
- Para editar código, usa el contenedor `devcontainer`. Ese contenedor monta el workspace y entra en la misma red Docker `api_bridge`, por lo que puede resolver `db`, `redis`, `backend-dev`, etc.

**Acceso desde la máquina host (producción vs desarrollo)**

- Producción (sistema actual): el frontend en producción se sirve detrás de `nginx` y se accede desde esta máquina por `http://localhost:6060`.
- Desarrollo (servicios `*-dev`): el frontend de desarrollo (`frontend-dev`) ahora está configurado para escuchas en el puerto `5173` y se mapea al host `5173:5173`. Por tanto, accede desde tu máquina local en:

   `http://localhost:5173`

   - Internamente, Vite corre en el contenedor y el `frontend-dev` se comunica con `backend-dev` usando la URL `http://backend-dev:8000` (nombre de servicio en la red `api_bridge`).
   - Si necesitas la API accesible desde el host (por ejemplo `http://localhost:8000`), puedo mapear `8000:8000` en `backend-dev` en `docker-compose.yml`.

- Base de datos: `db` está mapeada en el host como `15432:5432`. Entre contenedores usa el puerto `5432` y el hostname `db`.

Comandos útiles para comprobar/arrancar:

```bash
# Levantar servicios de desarrollo
docker compose up -d db redis backend-dev frontend-dev

# Reiniciar sólo frontend-dev tras cambios en compose
docker compose up -d --no-deps --build frontend-dev

# Logs
docker compose logs -f frontend-dev
docker compose logs -f backend-dev
```

**Usar Dev Container y acceder a `backend-dev`**

- **Abrir en Dev Container (VS Code)**: abre la carpeta en VS Code y ejecuta "Remote-Containers: Open Folder in Container...". El contenedor `devcontainer` levantará los servicios dependientes.
- **Desde la máquina host**: para entrar en el contenedor del backend de desarrollo usa:

```bash
# shell interactivo (salir con Ctrl+D)
docker compose exec backend-dev sh

# comando no interactivo (útil en scripts / CI)
docker compose exec -T backend-dev sh -c 'whoami; id; ps aux | head -n 20'
```

- **Ver logs del backend-dev**:

```bash
docker compose logs -f backend-dev
```

- **Probar la API desde dentro del contenedor `backend-dev`**:

```bash
docker compose exec -T backend-dev sh -c 'curl -sS http://localhost:8000/api/version || true'
```

Estas instrucciones te permiten inspeccionar procesos, variables de entorno y endpoints desde el propio contenedor `backend-dev`.

Nota: las imágenes usadas por los servicios son deliberadamente ligeras y pueden no traer utilidades como `ps`, `curl` o `bash` instaladas. Si al ejecutar alguno de los comandos anteriores obtienes `ps: not found` o `curl: not found`, usa una de estas alternativas:

- Ver logs desde el host: `docker compose logs -f backend-dev`.
- Ejecutar comandos Python (disponible en la imagen) para inspeccionar variables o probar endpoints, por ejemplo:

```bash
docker compose exec -T backend-dev python -c "import sys,os; print(sys.version); print(os.environ.get('BACKEND_SETTINGS'))"
docker compose exec -T backend-dev python -c "import urllib.request; print(urllib.request.urlopen('http://localhost:8000/api/version').read().decode())"
```

- Instalar utilidades si las necesitas (desde dentro del contenedor) con apt, ejemplo:

```bash
docker compose exec backend-dev sh -c 'apt-get update && apt-get install -y procps curl'
```

Usa la alternativa que prefieras según tus privilegios y necesidades.

**Flujo de trabajo con VS Code dentro del Dev Container (paso a paso)**

1. Abrir el proyecto en Dev Container

   - En VS Code: `Remote-Containers: Open Folder in Container...` y selecciona la carpeta del repo.
   - El `devcontainer` levantará servicios dependientes (según `.devcontainer/devcontainer.json` y `docker-compose.yml`).

2. Levantar servicios recomendados (desde el terminal integrado del Dev Container o desde host)

```bash
# desde la raíz del repo (dentro del devcontainer o desde host)
./scripts/start-dev.sh --with-devcontainer --migrate
```

3. Editar código (persistencia)

   - Edita los archivos desde VS Code. Rutas importantes:
     - Backend API: `/workspaces/queds/app/api`  (host: `./app/api`)
     - Backend worker / backend code: `/workspaces/queds/app/backend` (host: `./app/backend`)
     - Modelos / migrations: `/workspaces/queds/app/models` (host: `./app/models`)
     - Frontend: `/workspaces/queds/frontend` (host: `./frontend`)

   - Por diseño `devcontainer` monta el workspace en el host y `backend-dev` en `docker-compose.yml` monta `./app/api` en el contenedor `backend-dev`. Por tanto los cambios que hagas en VS Code dentro del Dev Container se guardan en el sistema de ficheros del host y son inmediatamente visibles para `backend-dev`.

4. Hot-reload y procesos

   - `backend-dev` ejecuta el servidor Flask en modo desarrollo (hot-reload) por lo que, al editar código en `app/api`, normalmente Flask reiniciará automáticamente y verás los cambios.
   - Si necesitas que además corra el worker (procesos en background), el script `start-dev.sh` también puede arrancar el servicio `backend` (worker). Si el worker necesita ver cambios, reinícialo con:

```bash
docker compose restart backend
```

5. Depuración (debugging) con VS Code

   - Opción A (preferida): ejecuta Flask dentro del Dev Container y usa la extensión Python para depuración (puntos de interrupción, paso a paso):

```bash
# abre terminal integrado en VS Code (en el devcontainer)
cd /workspaces/queds/app
PORT=8000 python app.py run -h 0.0.0.0
```

   - Luego en VS Code crea/usa un `launch.json` con una configuración "Attach" o "Python: Remote Attach" apuntando al proceso Python dentro del devcontainer.

   - Opción B (usar `backend-dev`): si prefieres mantener `backend-dev` como servicio, puedes abrir un terminal en VS Code y ejecutar: `docker compose exec -T backend-dev sh -c "python -m debugpy --listen 0.0.0.0:5678 --wait-for-client -m flask run --host=0.0.0.0 --port=8000"` y luego adjuntar el debugger de VS Code al puerto `5678` mapeado en el devcontainer (recomendado sólo para desarrollos avanzados).

6. Entrar en `backend-dev` para inspección rápida

```bash
docker compose exec backend-dev sh   # shell interactivo
docker compose exec -T backend-dev sh -c 'ps aux | head -n 20'  # si ps no está, ver logs o usar python
```

7. Problemas comunes y soluciones rápidas

- Problema: Vite/Flask no recarga o ves archivos antiguos.
  - Solución rápida: reinicia el servicio afectado:

```bash
docker compose restart frontend-dev
docker compose restart backend-dev
```

- Problema: utilidades faltan (`ps`, `curl`) en contenedores ligeros.
  - Solución: usar la alternativa con `python -c` para comprobar endpoints, o instalar utilidades temporalmente con `apt-get` dentro del contenedor si es necesario.

Nota sobre herramientas en `backend-dev`
-------------------------------------

Se ha añadido una etapa de build `dev` para la imagen de desarrollo y el servicio `backend-dev` se construye desde esa etapa. La imagen `backend-dev` incluye ya las siguientes herramientas útiles para desarrollo:

- `curl` — para probar endpoints HTTP desde dentro del contenedor.
- `procps` (`ps`) — para inspeccionar procesos.
- `debugpy` — para permitir la depuración remota desde VS Code.

Detalles prácticos:
- El puerto de depuración `5678` está expuesto y mapeado por defecto (`5678:5678`).
- El servicio `backend-dev` arranca por defecto con `DEBUG=1` y utiliza `debugpy` con `--wait-for-client`, de modo que esperará la conexión del debugger antes de continuar. Esto hace que la configuración de `.vscode/launch.json` "Attach to backend-dev (debugpy)" funcione sin pasos adicionales.
- Si prefieres no esperar al cliente, puedes cambiar la variable de entorno `DEBUG` a `0` en `docker-compose.yml` o ajustar el `command` del servicio.

Cómo depurar con VS Code
- Asegúrate de levantar `backend-dev` (reconstruir si hiciste cambios):

```bash
docker compose build backend-dev
docker compose up -d backend-dev
```

- En VS Code selecciona la configuración `Attach to backend-dev (debugpy)` y pulsa "Attach". La sesión se conectará al proceso Python dentro de `backend-dev`.

- Si necesitas iniciar manualmente el servidor bajo `debugpy` (sin usar la variable `DEBUG`), puedes ejecutar desde el host:

```bash
docker compose exec -T backend-dev bash -lc "python -m debugpy --listen 0.0.0.0:5678 --wait-for-client -- python app.py run -h 0.0.0.0"
```

Con esto tendrás un entorno listo para depuración remota y con utilidades convenientes ya instaladas en `backend-dev`.

8. Consejos de persistencia y permisos

- Evita crear ficheros como `root` desde dentro de contenedores si luego vas a editarlos desde el host; si ocurre, corrige permisos desde el host con `chown`/`chmod`.
- Si tu editor crea archivos temporales con otro UID, puedes configurar VS Code para usar el usuario `vscode` dentro del devcontainer (es la configuración por defecto en `.devcontainer/Dockerfile`).

9. Cierre de sesión y parar servicios

```bash
./scripts/stop-dev.sh
# o para bajar y eliminar contenedores
docker compose -f docker-compose.yml down
```

Resumen: editar en VS Code dentro del Dev Container es persistente por diseño — `backend-dev` monta el mismo árbol de código desde el host, por lo que los cambios se reflejan automáticamente en ese servicio. Si quieres, puedo añadir un `launch.json` de ejemplo en `.vscode/` para depuración Python con el devcontainer.

Depuración rápida
- Si el frontend no puede alcanzar el backend: desde dentro del contenedor devcontainer o desde el servicio frontend-dev ejecuta `curl -v http://backend-dev:8000/api/version`.
- Si la conexión a Postgres falla: revisa que `db` esté arriba y que las variables de conexión en `app/config` apunten a host `db` y puerto `5432` (la exposición a host es `15432:5432`, pero entre servicios use `5432`).

Notas finales
- Puedes adaptar el `postStartCommand` en `.devcontainer/devcontainer.json` para instalar dependencias automáticamente o usar tus propios scripts.
- Si quieres que el `devcontainer` tenga permisos docker (para arrancar containers desde dentro), ya montamos `/var/run/docker.sock`, pero ten en cuenta implicaciones de seguridad.

**Scripts útiles (start/stop)**

He incluido scripts convenientes en la carpeta `scripts/` para arrancar y parar los entornos.

- `scripts/start-dev.sh` — Arranca el entorno de desarrollo (por defecto: `db`, `redis`, `backend-dev`, `frontend-dev`).
   - Uso: `./scripts/start-dev.sh [--with-devcontainer] [--migrate]`
   - Ejemplo: `./scripts/start-dev.sh --with-devcontainer --migrate`
   - Nota: por defecto el frontend de desarrollo estará disponible en `http://localhost:5173`.
 - `scripts/stop-dev.sh` — Para y elimina los contenedores del entorno de desarrollo.
    - Uso: `./scripts/stop-dev.sh`

 - `scripts/start-prod.sh` — Arranca los servicios de producción definidos en `docker-compose.yml`.
    - Uso: `./scripts/start-prod.sh [--migrate]`
    - `--migrate` ejecuta las migraciones: `alembic -c /usr/src/models/migrations/alembic.ini upgrade head` dentro del servicio `migrate`.

 - `scripts/stop-prod.sh` — Para y elimina los contenedores de producción.
    - Uso: `./scripts/stop-prod.sh`

Ejemplos rápidos

```bash
# Levantar dev (sin devcontainer)
./scripts/start-dev.sh

# Levantar dev incluyendo el contenedor de desarrollo y aplicando migraciones
./scripts/start-dev.sh --with-devcontainer --migrate

# Ver logs (dev)
docker compose -f docker-compose.yml logs -f frontend-dev backend-dev db

# Parar dev (elimina contenedores)
./scripts/stop-dev.sh

# Levantar producción
./scripts/start-prod.sh --migrate

# Parar producción (elimina contenedores)
./scripts/stop-prod.sh
```

Seguridad y recomendaciones

- Los scripts detectan `docker compose` (v2) o `docker-compose` (legacy) y usan el disponible.
- Para desarrollo empecé exponiendo `backend-dev` en `8000:8000` para pruebas; si prefieres no exponer el backend, elimina ese `ports` del `docker-compose.yml` — con la proxy de Vite (configurada) no es necesario exponer `backend-dev`.

Persistencia de la base de datos

- La base de datos usa un volumen nombrado `users_data` definido en `docker-compose.yml`. Ese volumen es compartido entre los servicios y no se borra por defecto al parar los contenedores con `docker compose down` (a menos que uses `docker compose down --volumes`).
- Los scripts `start-dev.sh` y `start-prod.sh` están diseñados para reutilizar contenedores ya creados: si ya existe un contenedor para los servicios solicitados, el script los arrancará con `docker compose start` en lugar de recrearlos. Esto ayuda a mantener la base de datos y el estado entre arranques.

Comportamiento de los scripts respecto a imágenes y contenedores

- Por defecto los scripts no fuerzan la reconstrucción de las imágenes. Si quieres forzar un rebuild usa `docker compose build` o `docker compose up --build` manualmente.
- Los scripts arrancan contenedores existentes con `docker compose start` si detectan contenedores previos; sólo usan `docker compose up -d` cuando no hay contenedores previos para crear.


---

Mostrar la versión del backend en el frontend (Overview)
---------------------------------------------------

Durante el desarrollo puede ser útil que la UI muestre la versión que sirve el backend (por ejemplo para comprobar hot-reload). Estos son los pasos que usamos para ello sin necesidad de rebuild completo del frontend:

1. Cambiar la proxy de Vite para que en desarrollo el frontend apunte al servicio `backend-dev` (puerto 8000). Edita `frontend/vite.config.js` y ajusta la entrada `/api` a:

```js
server: {
  proxy: {
    '/api': { target: 'http://backend-dev:8000', changeOrigin: true, secure: false }
  }
}
```

2. Reiniciar el contenedor de desarrollo `frontend-dev` para que Vite vuelva a leer la configuración:

```bash
docker compose restart frontend-dev
```

3. Verificar que la proxy devuelve la versión parcheada del backend (la marca de tiempo que añade `app.py`):

```bash
curl -sS http://localhost:5173/api/version | sed -n l
# debería mostrar algo como:
# 0.1.0$
#  (patched at 2025-12-05 19:49:33)$
```

Notas:
- No es necesario reconstruir `node_modules` ni hacer un `npm run build` porque el frontend corre en modo dev (Vite) y el código está montado como volumen; sólo es necesario reiniciar el servidor dev para que recargue `vite.config.js`.
- Si prefieres que el frontend apunte al servicio de producción (`api:5000`) sólo tienes que revertir el cambio en `vite.config.js` y reiniciar `frontend-dev`.

Impacto en producción
---------------------

Cambiar `server.proxy` en `frontend/vite.config.js` afecta únicamente al servidor de desarrollo de Vite (ejecutado con `npm run dev` / `vite`). La build de producción se genera con `npm run build` y sirve archivos estáticos (por ejemplo desde `nginx` o el backend); en ese flujo la configuración `server.proxy` no se aplica.

En producción las llamadas al API dependen de cómo hayas configurado la URL de la API en el frontend (por ejemplo `import.meta.env.VITE_APP_BACKEND_URL` o rutas relativas como `/api`). Por eso:

- Si en producción el frontend y la API se sirven desde el mismo origen, usa rutas relativas (`/api`) y no necesitas ajustar nada para deploy.
- Si tu frontend consume una API en otro host en producción, configura `VITE_APP_BACKEND_URL` para apuntar al backend de producción al hacer el build (`.env.production` o variables del CI).

Recomendación práctica: deja la proxy en `vite.config.js` solo para el modo dev (o usa `command === 'serve'` para condicionar la proxy). Mantén `VITE_APP_BACKEND_URL` (o rutas relativas) como la fuente de verdad para la URL de la API en runtime/build. De este modo los cambios que hiciste para desarrollo no romperán el despliegue en producción.

