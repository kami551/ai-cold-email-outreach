# Setup Guide: n8n in GitHub Codespaces (From Scratch)

**Purpose:** Complete step-by-step guide to set up n8n with Python support in a GitHub Codespace, including the Nginx reverse proxy fix for the "Connection Lost" Origin header bug.

**Use this when:** You're creating a NEW Codespace, setting up n8n on a different repo, or starting over from scratch.

**Estimated time:** 30–45 minutes (first time), 10 minutes (once familiar)

---

## Prerequisites

Before you begin, make sure you have:

1. A GitHub account (free or Pro)
2. A repository (existing or new) where you'll set up n8n
3. Basic terminal familiarity (you can run commands in a shell)
4. A web browser (Chrome, Firefox, or Edge)

That's it. No local Docker installation needed — everything runs in the Codespace.

---

## Architecture Overview

Here's what we're building:

```
Browser
  │
  ▼
GitHub Codespace Proxy (rewrites Origin header — causes the bug)
  │
  ▼
Nginx container (port 5678 → 80)     ← THE FIX: rewrites Origin back
  │   proxy_set_header Origin https://<codespace-url>;
  ▼
n8n container (port 5678, internal only)
  │
  ▼
SQLite database (in n8n_data volume — persists across restarts)
```

**Files we'll create:**
```
.devcontainer/
  └── devcontainer.json     ← Codespace config (Docker-in-Docker feature)
Dockerfile                  ← Multi-stage build: adds Python to n8n image
docker-compose.yml          ← Defines n8n + nginx services
nginx.conf                  ← The Origin header rewrite (the actual fix)
```

---

## Step 1: Create the Codespace

### 1.1 Create a new Codespace

1. Go to: https://github.com/codespaces
2. Click **"New codespace"**
3. Select your repository
4. Choose the branch (or create a new one)
5. Click **"Create codespace"**

Wait 1–2 minutes for the Codespace to initialize.

### 1.2 Create the .devcontainer/devcontainer.json file

In your Codespace:

1. Create a folder named `.devcontainer` (note the dot at the start)
2. Inside it, create a file named `devcontainer.json`
3. Paste this content:

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

**Why these settings:**
- `docker-in-docker:4.0.0` — Lets you run Docker inside the Codespace. Version 4.0.0 supports Ubuntu `noble` (older versions fail).
- `"moby": false` — Installs Docker CE instead of Moby. Required because the Moby archive doesn't support `noble`.
- `forwardPorts: [5678]` — Automatically forwards n8n's port so you can access it in a browser.

### 1.3 Rebuild the Codespace to apply the feature

1. Press **Ctrl+Shift+P** (Command Palette)
2. Type: **"Codespaces: Rebuild Container"**
3. Press Enter, confirm
4. Wait 3–4 minutes for the rebuild

### Verification for Step 1

Run this in the terminal:

```bash
docker version
```

You should see Docker version info (no errors). If you see "Cannot connect to the Docker daemon", the feature didn't install — recheck your `devcontainer.json`.

---

## Step 2: Create the Dockerfile

The Dockerfile adds Python to the n8n image using a multi-stage build (because the modern n8n image is a "Docker Hardened Alpine" with no package manager).

### 2.1 Create the file

In the **repo root** (NOT inside any folder), create a file named `Dockerfile` (capital D, no extension).

### 2.2 Paste this content

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

**Why this works:**
- The modern n8n image is "Docker Hardened Alpine" — it has NO package manager (`apk`, `apt-get` both fail)
- We copy pre-built Python binaries from the official `python:3.12-alpine` image (compatible because both use musl libc)
- We pre-install useful Python packages (requests, numpy, pandas, openai, anthropic, etc.)

### Verification for Step 2

```bash
cat Dockerfile
```

The first line should be `FROM python:3.12-alpine AS python-builder` and the last line should be `USER node`.

---

## Step 3: Find Your Codespace URL

You need your Codespace's public URL for the next two files.

### 3.1 Get your Codespace name

Run this in the terminal:

```bash
echo $CODESPACE_NAME
```

**Example output:** `curly-succotash-gx4g7x9pq47pcw6pq`

### 3.2 Construct your full URL

Your n8n URL will be:

```
https://<CODESPACE_NAME>-5678.app.github.dev
```

**Example:** `https://curly-succotash-gx4g7x9pq47pcw6pq-5678.app.github.dev`

### 3.3 Save this URL

Write down this URL — you'll need it in Steps 4 and 5. Replace `<YOUR-CODESPACE-URL>` in the commands below with your actual URL.

---

## Step 4: Create the nginx.conf File

