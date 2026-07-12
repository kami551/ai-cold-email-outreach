# Configuration Files Explained

**Purpose:** Line-by-line explanations of the four configuration files that make up the working n8n + Codespaces setup. This file explains WHAT each line does and WHY it's there — so you understand the configs, not just copy them.

**How to use:** Read this alongside the actual files. When you need to modify a config, refer to this file to understand what each setting does.

---

## Table of Contents

1. [.devcontainer/devcontainer.json](#devcontainerdevcontainerjson)
2. [Dockerfile](#dockerfile)
3. [docker-compose.yml](#docker-composeyml)
4. [nginx.conf](#nginxconf)
5. [Configuration Comparison Table](#configuration-comparison-table)
6. [Common Modifications](#common-modifications)

---

## .devcontainer/devcontainer.json

**Purpose:** Tells GitHub Codespaces how to build the development environment.

**Location:** `.devcontainer/devcontainer.json` (note the dot at the start of the folder name)

### The Complete File

```json
{
  "name": "n8n-codespace",
  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker:4.0.0": {
      "moby": false
    }
  },
  "forwardPorts": [5678]
}
```

### Line-by-Line Explanation

#### `"name": "n8n-codespace"`

- **What it does:** Gives the Codespace a display name
- **Why it's there:** Helps you identify the Codespace in the GitHub UI
- **Can you change it?** Yes — any string works
- **Example:** `"name": "my-n8n-dev"`

#### `"features": { ... }`

- **What it does:** Lists devcontainer features to install
- **Why it's there:** Features add capabilities to the Codespace (Docker, Python, etc.)
- **Without it:** The Codespace would have no Docker

#### `"ghcr.io/devcontainers/features/docker-in-docker:4.0.0": { "moby": false }`

- **What it does:** Installs Docker inside the Codespace (Docker-in-Docker)
- **Why version 4.0.0:** Older versions (1.0.9) don't support Ubuntu `noble` (the modern base image)
- **Why `"moby": false`:** Moby's apt archive doesn't support `noble`. Setting `false` installs Docker CE instead, which does support `noble`
- **Can you change the version?** Yes, but 4.0.0 is the current working version
- **Can you remove `"moby": false`?** ❌ No — without this, Docker installation fails on `noble`

#### `"forwardPorts": [5678]`

- **What it does:** Automatically forwards port 5678 when the Codespace starts
- **Why port 5678:** That's n8n's default port
- **Why it's there:** So you can access n8n from the browser without manually forwarding
- **Can you add more ports?** Yes: `"forwardPorts": [5678, 8080, 3000]`
- **Do you still need to set visibility to Public?** Yes — auto-forwarded ports default to Private

### What's NOT in This File (and Why)

| Setting | Why it's not here |
|---|---|
| `image` or `dockerFile` | We use the default Codespace image (Ubuntu-based) |
| `extensions` | We don't need VS Code extensions for the Codespace itself |
| `postCreateCommand` | Docker Compose handles container startup |
| `settings` | No VS Code settings need to be forced |
| `version` | Devcontainer spec doesn't use a version field |

### Common Modifications

**Add more ports:**
```json
"forwardPorts": [5678, 8080, 3000]
```

**Add VS Code extensions:**
```json
"extensions": ["ms-azuretools.vscode-docker", "redhat.vscode-yaml"]
```

**Set timezone:**
```json
"remoteEnv": {
  "TZ": "Asia/Karachi"
}
```

---

## Dockerfile

**Purpose:** Builds a custom Docker image that combines n8n with Python support.

**Location:** `Dockerfile` (in repo root, capital D, no extension)

### The Complete File

```dockerfile
# Stage 1: Build Python packages in Alpine Python image
FROM python:3.12-alpine AS python-builder

RUN pip install --no-cache-dir --root=/python-root \
    requests \
    numpy \
    pandas \
    openai \
    anthropic \
    python-dotenv \
    pyyaml \
    beautifulsoup4 \
    lxml

# Stage 2: n8n image + Python copied in
FROM n8nio/n8n:latest

USER root

# Copy Python runtime from the official Alpine Python image
COPY --from=python:3.12-alpine /usr/local/bin/python3 /usr/local/bin/python3
COPY --from=python:3.12-alpine /usr/local/bin/python3.12 /usr/local/bin/python3.12
COPY --from=python:3.12-alpine /usr/local/lib/python3.12 /usr/local/lib/python3.12
COPY --from=python:3.12-alpine /usr/local/lib/libpython3.12.so* /usr/local/lib/

# Copy installed Python packages (from the builder stage)
COPY --from=python-builder /python-root /usr/local

# Make sure Python shared library is discoverable
ENV LD_LIBRARY_PATH=/usr/local/lib

USER node
```

### Line-by-Line Explanation

#### Stage 1: The Python Builder

##### `# Stage 1: Build Python packages in Alpine Python image`
- **What it does:** Comment (ignored by Docker)
- **Why it's there:** Documentation — explains what this stage does

##### `FROM python:3.12-alpine AS python-builder`
- **What it does:** Starts a new build stage using the official Python 3.12 Alpine image
- **Why Alpine:** Both Python Alpine and n8n use musl libc (binary compatibility)
- **Why `AS python-builder`:** Names this stage so we can copy from it later
- **Why not Debian Python:** Would be incompatible with n8n's Alpine-based image

##### `RUN pip install --no-cache-dir --root=/python-root \`
- **What it does:** Installs Python packages into `/python-root` (a temporary directory)
- **Why `--no-cache-dir`:** Don't cache downloaded packages (saves space)
- **Why `--root=/python-root`:** Installs to a separate directory we can copy later
- **The `\` at the end:** Continues the command on the next line

##### The package list:
```
    requests \
    numpy \
    pandas \
    openai \
    anthropic \
    python-dotenv \
    pyyaml \
    beautifulsoup4 \
    lxml
```
- **What it does:** Lists packages to install
- **Why these packages:**
  - `requests` — HTTP requests
  - `numpy` — Numeric/array operations
  - `pandas` — DataFrames, CSV/Excel
  - `openai` — OpenAI API
  - `anthropic` — Claude API
  - `python-dotenv` — Load .env files
  - `pyyaml` — Parse YAML
  - `beautifulsoup4` — Web scraping
  - `lxml` — XML/HTML parsing
- **Can you add more?** Yes — add them to the list

#### Stage 2: The n8n Image

##### `# Stage 2: n8n image + Python copied in`
- **What it does:** Comment
- **Why it's there:** Documentation

##### `FROM n8nio/n8n:latest`
- **What it does:** Starts the second stage from the official n8n image
- **Why `:latest`:** Gets the newest n8n version
- **Can you pin a version?** Yes: `FROM n8nio/n8n:1.104.2` (recommended for production)

##### `USER root`
- **What it does:** Switches to the root user
- **Why:** We need root to copy files into system directories
- **Important:** We switch back to `node` at the end (security)

##### `COPY --from=python:3.12-alpine /usr/local/bin/python3 /usr/local/bin/python3`
- **What it does:** Copies the `python3` binary from the Python image to the n8n image
- **Why `--from=python:3.12-alpine`:** Copies from the Python image (not the builder stage)
- **Why this works:** Both images are Alpine (musl libc) — binaries are compatible

##### `COPY --from=python:3.12-alpine /usr/local/bin/python3.12 /usr/local/bin/python3.12`
- **What it does:** Copies the version-specific Python binary
- **Why:** Some scripts reference `python3.12` specifically

##### `COPY --from=python:3.12-alpine /usr/local/lib/python3.12 /usr/local/lib/python3.12`
- **What it does:** Copies the Python standard library
- **Why:** Python needs its standard library to run

##### `COPY --from=python:3.12-alpine /usr/local/lib/libpython3.12.so* /usr/local/lib/`
- **What it does:** Copies the Python shared library
- **Why:** Some Python features require the shared library
- **The `*`:** Copies all matching files (e.g., `libpython3.12.so`, `libpython3.12.so.1.0`)

##### `COPY --from=python-builder /python-root /usr/local`
- **What it does:** Copies the installed packages from the builder stage
- **Why `--from=python-builder`:** This time we copy from the builder stage (not the Python image)
- **Why `/usr/local`:** Standard location for installed packages

##### `ENV LD_LIBRARY_PATH=/usr/local/lib`
- **What it does:** Sets an environment variable
- **Why:** Tells the system where to find shared libraries (like `libpython3.12.so`)
- **Without this:** Python might fail to start with "shared library not found"

##### `USER node`
- **What it does:** Switches back to the `node` user
- **Why:** Security — n8n should not run as root
- **Important:** This MUST be the last line — n8n runs as `node`

### Why Multi-Stage Build?

The n8n Docker image is a "Docker Hardened Alpine" — it has NO package manager (`apk`, `apt-get` both fail). We can't install Python inside it.

Instead, we:
1. Use the official Python Alpine image as a "builder" (it has pip)
2. Copy pre-built Python binaries into n8n
3. Copy the installed packages from the builder

This is the standard pattern for adding tools to hardened images.

### Common Modifications

**Add more Python packages:**
```dockerfile
RUN pip install --no-cache-dir --root=/python-root \
    requests \
    numpy \
    pandas \
    openai \
    anthropic \
    python-dotenv \
    pyyaml \
    beautifulsoup4 \
    lxml \
    psycopg2-binary \    # PostgreSQL
    redis \              # Redis
    boto3                # AWS
```

**Pin n8n version:**
```dockerfile
FROM n8nio/n8n:1.104.2
```

**Use a different Python version:**
```dockerfile
FROM python:3.11-alpine AS python-builder
COPY --from=python:3.11-alpine /usr/local/bin/python3 /usr/local/bin/python3
# ... etc
```

---

## docker-compose.yml

**Purpose:** Defines the n8n + nginx services and how they connect.

**Location:** `docker-compose.yml` (in repo root)

### The Complete File

```yaml
services:
  n8n:
    build:
      context: .
      dockerfile: Dockerfile
    image: n8n-custom:latest
    container_name: n8n
    restart: unless-stopped
    expose:
      - "5678"
    environment:
      - N8N_HOST=0.0.0.0
      - N8N_PORT=5678
      - N8N_PROTOCOL=https
      - N8N_EDITOR_BASE_URL=https://curly-succotash-gx4g7x9pq47pcw6pq-5678.app.github.dev
      - WEBHOOK_URL=https://curly-succotash-gx4g7x9pq47pcw6pq-5678.app.github.dev
      - N8N_PUSH_BACKEND=websocket
      - N8N_ALLOWED_ORIGINS=*
      - N8N_SECURE_COOKIE=false
      - N8N_DIAGNOSTICS_ENABLED=false
      - GENERIC_TIMEZONE=Asia/Karachi
      - DB_TYPE=sqlite
      - DB_STORAGE=/home/node/.n8n/database.sqlite
    volumes:
      - n8n_data:/home/node/.n8n

  nginx:
    image: nginx:alpine
    container_name: n8n-nginx
    restart: unless-stopped
    ports:
      - "5678:80"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - n8n

volumes:
  n8n_data:
```

### Line-by-Line Explanation

#### Top Level

##### `services:`
- **What it does:** Defines the containers to run
- **Why it's there:** Required for Docker Compose

#### The n8n Service

##### `  n8n:`
- **What it does:** Defines a service named `n8n`
- **Why this name:** Used in nginx.conf (`proxy_pass http://n8n:5678`)

##### `    build:`
- **What it does:** Tells Compose to build from a Dockerfile (not pull an image)
- **Why:** We need the custom image with Python

##### `      context: .`
- **What it does:** Sets the build context to the current directory
- **Why:** Dockerfile is in the repo root

##### `      dockerfile: Dockerfile`
- **What it does:** Specifies which Dockerfile to use
- **Why:** Defaults to `Dockerfile` but explicit is better

##### `    image: n8n-custom:latest`
- **What it does:** Tags the built image as `n8n-custom:latest`
- **Why:** Lets you reference it later and caches the build

##### `    container_name: n8n`
- **What it does:** Names the container `n8n`
- **Why:** Easier to reference in commands (`docker logs n8n`)

##### `    restart: unless-stopped`
- **What it does:** Restarts the container unless you explicitly stop it
- **Why:** Survives crashes and Codespace wake-ups
- **Alternatives:** `no`, `always`, `on-failure`

##### `    expose:`
- **What it does:** Exposes port 5678 to OTHER containers (not to the host)
- **Why:** Nginx needs to reach n8n, but n8n shouldn't be directly accessible
- **vs `ports`:** `expose` is internal only; `ports` publishes to the host

##### `      - "5678"`
- **What it does:** Exposes port 5678
- **Why:** n8n listens on 5678

#### Environment Variables

##### `    environment:`
- **What it does:** Sets environment variables for the container
- **Why:** Configures n8n's behavior

##### `      - N8N_HOST=0.0.0.0`
- **What it does:** Tells n8n to bind to all interfaces
- **Why `0.0.0.0`:** So Nginx (in another container) can reach it
- **❌ Don't set this to your URL** — it's for binding, not identity

##### `      - N8N_PORT=5678`
- **What it does:** Sets the port n8n listens on
- **Why 5678:** n8n's default port

##### `      - N8N_PROTOCOL=https`
- **What it does:** Tells n8n it's being accessed via HTTPS
- **Why:** Codespaces uses HTTPS; n8n needs to know for generating URLs

##### `      - N8N_EDITOR_BASE_URL=https://curly-succotash-...`
- **What it does:** Tells n8n its public URL
- **Why:** n8n uses this to generate correct URLs for the frontend
- **⚠️ Must match your actual Codespace URL**

##### `      - WEBHOOK_URL=https://curly-succotash-...`
- **What it does:** Sets the URL for outgoing webhooks
- **Why:** When n8n calls external services, it uses this as the return URL
- **Note:** This does NOT fix the incoming WebSocket origin issue (that's what Nginx is for)

##### `      - N8N_PUSH_BACKEND=websocket`
- **What it does:** Enables WebSocket-based push (live updates)
- **Why:** Without this, you get "Collaboration features are disabled" warning
- **Alternative:** `sse` (but it doesn't fix the origin issue)

##### `      - N8N_ALLOWED_ORIGINS=*`
- **What it does:** Allows all origins (CORS)
- **Why:** Multiple origins access n8n (localhost, Codespace URL)
- **Note:** Doesn't bypass the WebSocket origin check (that's what Nginx is for)
- **For production:** Set specific origins instead of `*`

##### `      - N8N_SECURE_COOKIE=false`
- **What it does:** Allows cookies over non-secure connections
- **Why:** Codespaces HTTPS can have cookie issues; this fixes them
- **For production:** Set to `true` with proper HTTPS

##### `      - N8N_DIAGNOSTICS_ENABLED=false`
- **What it does:** Disables n8n's usage telemetry
- **Why:** Privacy; reduces network traffic

##### `      - GENERIC_TIMEZONE=Asia/Karachi`
- **What it does:** Sets the timezone for scheduled tasks
- **Why:** Cron triggers and time-based nodes use this
- **Change to your timezone:** `America/New_York`, `Europe/London`, etc.

##### `      - DB_TYPE=sqlite`
- **What it does:** Uses SQLite as the database
- **Why:** Simple, no extra container needed
- **Alternative:** `postgresdb` (requires a Postgres container)

##### `      - DB_STORAGE=/home/node/.n8n/database.sqlite`
- **What it does:** Sets the SQLite database file location
- **Why:** Inside the volume so data persists

#### Volumes

##### `    volumes:`
- **What it does:** Mounts volumes
- **Why:** Persistent storage

##### `      - n8n_data:/home/node/.n8n`
- **What it does:** Mounts the `n8n_data` volume at `/home/node/.n8n`
- **Why:** This is where n8n stores workflows, credentials, settings
- **Without this:** All data is lost when the container is recreated

#### The nginx Service

##### `  nginx:`
- **What it does:** Defines the nginx service
- **Why:** This is the Origin header fix

##### `    image: nginx:alpine`
- **What it does:** Uses the official Nginx Alpine image
- **Why Alpine:** Small image size (~7MB)

##### `    container_name: n8n-nginx`
- **What it does:** Names the container `n8n-nginx`
- **Why:** Easy to reference in commands

##### `    restart: unless-stopped`
- **What it does:** Same as n8n — restart unless explicitly stopped

##### `    ports:`
- **What it does:** Publishes ports to the host
- **Why:** Nginx needs to be accessible from outside (the Codespace proxy)

##### `      - "5678:80"`
- **What it does:** Maps host port 5678 to container port 80
- **Why:** Nginx listens on port 80 (default); we expose it as 5678 (n8n's standard port)
- **Format:** `host_port:container_port`

##### `    volumes:`
- **What it does:** Mounts the nginx.conf file

##### `      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro`
- **What it does:** Mounts our `nginx.conf` as Nginx's default config
- **Why:** So Nginx uses our configuration (with the Origin header fix)
- **The `:ro`:** Read-only — Nginx can't modify the file

##### `    depends_on:`
- **What it does:** Ensures n8n starts before nginx
- **Why:** Nginx needs n8n to be running to forward requests to it

##### `      - n8n`
- **What it does:** Specifies the dependency
- **Note:** This is a simple dependency (start order only). For health-checking, see "Common Modifications" below.

#### Top-Level Volumes

##### `volumes:`
- **What it does:** Defines named volumes
- **Why:** Persistent storage that survives container recreation

##### `  n8n_data:`
- **What it does:** Defines the `n8n_data` volume
- **Why:** Used by the n8n service for persistent storage
- **Without this declaration:** The volume reference in the n8n service would fail

### Common Modifications

**Add healthcheck (fixes 502 race condition):**
```yaml
  n8n:
    # ... existing config ...
    healthcheck:
      test: ["CMD-SHELL", "wget -q --spider http://localhost:5678/healthz || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s

  nginx:
    # ... existing config ...
    depends_on:
      n8n:
        condition: service_healthy
```

**Use Postgres instead of SQLite:**
```yaml
  n8n:
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=n8n
      - DB_POSTGRESDB_USER=n8n
      - DB_POSTGRESDB_PASSWORD=n8n_password

  postgres:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=n8n
      - POSTGRES_USER=n8n
      - POSTGRES_PASSWORD=n8n_password
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  n8n_data:
  postgres_data:
```

---

## nginx.conf

**Purpose:** THE ACTUAL FIX for the "Connection Lost" error. Nginx rewrites the Origin header before forwarding requests to n8n.

**Location:** `nginx.conf` (in repo root)

### The Complete File

```nginx
server {
    listen 80;
    server_name _;

    client_max_body_size 50M;

    location / {
        proxy_pass http://n8n:5678;
        proxy_http_version 1.1;

        # WebSocket upgrade (CRITICAL)
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # Force the correct Origin (THIS IS THE FIX)
        proxy_set_header Origin https://curly-succotash-gx4g7x9pq47pcw6pq-5678.app.github.dev;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket timeout settings
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }
}
```

### Line-by-Line Explanation

#### Server Block

##### `server {`
- **What it does:** Starts a server block (one virtual server)
- **Why:** Nginx can run multiple servers; this defines one

##### `    listen 80;`
- **What it does:** Listens on port 80 (HTTP default)
- **Why:** This is what the `ports: "5678:80"` in docker-compose.yml forwards to

##### `    server_name _;`
- **What it does:** Matches any hostname
- **Why:** We don't care what hostname the request uses; we handle all of them
- **The `_`:** A catch-all that never matches a real hostname (so it matches everything)

##### `    client_max_body_size 50M;`
- **What it does:** Allows request bodies up to 50MB
- **Why:** n8n workflows can have large payloads (file uploads, etc.)
- **Default:** 1MB (too small for n8n)

#### Location Block

##### `    location / {`
- **What it does:** Matches all requests (the root path)
- **Why:** We want to proxy everything to n8n

##### `        proxy_pass http://n8n:5678;`
- **What it does:** Forwards requests to n8n on port 5678
- **Why `n8n`:** This is the service name in docker-compose.yml
- **Why `5678`:** n8n listens on port 5678

##### `        proxy_http_version 1.1;`
- **What it does:** Uses HTTP/1.1 for the proxy connection
- **Why:** WebSocket requires HTTP/1.1 (HTTP/1.0 doesn't support upgrades)

#### WebSocket Headers (CRITICAL)

##### `        # WebSocket upgrade (CRITICAL)`
- **What it does:** Comment
- **Why:** Emphasizes the importance of these two lines

##### `        proxy_set_header Upgrade $http_upgrade;`
- **What it does:** Passes the `Upgrade` header from the client to n8n
- **Why:** WebSocket connections send `Upgrade: websocket` — this must reach n8n
- **Without this:** WebSocket connections fail

##### `        proxy_set_header Connection "upgrade";`
- **What it does:** Sets the `Connection` header to `upgrade`
- **Why:** Tells n8n to upgrade the connection to WebSocket
- **Without this:** Nginx closes the connection after each request (no persistent WebSocket)

#### THE FIX — Origin Header

##### `        # Force the correct Origin (THIS IS THE FIX)`
- **What it does:** Comment
- **Why:** Marks the critical line that solves "Connection Lost"

##### `        proxy_set_header Origin https://curly-succotash-...;`
- **What it does:** OVERWRITES the Origin header with the correct Codespace URL
- **Why this is the fix:**
  1. Browser sends `Origin: https://curly-succotash-...` (correct)
  2. Codespace proxy rewrites it to `Origin: localhost:5678` (WRONG)
  3. Nginx overwrites it back to `Origin: https://curly-succotash-...` (correct)
  4. n8n receives the correct Origin → WebSocket accepted → "Connection Lost" fixed
- **⚠️ Must match your actual Codespace URL**

#### Standard Proxy Headers

##### `        proxy_set_header Host $host;`
- **What it does:** Passes the original Host header
- **Why:** n8n needs to know what hostname the client used

##### `        proxy_set_header X-Real-IP $remote_addr;`
- **What it does:** Sets the real client IP
- **Why:** Without this, n8n sees Nginx's IP instead of the client's

##### `        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;`
- **What it does:** Appends the client IP to the X-Forwarded-For chain
- **Why:** Standard proxy header for tracking the original client

##### `        proxy_set_header X-Forwarded-Proto $scheme;`
- **What it does:** Tells n8n what protocol the client used
- **Why:** n8n needs to know it's behind HTTPS (Codespaces uses HTTPS)

#### Timeout Settings

##### `        # WebSocket timeout settings`
- **What it does:** Comment

##### `        proxy_read_timeout 86400s;`
- **What it does:** Sets read timeout to 24 hours (86400 seconds)
- **Why:** WebSocket connections are long-lived; default 60s would kill them
- **Without this:** WebSocket disconnects after 60 seconds of inactivity

##### `        proxy_send_timeout 86400s;`
- **What it does:** Sets send timeout to 24 hours
- **Why:** Same reason — long-lived connections

### Why This Configuration Works

```
1. Browser → Codespace Proxy
   Origin: https://curly-succotash-... (correct)

2. Codespace Proxy → Nginx
   Origin: localhost:5678 (REWRITTEN — this is the problem)

3. Nginx → n8n
   proxy_set_header Origin https://curly-succotash-... (OVERWRITTEN — this is the fix)
   Origin: https://curly-succotash-... (correct again!)

4. n8n receives correct Origin → WebSocket accepted → "Connection Lost" fixed! ✅
```

### Common Modifications

**Use environment variable for URL (advanced):**
```nginx
# In docker-compose.yml, use envsubst:
# nginx:
#   volumes:
#     - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
#   environment:
#     - CODESPACE_URL=https://...
```

**Add multiple allowed origins (advanced):**
```nginx
# Use a map to set the origin based on the incoming request
map $http_origin $allowed_origin {
    default "";
    "~https://.*\.app\.github\.dev" $http_origin;
}

server {
    # ...
    proxy_set_header Origin $allowed_origin;
}
```

---

## Configuration Comparison Table

| File | Purpose | When to Modify |
|---|---|---|
| `devcontainer.json` | Codespace setup | Adding features, changing ports |
| `Dockerfile` | Build custom n8n image | Adding Python packages, changing versions |
| `docker-compose.yml` | Define services | Adding services, changing env vars |
| `nginx.conf` | Origin header fix | Changing URL, adding headers |

### File Dependency Order

```
1. devcontainer.json  →  Creates Codespace with Docker
2. Dockerfile         →  Builds n8n image with Python
3. docker-compose.yml →  Starts n8n + nginx, references Dockerfile
4. nginx.conf         →  Mounted into nginx container, contains the fix
```

### What Each File Does NOT Do

| File | What it doesn't do |
|---|---|
| `devcontainer.json` | Doesn't install Python (Dockerfile does that) |
| `Dockerfile` | Doesn't configure n8n settings (docker-compose.yml does that) |
| `docker-compose.yml` | Doesn't fix the origin issue (nginx.conf does that) |
| `nginx.conf` | Doesn't start services (docker-compose.yml does that) |

---

## Common Modifications

### Change Timezone

In `docker-compose.yml`:
```yaml
- GENERIC_TIMEZONE=America/New_York    # or Europe/London, Asia/Tokyo, etc.
```

### Add More Python Packages

In `Dockerfile`:
```dockerfile
RUN pip install --no-cache-dir --root=/python-root \
    requests \
    numpy \
    pandas \
    # ... existing packages ...
    psycopg2-binary \    # PostgreSQL support
    redis \              # Redis support
    boto3                # AWS support
```

### Change n8n Version

In `Dockerfile`:
```dockerfile
FROM n8nio/n8n:1.104.2    # instead of :latest
```

### Add Basic Auth

In `docker-compose.yml`:
```yaml
- N8N_BASIC_AUTH_ACTIVE=true
- N8N_BASIC_AUTH_USER=admin
- N8N_BASIC_AUTH_PASSWORD=your-password
```

### Disable Community Nodes

In `docker-compose.yml`:
```yaml
- N8N_COMMUNITY_PACKAGES_ENABLED=false
```

---

## Key Takeaways

1. **Each file has a specific purpose** — don't mix concerns
2. **The Nginx `proxy_set_header Origin` line is the actual fix** — everything else is supporting infrastructure
3. **`expose` vs `ports`**: `expose` is internal, `ports` publishes to host
4. **Multi-stage Docker builds** are the professional way to add tools to hardened images
5. **Always set `USER node` at the end of the Dockerfile** — n8n should not run as root
6. **The Codespace URL must match** in both `nginx.conf` and `docker-compose.yml`
7. **`docker compose down` (without `-v`)** preserves your data in the `n8n_data` volume

---

*Last updated: July 2026*
