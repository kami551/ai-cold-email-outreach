#!/bin/bash
# =====================================================================
# n8n Codespace Auto-Start Script
# =====================================================================
# Waits for Docker daemon to be ready, then starts n8n + nginx containers.
# Used by devcontainer.json postCreateCommand and postStartCommand.
#
# WHY THIS EXISTS:
# In GitHub Codespaces with docker-in-docker, postStartCommand fires
# BEFORE the Docker daemon is fully ready. Running "docker compose up -d"
# directly fails silently. This script retries for up to 60 seconds,
# waiting for Docker to be ready before starting containers.
#
# Confirmed by: https://github.com/devcontainers/features/issues/977
# =====================================================================

set -e

# Maximum retries (60 seconds total, 2s between attempts)
MAX_ATTEMPTS=30
WAIT_SECONDS=2

# Find the repo directory (Codespaces mount repos at /workspaces/)
REPO_DIR=""
for candidate in "/workspaces/ai-cold-email-outreach" "$HOME/workspace/ai-cold-email-outreach" "$PWD"; do
    if [ -f "$candidate/docker-compose.yml" ]; then
        REPO_DIR="$candidate"
        break
    fi
done

if [ -z "$REPO_DIR" ]; then
    echo "[start-n8n] ERROR: Could not find docker-compose.yml"
    echo "[start-n8n] Searched: /workspaces/ai-cold-email-outreach, \$HOME/workspace, \$PWD ($PWD)"
    exit 1
fi

echo "[start-n8n] Repo directory: $REPO_DIR"
cd "$REPO_DIR"

# Wait for Docker daemon to be ready
echo "[start-n8n] Waiting for Docker daemon..."
for i in $(seq 1 $MAX_ATTEMPTS); do
    if docker info >/dev/null 2>&1; then
        echo "[start-n8n] Docker daemon ready (attempt $i/$MAX_ATTEMPTS)"
        break
    else
        echo "[start-n8n] Docker not ready yet (attempt $i/$MAX_ATTEMPTS), waiting ${WAIT_SECONDS}s..."
        sleep $WAIT_SECONDS
    fi

    if [ $i -eq $MAX_ATTEMPTS ]; then
        echo "[start-n8n] ERROR: Docker daemon did not become ready after $((MAX_ATTEMPTS * WAIT_SECONDS))s"
        echo "[start-n8n] Try running 'sudo service docker start' manually, then 'docker compose up -d'"
        exit 1
    fi
done

# Start containers (with retry in case compose has a transient error)
echo "[start-n8n] Starting containers with docker compose..."
for i in 1 2 3; do
    if docker compose up -d; then
        echo "[start-n8n] Containers started successfully"
        break
    else
        echo "[start-n8n] docker compose failed (attempt $i/3), retrying in 3s..."
        sleep 3
    fi

    if [ $i -eq 3 ]; then
        echo "[start-n8n] ERROR: docker compose failed after 3 attempts"
        exit 1
    fi
done

# Wait for n8n to be ready (up to 30s)
echo "[start-n8n] Waiting for n8n to respond on port 5678..."
for i in $(seq 1 15); do
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:5678 | grep -q "200\|302\|401"; then
        echo "[start-n8n] n8n is ready! (attempt $i/15)"
        echo "[start-n8n] Editor URL: https://${CODESPACE_NAME}-5678.app.github.dev"
        exit 0
    else
        echo "[start-n8n] n8n not responding yet (attempt $i/15), waiting 2s..."
        sleep 2
    fi
done

echo "[start-n8n] WARNING: Containers started but n8n not responding on port 5678"
echo "[start-n8n] Check logs with: docker compose logs --tail=30 n8n"
exit 0
