# Troubleshooting by Symptom

**Purpose:** A lookup table organized by **what you see** (the symptom), not by cause. Each entry has: Symptom → Root Cause → Fix → Verification command.

**How to use:** Find the symptom you're experiencing, follow the fix, run the verification command to confirm it's resolved.

---

## Table of Contents

1. [Codespace & Docker Issues](#codespace--docker-issues)
2. [Dockerfile & Build Issues](#dockerfile--build-issues)
3. [Container & Runtime Issues](#container--runtime-issues)
4. [Browser & Connection Issues](#browser--connection-issues)
5. [WebSocket & Origin Issues](#websocket--origin-issues)
6. [Port & Network Issues](#port--network-issues)
7. [Data & Persistence Issues](#data--persistence-issues)
8. [Git Issues](#git-issues)
9. [Codespace Lifecycle Issues](#codespace-lifecycle-issues)
10. [Quick Symptom Reference](#quick-symptom-reference)

---

## Codespace & Docker Issues

### Symptom: "Unsupported distribution version 'noble'"

**What you see:**
```
(!) Unsupported distribution version 'noble'. To resolve, either:
(1) set feature option '"moby": false', or (2) choose a compatible OS distribution
ERROR: Feature "Docker (Docker-in-Docker)" failed to install!
Error code: 1302 (UnifiedContainersErrorFatalCreatingContainer)
```

**Root Cause:**
The `docker-in-docker` feature version 1.0.9 doesn't support Ubuntu 24.04 (`noble`). The modern Codespace base image ships Ubuntu noble, but the old feature only knows older distros (jammy, focal, etc.).

**Fix:**
Update `.devcontainer/devcontainer.json` to use feature version 4.0.0 with `moby: false`:

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

Then rebuild: **Ctrl+Shift+P** → "Codespaces: Rebuild Container"

**Verification:**
```bash
docker version
```
Should show Docker version info with no errors.

**Related:** [`07-CONFIGURATION-FILES.md`](./07-CONFIGURATION-FILES.md) → devcontainer.json section

---

### Symptom: "Cannot connect to the Docker daemon"

**What you see:**
```
Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?
```

**Root Cause:**
Docker-in-Docker feature didn't install correctly, or the Codespace needs rebuilding.

**Fix:**
1. Check `devcontainer.json` is correct (see above)
2. Rebuild the Codespace: **Ctrl+Shift+P** → "Codespaces: Rebuild Container"
3. Wait 3-4 minutes
4. If still failing, try "Rebuild Container Without Cache"

**Verification:**
```bash
docker version
docker ps
```

**Related:** [`06-COMMANDS-CODESPACES.md`](./06-COMMANDS-CODESPACES.md) → Rebuild & Reset section

---

### Symptom: Codespace won't create at all

**What you see:**
Codespace creation fails, shows error in the creation log.

**Root Cause:**
Usually a `devcontainer.json` syntax error or incompatible feature.

**Fix:**
1. Check `devcontainer.json` for JSON syntax errors
2. Verify the feature version exists
3. Try creating a Codespace without `devcontainer.json` first (to isolate the issue)
4. Add features one at a time

**Verification:**
```bash
# After Codespace creates successfully
docker version
```

---

## Dockerfile & Build Issues

### Symptom: "apk: not found" during Docker build

**What you see:**
```
=> ERROR [2/2] RUN apk add --no-cache python3 ...
0.475 /bin/sh: apk: not found
failed to solve: process "/bin/sh -c apk add..." did not complete successfully: exit code: 127
```

**Root Cause:**
The modern n8n image is "Docker Hardened Alpine" — it has NO package manager (`apk` was removed for security). You can't install packages inside it.

**Fix:**
Use a multi-stage build. Copy pre-built Python binaries from the official `python:3.12-alpine` image:

```dockerfile
FROM python:3.12-alpine AS python-builder
RUN pip install --no-cache-dir --root=/python-root requests numpy pandas

FROM n8nio/n8n:latest
USER root
COPY --from=python:3.12-alpine /usr/local/bin/python3 /usr/local/bin/python3
COPY --from=python:3.12-alpine /usr/local/lib/python3.12 /usr/local/lib/python3.12
COPY --from=python-builder /python-root /usr/local
ENV LD_LIBRARY_PATH=/usr/local/lib
USER node
```

**Verification:**
```bash
docker compose up -d --build
docker exec n8n python3 --version
```
Should show `Python 3.12.x`.

**Related:** [`07-CONFIGURATION-FILES.md`](./07-CONFIGURATION-FILES.md) → Dockerfile section

---

### Symptom: "apt-get: not found" during Docker build

**What you see:**
```
=> ERROR [2/2] RUN apt-get update && apt-get install -y python3 ...
0.276 /bin/sh: apt-get: not found
failed to solve: process "/bin/sh -c apt-get update..." did not complete successfully: exit code: 127
```

**Root Cause:**
Same as above — the n8n image is Alpine-based, not Debian/Ubuntu. `apt-get` doesn't exist.

**Fix:**
Same as "apk: not found" — use the multi-stage build with `python:3.12-alpine`.

**Verification:**
```bash
docker exec n8n python3 --version
```

**Related:** [`07-CONFIGURATION-FILES.md`](./07-CONFIGURATION-FILES.md) → Dockerfile section

---

### Symptom: Docker build fails with "No source image provided with FROM"

**What you see:**
```
No source image provided with `FROM`
Unknown instruction: CAT
Unknown instruction: EOF
```

**Root Cause:**
You accidentally pasted the `cat > Dockerfile <<'EOF'` shell command INTO the Dockerfile as content, instead of running it in the terminal.

**Fix:**
1. Open the Dockerfile in VS Code
2. Delete the `cat`, `>`, `<<'EOF'`, and `EOF` lines
3. The file should start with `FROM` and end with `USER node`
4. Save and rebuild

**Verification:**
```bash
cat Dockerfile
```
First line should be `FROM python:3.12-alpine AS python-builder`, last line should be `USER node`.

---

### Symptom: Docker build succeeds but Python doesn't work

**What you see:**
Container runs, but `docker exec n8n python3 --version` fails, or n8n logs show "Python 3 is missing".

**Root Cause:**
The `USER node` line is missing from the end of the Dockerfile, or the `LD_LIBRARY_PATH` env var isn't set.

**Fix:**
1. Ensure the Dockerfile ends with `USER node`
2. Ensure `ENV LD_LIBRARY_PATH=/usr/local/lib` is present
3. Rebuild: `docker compose up -d --build`

**Verification:**
```bash
docker exec n8n python3 --version
docker exec n8n python3 -c "import requests; print('OK')"
```

---

## Container & Runtime Issues

### Symptom: "Container name already in use"

**What you see:**
```
docker: Error response from daemon: Conflict. The container name "/n8n" is already
in use by container "b22fe4445fbc...". You have to remove (or rename) that container
to be able to reuse that name.
```

**Root Cause:**
An old n8n container (stopped) still exists. Docker doesn't allow two containers with the same name.

**Fix:**
```bash
docker rm -f n8n
```
Then start the new container.

**If using Docker Compose:**
```bash
docker compose down
docker compose up -d
```

**Verification:**
```bash
docker ps -a --filter name=n8n
```
Should show only one n8n container.

---

### Symptom: Container exits immediately after starting

**What you see:**
`docker ps` shows the container as "Exited" shortly after starting.

**Root Cause:**
Usually a configuration error — check the logs to find the specific cause.

**Fix:**
1. Check logs:
```bash
docker logs n8n --tail 50
```
2. Common causes:
   - Wrong environment variable values
   - YAML syntax error in docker-compose.yml
   - Missing files (Dockerfile, nginx.conf)
   - Permission issues

**Verification:**
After fixing, restart and check:
```bash
docker compose up -d
sleep 15
docker ps
docker logs n8n --tail 15
```

---

### Symptom: "Failed to start Python task runner" warning

**What you see in logs:**
```
Failed to start Python task runner in internal mode. because Python 3 is missing from this system.
```

**Root Cause:**
Python isn't installed in the n8n container, or the venv is missing.

**Note:** This is a WARNING, not a fatal error. n8n still works, but Python Code nodes won't function. JavaScript Code nodes work fine.

**Fix:**
Use the multi-stage Dockerfile that installs Python (see "apk: not found" symptom above).

**If you see "virtual environment is missing":**
This is a different message — Python is installed but n8n wants a venv. This is non-blocking; JS Code nodes work. For full Python support, you'd need to set up an external task runner.

**Verification:**
```bash
docker exec n8n python3 --version
```

---

## Browser & Connection Issues

### Symptom: "Connection Lost" in n8n editor

**What you see:**
Red banner in n8n saying "Connection Lost". Workflows can't be saved or executed.

**Root Cause:**
GitHub Codespaces' port-forwarding proxy rewrites the `Origin` header to `localhost:5678`. n8n rejects the WebSocket because the Origin doesn't match its expected URL.

**Check the logs:**
```bash
docker logs n8n --tail 50 | grep -i "origin"
```
If you see "Origin header does NOT match", this is the issue.

**Fix:**
The Nginx reverse proxy solution. Ensure:
1. `nginx.conf` exists with `proxy_set_header Origin https://<your-codespace-url>;`
2. `docker-compose.yml` includes the nginx service
3. Both n8n and nginx containers are running

```bash
docker compose down
docker compose up -d
sleep 20
```

**Verification:**
```bash
docker logs n8n --tail 20 | grep -i "origin"
```
Should show NO "Origin header does NOT match" errors.

**Related:** [`02-ERROR-RECOVERY-STORY.md`](./02-ERROR-RECOVERY-STORY.md), [`07-CONFIGURATION-FILES.md`](./07-CONFIGURATION-FILES.md) → nginx.conf

---

### Symptom: "Refused to Connect" in browser

**What you see:**
Browser shows "curly-succotash-...-5678.app.github.dev refused to connect."

**Root Cause:**
Codespace port forwarding is stuck, or port visibility is set to Private.

**Fix:**
1. In VS Code, open the **Ports** tab
2. Find port `5678`
3. Right-click → **Port Visibility** → **Public**
4. If that doesn't work, right-click → **Unforward Port**
5. Click **Forward a Port** → type `5678`
6. Set visibility to **Public**
7. Try the URL again

**Verification:**
- Port indicator should be green
- Visibility should show "Public"
- URL should load in browser

**If still failing:**
- Try an incognito window
- Rebuild the Codespace: **Ctrl+Shift+P** → "Codespaces: Rebuild Container"

**Related:** [`06-COMMANDS-CODESPACES.md`](./06-COMMANDS-CODESPACES.md) → Port Forwarding

---

### Symptom: "502 Bad Gateway" in browser

**What you see:**
Browser shows "502 Bad Gateway — nginx/1.31.2"

**Root Cause:**
Nginx started before n8n was ready (race condition). Nginx tried to forward requests, but n8n wasn't responding yet.

**Fix:**
Wait 30 seconds and refresh the browser. n8n usually finishes starting within 30 seconds.

**For permanent fix:**
Add a healthcheck to `docker-compose.yml`:

```yaml
n8n:
  healthcheck:
    test: ["CMD-SHELL", "wget -q --spider http://localhost:5678/healthz || exit 1"]
    interval: 10s
    timeout: 5s
    retries: 5
    start_period: 30s

nginx:
  depends_on:
    n8n:
      condition: service_healthy
```

**Verification:**
```bash
docker ps
curl -I http://localhost:5678
```
Should return `HTTP/1.1 200 OK`.

---

### Symptom: "Lost connection to the localhost server"

**What you see:**
Error mentioning "localhost" even though you're accessing the Codespace URL.

**Root Cause:**
You're accessing n8n via `localhost:5678` (or VS Code's "Open in Browser" uses localhost), which triggers the Origin header mismatch.

**Fix:**
1. Always use the Codespace URL from the Ports tab
2. Don't use VS Code's "Open in Browser" — it may use localhost
3. Copy the URL from the "Local Address" column in the Ports tab
4. URL should be: `https://<codespace-name>-5678.app.github.dev`

**Verification:**
Check the browser address bar — it should show the Codespace URL, NOT localhost.

---

### Symptom: n8n page loads but is blank/white

**What you see:**
Browser loads the page but shows a blank white screen.

**Root Cause:**
JavaScript errors in the browser, or n8n frontend can't connect to the backend.

**Fix:**
1. Open Developer Tools (F12) → Console tab
2. Look for red errors
3. Hard refresh: **Ctrl+Shift+R**
4. Try incognito window
5. Check n8n logs: `docker logs n8n --tail 30`

**Verification:**
The n8n editor should load without errors.

---

## WebSocket & Origin Issues

### Symptom: "Origin header does NOT match" in logs

**What you see in logs:**
```
Origin header does NOT match the expected origin.
(Origin: "https://localhost:5678" -> "localhost:5678",
 Expected: "curly-succotash-...-5678.app.github.dev"
 -> "curly-succotash-...-5678.app.github.dev",
 Protocol: "https")
```

**Root Cause:**
The Codespace proxy rewrites the Origin header to `localhost:5678`. n8n expects the Codespace URL.

**Fix:**
The Nginx reverse proxy solution (see "Connection Lost" above).

**Verification:**
```bash
docker logs n8n --tail 50 | grep -i "origin"
```
Should show NO "Origin header does NOT match" errors after the fix.

---

### Symptom: "Collaboration features are disabled" warning

**What you see in logs:**
```
Collaboration features are disabled because push is configured unidirectional.
Use N8N_PUSH_BACKEND=websocket environment variable to enable them.
```

**Root Cause:**
`N8N_PUSH_BACKEND` isn't set to `websocket`.

**Fix:**
Add to `docker-compose.yml`:
```yaml
- N8N_PUSH_BACKEND=websocket
```

**Verification:**
```bash
docker compose down
docker compose up -d
docker logs n8n --tail 20 | grep -i "collaboration"
```
Should NOT show the warning.

---

### Symptom: WebSocket connection fails (HTTP status 4xx/5xx)

**What you see:**
Browser DevTools (F12 → Network → WS) shows WebSocket connection with status 4xx or 5xx.

**Root Cause:**
Either the Origin mismatch (see above) or Nginx isn't configured for WebSocket upgrade.

**Fix:**
Ensure `nginx.conf` has:
```nginx
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
proxy_read_timeout 86400s;
proxy_send_timeout 86400s;
```

**Verification:**
In DevTools → Network → WS, the WebSocket should show status `101 Switching Protocols`.

---

## Port & Network Issues

### Symptom: "Port is already allocated"

**What you see:**
```
Bind for 0.0.0.0:5678 failed: port is already allocated
```

**Root Cause:**
Another process (or container) is using port 5678.

**Fix:**
1. Check what's using the port:
```bash
sudo ss -ltnp | grep :5678
```
2. If it's a Docker container, stop it:
```bash
docker compose down
# or
docker rm -f <container-name>
```
3. If it's another process, kill it (carefully):
```bash
kill <PID>
```

**Verification:**
```bash
ss -ltnp | grep :5678
```
Should show nothing (port is free).

---

### Symptom: curl works locally but browser can't connect

**What you see:**
```bash
curl -I http://localhost:5678    # Returns 200 OK
```
But browser shows "Refused to Connect" or "Connection Lost".

**Root Cause:**
The issue is in the Codespace proxy or browser, not in n8n. n8n is working fine locally.

**Fix:**
1. Make port 5678 Public in the Ports tab
2. Use the Codespace URL (not localhost) in the browser
3. If "Connection Lost", apply the Nginx fix
4. If "Refused to Connect", reset the port forwarding

**Verification:**
Browser should load n8n without errors.

---

### Symptom: "no configuration file provided: not found"

**What you see:**
```
no configuration file provided: not found
```

**Root Cause:**
You're running `docker compose` in a directory that doesn't have `docker-compose.yml`.

**Fix:**
1. Check your current directory:
```bash
pwd
ls docker-compose.yml
```
2. Navigate to the repo root:
```bash
cd /workspaces/ai-cold-email-outreach
```
3. Verify the file exists:
```bash
ls -la docker-compose.yml
```

**Verification:**
```bash
docker compose config
```
Should print the resolved configuration.

---

## Data & Persistence Issues

### Symptom: Workflows disappear after restart

**What you see:**
After `docker compose down` and `docker compose up -d`, your workflows and credentials are gone.

**Root Cause:**
You likely ran `docker compose down -v` (which deletes volumes) or `rm -rf n8n_data`.

**Fix:**
- ❌ You can't recover deleted volumes
- Going forward, ONLY use `docker compose down` (without `-v`)
- Back up your data regularly

**Backup command:**
```bash
docker run --rm -v n8n_data:/data -v $(pwd):/backup alpine \
  tar czf /backup/n8n-backup-$(date +%Y%m%d).tar.gz /data
```

**Verification:**
```bash
docker volume ls | grep n8n_data
```
Should show `n8n_data` volume.

**Related:** [`09-DONT-DO-THIS.md`](./09-DONT-DO-THIS.md)

---

### Symptom: SQLite database errors

**What you see:**
n8n logs show "Database connection timed out" or SQLite errors.

**Root Cause:**
Database file is locked, corrupted, or has permission issues.

**Fix:**
1. Check permissions:
```bash
docker exec n8n ls -la /home/node/.n8n/
```
2. If corrupted, back up and reset:
```bash
docker compose down
# Back up first!
docker run --rm -v n8n_data:/data -v $(pwd):/backup alpine \
  tar czf /backup/n8n-backup.tar.gz /data
# Then reset (DESTRUCTIVE)
docker compose down -v    # ⚠️ This deletes data!
docker compose up -d
```

**Verification:**
```bash
docker logs n8n --tail 20
```
Should show "Database connection recovered" or no database errors.

---

## Git Issues

### Symptom: "nothing added to commit but untracked files present"

**What you see:**
```
On branch feat-workflow-final-polish
Untracked files:
  docs/01-SETUP-GUIDE.md

nothing added to commit but untracked files present
```

**Root Cause:**
You ran `git commit` without `git add` first.

**Fix:**
```bash
git add docs/01-SETUP-GUIDE.md
git commit -m "Add setup guide"
git push
```

**Verification:**
```bash
git status
```
Should show "nothing to commit, working tree clean".

---

### Symptom: "The current branch has no upstream branch"

**What you see:**
```
fatal: The current branch feat-workflow-final-polish has no upstream branch.
To push the current branch and set the remote as upstream, use
    git push --set-upstream origin feat-workflow-final-polish
```

**Root Cause:**
This is a new branch that hasn't been pushed to GitHub yet.

**Fix:**
```bash
git push --set-upstream origin feat-workflow-final-polish
```

**Verification:**
```bash
git status
```
Should show "Your branch is up to date with 'origin/feat-workflow-final-polish'."

---

### Symptom: Git push rejected

**What you see:**
```
! [rejected]        feat-workflow-final-polish -> feat-workflow-final-polish (fetch first)
```

**Root Cause:**
GitHub has commits that your local branch doesn't have (someone else pushed, or you edited on GitHub).

**Fix:**
```bash
git pull
git push
```

**If there are conflicts:**
```bash
git pull
# Resolve conflicts in VS Code
git add .
git commit -m "Merge remote changes"
git push
```

---

## Codespace Lifecycle Issues

### Symptom: Codespace auto-slept while I was working

**What you see:**
Codespace suddenly stops, n8n becomes unreachable.

**Root Cause:**
Idle timeout reached (default 30 minutes, max 4 hours).

**Fix:**
1. Open https://github.com/codespaces
2. Click "Open" to wake the Codespace
3. Run `docker compose up -d`
4. Wait 30 seconds
5. Increase idle timeout at https://github.com/settings/codespaces (max 240 minutes)

**Verification:**
```bash
docker ps
curl -I http://localhost:5678
```

---

### Symptom: Codespace was deleted (30-day inactivity)

**What you see:**
Codespace no longer appears in https://github.com/codespaces

**Root Cause:**
GitHub auto-deletes Codespaces inactive for 30 days (90 days for Pro).

**Fix:**
1. Create a new Codespace from your repo
2. Your git-committed files are safe on GitHub
3. Run `docker compose up -d --build` to rebuild
4. n8n data in Docker volumes is LOST (unless you backed it up)

**Verification:**
```bash
ls -la
docker compose up -d --build
```

---

## Quick Symptom Reference

| Symptom | Root Cause | File to Read |
|---|---|---|
| "Unsupported distribution version 'noble'" | Old docker-in-docker version | `07-CONFIGURATION-FILES.md` |
| "Cannot connect to Docker daemon" | Docker-in-Docker not installed | `06-COMMANDS-CODESPACES.md` |
| "apk: not found" | Hardened image, no package manager | `07-CONFIGURATION-FILES.md` |
| "apt-get: not found" | Alpine image, not Debian | `07-CONFIGURATION-FILES.md` |
| "Container name already in use" | Old container exists | `03-COMMANDS-DOCKER.md` |
| "Connection Lost" | Origin header mismatch | `02-ERROR-RECOVERY-STORY.md` |
| "Origin header does NOT match" | Codespace proxy rewrites Origin | `07-CONFIGURATION-FILES.md` |
| "Refused to Connect" | Port Private or forwarding stuck | `06-COMMANDS-CODESPACES.md` |
| "502 Bad Gateway" | Nginx started before n8n | This file |
| "Lost connection to localhost" | Accessing via localhost | This file |
| "Port is already allocated" | Another process on port | `05-COMMANDS-NETWORKING.md` |
| "no configuration file provided" | Wrong directory | `03-COMMANDS-DOCKER.md` |
| Workflows disappear | Used `down -v` | `09-DONT-DO-THIS.md` |
| "nothing added to commit" | Forgot `git add` | `04-COMMANDS-GIT.md` |
| "no upstream branch" | New branch, first push | `04-COMMANDS-GIT.md` |
| Codespace auto-slept | Idle timeout | `06-COMMANDS-CODESPACES.md` |

---

## Diagnostic Decision Tree

```
Is n8n not working?
├── Can't create Codespace?
│   ├── Check devcontainer.json syntax
│   └── Check feature version (need 4.0.0)
│
├── Docker not working?
│   ├── "Cannot connect to daemon" → Rebuild Container
│   └── "noble" error → Update to docker-in-docker:4.0.0
│
├── Build fails?
│   ├── "apk not found" → Use multi-stage Dockerfile
│   ├── "apt-get not found" → Use multi-stage Dockerfile
│   └── "No source image" → Remove cat/EOF from Dockerfile
│
├── Container won't start?
│   ├── "Name already in use" → docker rm -f n8n
│   ├── Check logs → docker logs n8n --tail 50
│   └── "no config file" → cd to repo root
│
├── Browser can't connect?
│   ├── "Refused to Connect" → Make port Public
│   ├── "502 Bad Gateway" → Wait 30 seconds
│   ├── "Connection Lost" → Apply Nginx fix
│   └── Blank page → Hard refresh, check DevTools
│
├── Data issues?
│   ├── Workflows gone → You used down -v (no recovery)
│   └── SQLite errors → Check permissions, restore backup
│
└── Git issues?
    ├── "nothing to commit" → Run git add first
    ├── "no upstream" → git push --set-upstream
    └── "rejected" → git pull first
```

---

## When All Else Fails

### The "Nuclear Option" — Full Rebuild

If nothing else works, do a full clean rebuild:

```bash
# 1. Stop and remove containers (preserve data)
docker compose down

# 2. Rebuild the Codespace
# Ctrl+Shift+P → "Codespaces: Rebuild Container Without Cache"

# 3. Wait 5-10 minutes

# 4. Rebuild and start
docker compose up -d --build

# 5. Wait for startup
sleep 30

# 6. Verify
docker ps
docker logs n8n --tail 20
curl -I http://localhost:5678
```

### When to Ask for Help

If you've tried everything and it still doesn't work:
1. Collect diagnostic info:
   ```bash
   docker ps -a > diagnostics.txt
   docker logs n8n --tail 100 >> diagnostics.txt
   docker logs n8n-nginx --tail 50 >> diagnostics.txt
   docker inspect n8n >> diagnostics.txt
   curl -I http://localhost:5678 >> diagnostics.txt
   ```
2. Check the n8n community: https://community.n8n.io
3. Check GitHub issues: https://github.com/n8n-io/n8n/issues
4. Reference this knowledge base when asking for help

---

*Last updated: July 2026*