This is **the actual fix** for the "Connection Lost" error. Nginx rewrites the Origin header before forwarding requests to n8n.

### 4.1 Create the file

In the **repo root**, create a file named `nginx.conf`.

### 4.2 Paste this content

**IMPORTANT:** Replace `<YOUR-CODESPACE-URL>` with the URL from Step 3 (e.g., `https://curly-succotash-gx4g7x9pq47pcw6pq-5678.app.github.dev`).

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
        proxy_set_header Origin <YOUR-CODESPACE-URL>;
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

**Why this works:**
- The Codespace proxy rewrites the `Origin` header to `localhost:5678`
- n8n rejects the WebSocket because Origin doesn't match its expected URL
- Nginx **overwrites** the Origin header back to the correct Codespace URL before passing the request to n8n
- This bypasses n8n's origin check without disabling security features

### Verification for Step 4

```bash
cat nginx.conf
```

Confirm the `proxy_set_header Origin` line has your real Codespace URL (not the placeholder).

---

## Step 5: Create the docker-compose.yml File

### 5.1 Create the file

In the **repo root**, create a file named `docker-compose.yml`.

### 5.2 Paste this content

**IMPORTANT:** Replace `<YOUR-CODESPACE-URL>` with the URL from Step 3 (both places).

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
      - N8N_EDITOR_BASE_URL=<YOUR-CODESPACE-URL>
      - WEBHOOK_URL=<YOUR-CODESPACE-URL>
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

**Key settings explained:**
- `build:` — Tells Docker Compose to build from your Dockerfile (instead of pulling plain n8n image)
- `expose: "5678"` — n8n is only accessible internally (not directly from host)
- `ports: "5678:80"` — Nginx listens on host port 5678, forwards to its own port 80
- `N8N_HOST=0.0.0.0` — Bind to all interfaces (NOT your URL — this is for binding, not identity)
- `N8N_EDITOR_BASE_URL` and `WEBHOOK_URL` — Tell n8n its public URL
- `N8N_PUSH_BACKEND=websocket` — Enables live editor updates
- `N8N_SECURE_COOKIE=false` — Required for Codespaces HTTPS cookies
- `volumes: n8n_data` — Persists your workflows across container restarts
- `depends_on: n8n` — Nginx waits for n8n to start

### Verification for Step 5

```bash
cat docker-compose.yml
```

Confirm both `<YOUR-CODESPACE-URL>` placeholders have been replaced with your real URL.

---

## Step 6: Build and Start the Containers

### 6.1 Build and start

In the terminal (from the repo root):

```bash
docker compose up -d --build
```

- The `--build` flag tells Docker to build your custom image (with Python) from the Dockerfile
- First build takes 3–5 minutes (downloading Python, installing packages)
- Subsequent builds are much faster (Docker caches layers)

### 6.2 Wait for startup

```bash
sleep 30
```

### 6.3 Check both containers are running

```bash
docker ps
```

**Expected output:**
```
CONTAINER ID   IMAGE               STATUS         PORTS                          NAMES
xxxxxxxxxxxx   nginx:alpine        Up X seconds   0.0.0.0:5678->80/tcp           n8n-nginx
xxxxxxxxxxxx   n8n-custom:latest   Up X seconds   5678/tcp                       n8n
```

You should see BOTH `n8n` and `n8n-nginx` running.

### 6.4 Check n8n logs (should be clean)

```bash
docker logs n8n --tail 15
```

**Expected — last 2 lines:**
```
Editor is now accessible via:
https://<your-codespace-name>-5678.app.github.dev
```

**Red flags (should NOT appear):**
- `Origin header does NOT match`
- `Failed to start Python task runner` (the venv warning is OK — that's different)
- `Connection refused`
- `0.0.0.0:5678` (should show your real URL instead)

### Verification for Step 6

```bash
curl -I http://localhost:5678
```

Should return `HTTP/1.1 200 OK`.

---

## Step 7: Configure the Codespace Port (Public)

This is critical — without it, the browser can't reach n8n.

### 7.1 Open the Ports tab

In VS Code, look at the **bottom panel**. Click the **"Ports"** tab.

### 7.2 Make port 5678 Public

1. Find the row for port `5678`
2. **Right-click** on the row
3. Hover over **"Port Visibility"**
4. Click **"Public"**

The indicator should turn green.

### 7.3 Copy the URL

In the same row, look at the **"Local Address"** column. This is your n8n URL:

```
https://<your-codespace-name>-5678.app.github.dev
```

### Verification for Step 7

In the Ports tab, the row for port `5678` should show:
- Green indicator
- Visibility: **Public**
- A URL in "Local Address"

---

## Step 8: Open n8n and Create Your Owner Account

### 8.1 Open n8n in your browser

1. In the Ports tab, **click the URL** in the "Local Address" column for port `5678`
2. The n8n page opens in a new browser tab

### 8.2 Create the owner account

1. You'll see the **"Set up your account"** screen
2. Enter your email
3. Enter a strong password (and remember it — this is your n8n login)
4. Click **"Next"**
5. Fill in the optional first/last name fields
6. Click **"Continue"**

### 8.3 You're in!

You should now see the n8n workflow editor.

### Verification for Step 8

- The n8n editor loads without "Connection Lost" errors
- You can create a new workflow
- You can drag nodes onto the canvas
- You can save a workflow

---

## Complete Verification Checklist

Run through this checklist to confirm everything is working:

| # | Check | Command / Action | Expected Result |
|---|---|---|---|
| 1 | Docker is installed | `docker version` | Shows version info |
| 2 | Both containers running | `docker ps` | `n8n` and `n8n-nginx` both "Up" |
| 3 | n8n responds locally | `curl -I http://localhost:5678` | `HTTP/1.1 200 OK` |
| 4 | Logs are clean | `docker logs n8n --tail 15` | No "Origin header" errors |
| 5 | URL is correct | Last line of logs | Real Codespace URL (not 0.0.0.0) |
| 6 | Port is Public | Check Ports tab | Green indicator, "Public" |
| 7 | Browser loads n8n | Open URL in browser | Setup screen or editor |
| 8 | No "Connection Lost" | Check browser | No red banner |
| 9 | Python works | `docker exec n8n python3 --version` | `Python 3.12.x` |
| 10 | Workflows persist | Save workflow, restart, check | Workflow still there |

---

## If Something Goes Wrong

### Problem: "Connection Lost" in browser
- **Check:** `docker logs n8n --tail 20` — do you see "Origin header does NOT match"?
- **Cause:** The URL in `nginx.conf` or `docker-compose.yml` is wrong
- **Fix:** Verify the URL matches your actual Codespace URL (Step 3), then `docker compose down && docker compose up -d`

### Problem: "502 Bad Gateway"
- **Cause:** Nginx started before n8n was ready (race condition)
- **Fix:** Wait 30 seconds and refresh. For permanent fix, add a healthcheck (see `07-CONFIGURATION-FILES.md`).

### Problem: "Refused to Connect"
- **Cause:** Port visibility is Private or port forwarding is stuck
- **Fix:** In Ports tab, right-click port 5678 → Port Visibility → Public. If stuck, remove the port and re-add it.

### Problem: Build fails with "apk not found" or "apt-get not found"
- **Cause:** Your Dockerfile is using the wrong package manager
- **Fix:** Use the multi-stage Dockerfile from Step 2 exactly as written

### Problem: Container won't start
- **Check:** `docker logs n8n --tail 30`
- **Common causes:**
  - Wrong env var values
  - YAML syntax error in docker-compose.yml
  - Missing files (Dockerfile, nginx.conf)

For more troubleshooting, see `08-TROUBLESHOOTING-BY-SYMPTOM.md`.

---

## Saving Your Free Hours

Codespaces auto-sleep after idle timeout (max 4 hours). To save your free hours:

### When you're done working:
```bash
docker compose down
```
Then: **Ctrl+Shift+P** → "Codespaces: Stop Codespace"

### When you come back:
1. Open your Codespace from https://github.com/codespaces
2. Run: `docker compose up -d`
3. Wait 30 seconds
4. Open the URL from the Ports tab

Your workflows, credentials, and settings are all preserved in the `n8n_data` Docker volume.

---

## Commit Your Setup to Git

Once everything is working, commit your files so they're backed up:

```bash
git add .devcontainer/devcontainer.json Dockerfile docker-compose.yml nginx.conf
git commit -m "Working n8n setup with Nginx reverse proxy for Codespaces"
git push
```

This way, if your Codespace is ever deleted, you can recreate the entire setup in minutes.

---

## Summary

Congratulations! You now have a fully working n8n instance running in GitHub Codespaces with:

- All 400+ built-in n8n nodes
- JavaScript Code node (with axios, lodash, moment, uuid)
- Python Code node (with requests, numpy, pandas, openai, anthropic, etc.)
- AI Agent / LLM / RAG capabilities
- Persistent workflows across restarts
- No "Connection Lost" errors (thanks to the Nginx fix)

For the complete story of how this setup was developed (and why the Nginx fix is necessary), see `02-ERROR-RECOVERY-STORY.md`.

---

*Last updated: July 2026*
