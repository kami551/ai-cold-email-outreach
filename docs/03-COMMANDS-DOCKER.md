# Docker Commands Reference

**Purpose:** Complete reference for every Docker and Docker Compose command used in this project, with purpose, usage context, precautions, and real examples from our debugging session.

**How to use:** Look up a command by name or browse by category. Each entry follows the same template so you can quickly find what you need.

---

## Table of Contents

1. [Container Lifecycle](#container-lifecycle)
2. [Container Inspection](#container-inspection)
3. [Logs & Monitoring](#logs--monitoring)
4. [Container Management](#container-management)
5. [Container Inspection & Config](#container-inspection--config)
6. [Executing Commands Inside Containers](#executing-commands-inside-containers)
7. [Image Management](#image-management)
8. [Networking & Ports](#networking--ports)
9. [Cleanup & Maintenance](#cleanup--maintenance)
10. [Diagnostics & Debugging](#diagnostics--debugging)
11. [Dangerous Commands — Read First](#dangerous-commands--read-first)

---

## Container Lifecycle

### docker compose up -d

```bash
docker compose up -d
```

**Purpose:** Start all services defined in `docker-compose.yml` in the background.

**What It Does:**
- Reads `docker-compose.yml`
- Creates containers from the defined services
- Starts them in detached mode (background)
- Returns control to the terminal immediately
- Containers keep running after you close the terminal

**When to Use:**
- After waking up the Codespace
- After modifying `docker-compose.yml`
- When n8n isn't running but should be
- At the start of a work session

**When NOT to Use:**
- If you modified the `Dockerfile` → use `docker compose up -d --build` instead
- If you just want to apply a small config change to a running container → use `docker compose restart`
- If you want to see real-time logs → use `docker compose up` (without `-d`)

**Precautions:**
- Always run from the directory containing `docker-compose.yml`
- Check `docker ps` afterward to confirm containers started

**Real Example from Our Session:**
```bash
docker compose up -d
```
Used every morning after waking the Codespace. Both `n8n` and `n8n-nginx` containers started.

**Related Commands:**
- `docker compose down` — stop and remove containers
- `docker compose restart` — restart without removing
- `docker compose up -d --build` — rebuild images first

**Common Mistakes:**
- Running from the wrong directory → "no configuration file provided: not found"
- Forgetting `-d` → terminal is locked showing logs

---

### docker compose up -d --build

```bash
docker compose up -d --build
```

**Purpose:** Rebuild images from the Dockerfile, then start containers.

**What It Does:**
- Reads the `Dockerfile` and rebuilds the custom image
- Replaces existing containers with new ones from the rebuilt image
- Starts everything in detached mode

**When to Use:**
- After modifying the `Dockerfile`
- After modifying `nginx.conf` (if mounted as a volume, restart is enough; if baked into image, rebuild needed)
- When you want to ensure you're using the latest image
- First time setting up the project

**When NOT to Use:**
- If you only changed `docker-compose.yml` → `docker compose up -d` is enough
- If you only changed environment variables → `docker compose up -d` recreates containers with new env

**Precautions:**
- First build takes 3–5 minutes (downloading Python, installing packages)
- Subsequent builds use Docker cache and are faster
- Your data in volumes is preserved

**Real Example from Our Session:**
```bash
docker compose up -d --build
```
Used after creating the multi-stage Dockerfile with Python. Build took ~4 minutes the first time.

**Related Commands:**
- `docker compose up -d` — start without rebuilding
- `docker compose build` — build images without starting containers

**Common Mistakes:**
- Forgetting `--build` after changing the Dockerfile → old image is used
- Panicking when build takes 5 minutes → it's normal for the first build

---

### docker compose down

```bash
docker compose down
```

**Purpose:** Stop and remove all containers, networks (but NOT volumes).

**What It Does:**
- Stops all running containers
- Removes the containers (they're disposable)
- Removes the default network
- **Preserves named volumes** (your n8n data stays safe)

**When to Use:**
- At the end of a work session
- Before stopping the Codespace for the night
- Before making major config changes
- When n8n is misbehaving and you want a fresh container

**When NOT to Use:**
- If you just want to pause containers → use `docker compose stop`
- If you need to rebuild after Dockerfile change → use `docker compose up -d --build` (no need to down first)
- For a quick restart → use `docker compose restart`

**Precautions:**
- **NEVER add `-v` flag** unless you want to DELETE ALL YOUR DATA
- `docker compose down -v` deletes volumes = deletes your workflows, credentials, settings
- If you have uncommitted changes in mounted files, they're safe (they live on the host)

**Real Example from Our Session:**
```bash
docker compose down
```
Used every night before stopping the Codespace. n8n data was preserved in the `n8n_data` volume.

**Related Commands:**
- `docker compose stop` — pause without removing
- `docker compose down -v` — ⚠️ DANGEROUS, deletes data
- `docker compose up -d` — the counterpart (start)

**Common Mistakes:**
- Running `docker compose down -v` by accident → **data loss!**
- Running `down` then `up` when you could just `restart`

---

### docker compose stop

```bash
docker compose stop
```

**Purpose:** Pause containers without removing them.

**What It Does:**
- Sends a stop signal to all containers
- Containers remain on disk (just stopped)
- Containers can be restarted with `docker compose start`
- Faster than `down` + `up`

**When to Use:**
- When you want to temporarily free resources
- When you'll resume work shortly
- When you don't want to recreate containers

**When NOT to Use:**
- If you want to apply config changes → use `docker compose down` + `up`
- If you're done for the day → use `docker compose down` (cleaner)

**Precautions:**
- Volumes are preserved (always, `stop` never touches volumes)
- Containers still exist, just stopped

**Real Example from Our Session:**
Not used often — we preferred `down` for a clean slate.

**Related Commands:**
- `docker compose start` — resume stopped containers
- `docker compose down` — stop AND remove

---

### docker compose restart

```bash
docker compose restart
docker compose restart n8n
```

**Purpose:** Restart containers without removing them.

**What It Does:**
- Stops and starts the containers
- Containers keep their configuration
- Faster than `down` + `up`

**When to Use:**
- After modifying a mounted file (like `nginx.conf`)
- When a container is behaving strangely
- When you want to apply env var changes (note: `up -d` is needed for new env vars)

**When NOT to Use:**
- If you changed the Dockerfile → need `up -d --build`
- If you changed environment variables in docker-compose.yml → need `up -d`

**Precautions:**
- Doesn't apply new environment variables (use `up -d` for that)
- Doesn't rebuild images

**Real Example from Our Session:**
```bash
docker compose restart n8n
```
Used to restart just n8n without affecting nginx.

**Related Commands:**
- `docker compose up -d` — recreate with new config
- `docker compose restart nginx` — restart only nginx

---

## Container Inspection

### docker ps

```bash
docker ps
```

**Purpose:** List all running containers.

**What It Does:**
- Shows container ID, image, command, status, ports, names
- Only shows currently running containers
- Real-time snapshot of what's running

**When to Use:**
- Verify containers are running
- Check container names and IDs
- See port mappings
- First step in any debugging

**When NOT to Use:**
- If you want to see stopped containers → use `docker ps -a`
- If you want to filter by name → use `docker ps --filter name=n8n`

**Precautions:**
None — this is a read-only command, completely safe.

**Real Example from Our Session:**
```bash
docker ps
```
Output:
```
CONTAINER ID   IMAGE               STATUS         PORTS                          NAMES
b45597576b71   n8n-custom:latest   Up 3 minutes   0.0.0.0:5678->5678/tcp         n8n
```

**Related Commands:**
- `docker ps -a` — show all containers (including stopped)
- `docker ps --filter name=n8n` — show only n8n containers

**Common Mistakes:**
- Expecting to see stopped containers → use `docker ps -a`

---

### docker ps -a

```bash
docker ps -a
```

**Purpose:** List ALL containers, including stopped ones.

**What It Does:**
- Shows running AND stopped containers
- Includes exit codes for stopped containers
- Useful for seeing container history

**When to Use:**
- Investigating why a container stopped
- Checking exit codes
- Finding old containers to clean up
- Debugging container crashes

**When NOT to Use:**
- If you only care about running containers → use `docker ps`

**Precautions:**
None — read-only command.

**Real Example from Our Session:**
Used to check if old n8n containers were lingering and causing name conflicts.

**Related Commands:**
- `docker ps` — running containers only
- `docker container prune` — remove all stopped containers

---

### docker ps -a --filter "name=n8n"

```bash
docker ps -a --filter "name=n8n" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}"
```

**Purpose:** List containers matching a name filter, with custom formatting.

**What It Does:**
- Filters containers by name
- Formats output as a clean table
- Shows only the columns you specify

**When to Use:**
- When you have many containers and want to focus on one
- When you want clean, readable output
- When scripting (parsing output is easier with custom format)

**When NOT to Use:**
- If you want to see all containers → use `docker ps -a`

**Precautions:**
None — read-only.

**Real Example from Our Session:**
This was suggested by GitHub Copilot during the debugging session:
```bash
docker ps -a --filter "name=n8n" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}"
```

**Related Commands:**
- `docker ps` — unfiltered
- `docker ps --format` — custom format without filter

---

## Logs & Monitoring

### docker logs n8n

```bash
docker logs n8n
```

**Purpose:** View all logs from a container.

**What It Does:**
- Prints all log output (stdout and stderr) from the container
- Shows everything since the container started

**When to Use:**
- Initial debugging
- When you want to see the full startup sequence
- When `--tail` doesn't show enough context

**When NOT to Use:**
- If you only want recent logs → use `docker logs n8n --tail 20`
- If you want live logs → use `docker logs -f n8n`

**Precautions:**
- Output can be very long (thousands of lines)
- Use `--tail` to limit output

**Real Example from Our Session:**
```bash
docker logs n8n
```
This revealed the "Origin header does NOT match" errors that pointed us to the root cause.

**Related Commands:**
- `docker logs n8n --tail 20` — last 20 lines
- `docker logs -f n8n` — live follow
- `docker logs n8n --timestamps` — with timestamps

---

### docker logs n8n --tail 20

```bash
docker logs n8n --tail 20
```

**Purpose:** View the last 20 lines of container logs.

**What It Does:**
- Shows only the most recent log entries
- Useful for quick checks

**When to Use:**
- Quick health check
- After restarting a container
- When you only care about recent events

**When NOT to Use:**
- If you need full history → use `docker logs n8n`
- If you want live updates → use `docker logs -f n8n`

**Precautions:**
None — read-only.

**Real Example from Our Session:**
```bash
docker logs n8n --tail 10
```
Output showed:
```
Editor is now accessible via:
https://curly-succotash-gx4g7x9pq47pcw6pq-5678.app.github.dev
```

**Related Commands:**
- `docker logs n8n --tail 50` — more lines
- `docker logs n8n --tail 200 --timestamps` — with timestamps

---

### docker logs n8n --tail 200 --timestamps

```bash
docker logs n8n --tail 200 --timestamps n8n
```

**Purpose:** View recent logs with timestamps for correlation.

**What It Does:**
- Shows last 200 lines
- Prepends each line with an ISO timestamp
- Useful for correlating events

**When to Use:**
- When you need to correlate events with external timestamps
- When debugging timing issues
- When reporting bugs to maintainers

**When NOT to Use:**
- Quick checks → `--tail 20` is faster

**Precautions:**
None — read-only.

**Real Example from Our Session:**
Used by Copilot to identify exactly when the "Origin header" errors started.

**Related Commands:**
- `docker logs n8n --since 1h` — logs from last hour
- `docker logs n8n --since 2026-07-08T11:00:00` — logs since specific time

---

### docker logs -f n8n

```bash
docker logs -f n8n
```

**Purpose:** Follow live logs (real-time streaming).

**What It Does:**
- Shows existing logs
- Continues streaming new log entries as they happen
- Blocks the terminal until you press Ctrl+C

**When to Use:**
- Watching for errors in real-time
- Debugging a workflow execution
- Monitoring startup

**When NOT to Use:**
- If you need to run other commands → use `docker logs n8n --tail 20` instead
- In scripts → use `timeout` to prevent hanging

**Precautions:**
- Blocks the terminal — press **Ctrl+C** to exit
- Don't use in scripts without `timeout`

**Real Example from Our Session:**
```bash
docker logs -f n8n
```
Used to watch for "Origin header" errors in real-time while testing in the browser.

**Related Commands:**
- `timeout 30s docker logs -f n8n` — auto-stop after 30 seconds
- `docker logs n8n --tail 20` — non-blocking alternative

---

### timeout 30s docker logs --follow --timestamps n8n

```bash
timeout 30s docker logs --follow --timestamps n8n
```

**Purpose:** Follow live logs for a limited time, then auto-stop.

**What It Does:**
- Streams logs with timestamps
- Automatically stops after 30 seconds
- Returns control to the terminal

**When to Use:**
- When you want live logs but don't want to block forever
- In scripts
- When reproducing an issue that happens within 30 seconds

**When NOT to Use:**
- If you need to watch for longer → use `docker logs -f` and Ctrl+C manually

**Precautions:**
- Adjust the timeout as needed (`timeout 60s`, `timeout 120s`)

**Real Example from Our Session:**
```bash
timeout 30s docker logs --follow --timestamps n8n
```
Used by Copilot to capture logs while reproducing the "Connection Lost" error.

**Related Commands:**
- `docker logs -f n8n` — manual stop with Ctrl+C
- `docker logs n8n --tail 50` — instant snapshot

---

### docker logs n8n 2>&1 | tail -200

```bash
docker logs n8n 2>&1 | tail -200
```

**Purpose:** View last 200 lines, combining stdout and stderr.

**What It Does:**
- `2>&1` redirects stderr to stdout (so you see error messages too)
- `| tail -200` pipes to tail, showing only last 200 lines
- More thorough than `--tail` because it captures stderr

**When to Use:**
- When you suspect errors are being written to stderr (not captured by default)
- When `--tail` doesn't show the errors you expect
- For thorough debugging

**When NOT to Use:**
- Quick checks → `docker logs n8n --tail 20` is simpler

**Precautions:**
None — read-only.

**Real Example from Our Session:**
This was one of the commands from the user's saved notes — more thorough than the basic `--tail`.

**Related Commands:**
- `docker logs n8n --tail 200` — simpler version
- `docker logs n8n 2>&1 | grep -i error` — filter for errors

---

## Container Management

### docker rm -f n8n

```bash
docker rm -f n8n
```

**Purpose:** Force-remove a container (even if running).

**What It Does:**
- Stops the container if it's running
- Removes the container from Docker
- Frees the container name for reuse

**When to Use:**
- When you get "container name already in use" error
- Before starting a fresh container with the same name
- To clean up stuck containers

**When NOT to Use:**
- If you want to stop without removing → use `docker stop n8n`
- If you're using Docker Compose → use `docker compose down` instead

**Precautions:**
- This removes the container, but NOT volumes (your data is safe)
- The `-f` flag doesn't prompt for confirmation

**Real Example from Our Session:**
```bash
docker rm -f n8n
```
Used frequently during Phase 3 (env var testing) to clear old containers before starting new ones.

**Related Commands:**
- `docker stop n8n && docker rm n8n` — cleaner two-step approach
- `docker rm -f n8n 2>/dev/null || true` — silent version for scripts

---

### docker stop n8n && docker rm n8n

```bash
docker stop n8n && docker rm n8n
```

**Purpose:** Gracefully stop, then remove a container.

**What It Does:**
- `docker stop n8n` sends SIGTERM, waits for graceful shutdown
- `&&` runs the next command only if the first succeeds
- `docker rm n8n` removes the stopped container

**When to Use:**
- When you want a clean shutdown (vs. force-remove)
- When the container is responsive
- Safer than `rm -f` for graceful shutdown

**When NOT to Use:**
- If the container is hung → use `docker rm -f n8n`
- If using Docker Compose → use `docker compose down`

**Precautions:**
- Safer than `rm -f` because it allows graceful shutdown
- Volumes are preserved

**Real Example from Our Session:**
```bash
docker stop n8n && docker rm n8n
```

**Related Commands:**
- `docker rm -f n8n` — force remove (faster, less graceful)
- `docker compose down` — remove all compose containers

---

### docker rm -f n8n 2>/dev/null || true

```bash
docker rm -f n8n 2>/dev/null || true
```

**Purpose:** Remove a container if it exists, silently continue if it doesn't.

**What It Does:**
- `2>/dev/null` silences error output (e.g., "No such container")
- `|| true` ensures the command always succeeds (exit code 0)
- Useful in scripts where you don't want failures to stop execution

**When to Use:**
- In scripts to ensure cleanup doesn't break the script
- When you're not sure if the container exists
- As a "just in case" cleanup before starting a new container

**When NOT to Use:**
- In interactive terminal → just use `docker rm -f n8n`

**Precautions:**
None — this is a safe cleanup pattern.

**Real Example from Our Session:**
Used in scripts and combined commands to ensure clean state.

**Related Commands:**
- `docker rm -f n8n` — without error suppression

---

## Container Inspection & Config

### docker inspect n8n

```bash
docker inspect n8n
```

**Purpose:** View detailed configuration of a container.

**What It Does:**
- Outputs a large JSON object with all container details
- Includes env vars, network settings, volumes, mounts, etc.

**When to Use:**
- Debugging configuration issues
- Verifying environment variables are set correctly
- Checking volume mounts

**When NOT to Use:**
- If you only need env vars → use the formatted version below
- Quick checks → use `docker ps`

**Precautions:**
- Output is very large (hundreds of lines of JSON)
- Use `--format` to extract specific fields

**Real Example from Our Session:**
Used to verify that environment variables were correctly passed to the container.

**Related Commands:**
- `docker inspect --format ...` — extract specific fields
- `docker ps` — summary view

---

### docker inspect --format (extract env vars)

```bash
docker inspect --format '{{range .Config.Env}}{{println .}}{{end}}' n8n
```

**Purpose:** List all environment variables passed to a container.

**What It Does:**
- Uses Go template syntax to extract just the `.Config.Env` field
- Prints each environment variable on its own line
- Much cleaner than full `docker inspect`

**When to Use:**
- Verifying env vars are set correctly
- Debugging "why isn't my env var working"
- Confirming Docker Compose is passing the right values

**When NOT to Use:**
- If you want full container details → use `docker inspect n8n`

**Precautions:**
None — read-only.

**Real Example from Our Session:**
```bash
docker inspect --format '{{range .Config.Env}}{{println .}}{{end}}' n8n
```
Output:
```
N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_EDITOR_BASE_URL=https://localhost:5678
GENERIC_TIMEZONE=America/New_York
...
```
This revealed that `N8N_EDITOR_BASE_URL` was set to `localhost:5678` instead of the Codespace URL.

**Related Commands:**
- `docker inspect n8n` — full JSON output
- `docker inspect --format '{{.NetworkSettings.Ports}}' n8n` — check port mappings

---

## Executing Commands Inside Containers

### docker exec n8n python3 --version

```bash
docker exec n8n python3 --version
```

**Purpose:** Run a command inside a running container.

**What It Does:**
- Executes `python3 --version` inside the `n8n` container
- Returns the output to your terminal
- Container keeps running

**When to Use:**
- Verifying tools are installed (Python, Node, etc.)
- Running one-off commands inside the container
- Debugging file system issues

**When NOT to Use:**
- If you need an interactive shell → use `docker exec -it n8n sh`
- If the container is stopped → start it first

**Precautions:**
- Container must be running
- Commands run as the container's default user (usually `node` for n8n)

**Real Example from Our Session:**
```bash
docker exec n8n python3 --version
```
Output: `Python 3.12.x` — confirming Python was successfully installed via the multi-stage Dockerfile.

**Related Commands:**
- `docker exec -it n8n sh` — interactive shell
- `docker exec -u root n8n sh` — run as root

---

### docker exec -it n8n sh

```bash
docker exec -it n8n sh
```

**Purpose:** Open an interactive shell inside the container.

**What It Does:**
- `-i` keeps stdin open (interactive)
- `-t` allocates a pseudo-TTY (terminal)
- Opens a shell (`sh`) inside the container
- You can now run commands as if you're inside the container

**When to Use:**
- Exploring the container's file system
- Running multiple commands inside the container
- Debugging that requires interactive exploration

**When NOT to Use:**
- For single commands → use `docker exec n8n <command>`
- If the container is stopped

**Precautions:**
- Type `exit` or press Ctrl+D to leave the shell
- Changes you make inside the container are lost when it's recreated (use volumes for persistence)

**Real Example from Our Session:**
Used to explore the n8n container's file system and verify Python installation paths.

**Related Commands:**
- `docker exec -it n8n bash` — if bash is available
- `docker exec -u root -it n8n sh` — as root user

---

## Image Management

### docker version

```bash
docker version
```

**Purpose:** Verify Docker is installed and show version info.

**What It Does:**
- Shows client and server versions
- Confirms Docker daemon is running
- Shows API version, Go version, OS/Arch

**When to Use:**
- First step after creating a Codespace
- Verifying Docker-in-Docker feature installed correctly
- Debugging "Cannot connect to Docker daemon" errors

**When NOT to Use:**
- If you just want the version number → use `docker --version`

**Precautions:**
None — read-only.

**Real Example from Our Session:**
```bash
docker version
```
Output confirmed Docker 29.6.1 was installed after rebuilding the Codespace with `docker-in-docker:4.0.0`.

**Related Commands:**
- `docker --version` — just the version number
- `docker info` — detailed system info

---

### docker compose build

```bash
docker compose build
```

**Purpose:** Build images defined in docker-compose.yml without starting containers.

**What It Does:**
- Reads the Dockerfile
- Builds the image
- Tags it with the name specified in `docker-compose.yml`
- Does NOT start containers

**When to Use:**
- When you want to build in advance
- When testing build changes
- Before a `docker compose up -d` to separate build and run

**When NOT to Use:**
- If you want to build AND start → use `docker compose up -d --build`

**Precautions:**
- First build is slow (downloads base images)
- Subsequent builds use cache

**Real Example from Our Session:**
Not used directly — we used `docker compose up -d --build` to combine build and start.

**Related Commands:**
- `docker compose up -d --build` — build and start
- `docker build -t myimage .` — build without compose

---

## Networking & Ports

### docker port n8n

```bash
docker port n8n
```

**Purpose:** Show port mappings for a container.

**What It Does:**
- Lists which container ports are mapped to which host ports
- Helps verify port forwarding is correct

**When to Use:**
- Debugging "can't access the app" issues
- Verifying port mappings after starting a container
- Checking if a port is exposed

**When NOT to Use:**
- If using Docker Compose → `docker compose ps` shows ports too

**Precautions:**
None — read-only.

**Real Example from Our Session:**
```bash
docker port n8n && echo '---' && curl -I http://127.0.0.1:8080
```
Combined command to verify port mapping AND test HTTP response.

**Related Commands:**
- `docker compose ps` — shows ports for compose services
- `ss -ltnp | grep :5678` — check what's listening on a port

---

### docker compose port n8n 5678

```bash
docker compose port n8n 5678
```

**Purpose:** Show the host port mapped to a container's port.

**What It Does:**
- Queries Docker Compose for the public-facing port mapping
- Returns the host port for the specified container port

**When to Use:**
- Programmatically discovering the host port
- Verifying port mappings in a compose setup

**When NOT to Use:**
- Quick checks → `docker ps` shows ports in a table

**Precautions:**
None — read-only.

**Real Example from Our Session:**
Used as a fallback when `docker port` didn't give enough detail.

**Related Commands:**
- `docker port n8n` — without compose
- `docker inspect --format '{{.NetworkSettings.Ports}}' n8n`

---

## Cleanup & Maintenance

### docker container prune

```bash
docker container prune
```

**Purpose:** Remove all stopped containers.

**What It Does:**
- Removes ALL stopped containers (not running ones)
- Frees disk space
- Cleans up container clutter

**When to Use:**
- After many `docker run` experiments
- When "container name already in use" errors appear
- Periodic cleanup

**When NOT to Use:**
- If you want to keep stopped containers for reference → don't prune

**Precautions:**
- Only removes STOPPED containers (running ones are safe)
- Does NOT remove volumes (your data is safe)
- Asks for confirmation (use `-f` to skip)

**Real Example from Our Session:**
Suggested as a cleanup step after many `docker run` attempts left stopped containers.

**Related Commands:**
- `docker image prune` — remove unused images
- `docker system prune` — remove everything unused (⚠️ see warning below)

---

### docker image prune

```bash
docker image prune
docker image prune -a
```

**Purpose:** Remove unused Docker images.

**What It Does:**
- Without `-a`: removes dangling images (untagged layers)
- With `-a`: removes ALL unused images (not referenced by any container)

**When to Use:**
- Freeing disk space
- After many image builds
- When Codespace disk is full

**When NOT to Use:**
- If you might need the images later → they'll need to be re-downloaded

**Precautions:**
- `-a` is aggressive — only use if you're sure
- Does NOT remove volumes

**Real Example from Our Session:**
Not used — we had enough disk space.

**Related Commands:**
- `docker container prune` — remove stopped containers
- `docker images` — list images

---

## Diagnostics & Debugging

### docker run --rm --entrypoint sh (inspect image contents)

```bash
docker run --rm --entrypoint sh n8nio/n8n:latest -c "cat /etc/os-release"
```

**Purpose:** Run a one-off command inside an image to inspect its contents.

**What It Does:**
- `--rm` removes the container after it exits
- `--entrypoint sh` overrides the default entrypoint with a shell
- `-c "..."` runs the specified command
- Container starts, runs command, prints output, exits, is removed

**When to Use:**
- Inspecting what's inside an image
- Checking what OS/package manager an image uses
- Debugging image contents without modifying your setup

**When NOT to Use:**
- If you want a persistent container → use `docker run -d`

**Precautions:**
- `--rm` means the container is deleted after the command finishes
- Safe — doesn't affect running containers

**Real Example from Our Session:**
```bash
docker run --rm --entrypoint sh n8nio/n8n:latest -c "cat /etc/os-release 2>/dev/null | head -5; echo '---'; which apk apt-get yum dnf microdnf 2>/dev/null; echo '---'; uname -a"
```
Output revealed:
```
NAME="Docker Hardened Images (Alpine)"
ID=alpine
VERSION_ID=3.24
```
This confirmed the image was Alpine-based but had no package managers — the key insight that led to the multi-stage Dockerfile solution.

**Related Commands:**
- `docker run -it --rm n8nio/n8n:latest sh` — interactive shell in image
- `docker inspect n8nio/n8n:latest` — image metadata

---

### docker compose ps -a

```bash
docker compose ps -a
```

**Purpose:** Show status of all compose services (including stopped).

**What It Does:**
- Lists containers managed by docker-compose.yml
- Shows status, ports, and other info
- `-a` includes stopped services

**When to Use:**
- Checking if compose services are running
- Verifying port mappings
- Debugging compose issues

**When NOT to Use:**
- If you want ALL containers (not just compose ones) → use `docker ps -a`

**Precautions:**
None — read-only.

**Real Example from Our Session:**
Used to verify both `n8n` and `n8n-nginx` were running after `docker compose up -d`.

**Related Commands:**
- `docker ps -a` — all containers, not just compose
- `docker compose config` — show resolved compose config

---

### docker compose config

```bash
docker compose config
```

**Purpose:** Validate and display the resolved docker-compose.yml configuration.

**What It Does:**
- Parses docker-compose.yml
- Resolves environment variables
- Prints the final configuration that Docker Compose will use
- Validates YAML syntax

**When to Use:**
- Debugging YAML syntax errors
- Verifying environment variable substitution
- Checking what config Docker Compose actually sees

**When NOT to Use:**
- If you just want to see if containers are running → use `docker compose ps`

**Precautions:**
None — read-only and safe.

**Real Example from Our Session:**
Used to verify that `${CODESPACE_NAME}` was being substituted correctly in docker-compose.yml.

**Related Commands:**
- `docker compose ps` — running containers
- `cat docker-compose.yml` — raw file contents

---

## Dangerous Commands — Read First

### ⚠️ docker compose down -v

```bash
docker compose down -v
```

**Purpose:** Stop containers, remove containers, AND DELETE ALL VOLUMES.

**What It Does:**
- Everything `docker compose down` does
- PLUS deletes all named volumes
- **Your n8n workflows, credentials, and settings are PERMANENTLY DESTROYED**

**When to Use:**
- ❌ **Almost NEVER** in normal operation
- Only when you want a complete factory reset
- Only when you've backed up your data elsewhere
- Only when you understand the consequences

**When NOT to Use:**
- For routine shutdown → use `docker compose down` (without `-v`)
- Before stopping the Codespace → use `docker compose down`
- When debugging → use `docker compose down`

**Precautions:**
- 🚨 **THIS DELETES YOUR DATA PERMANENTLY**
- There is NO undo
- Your workflows, credentials, owner account — all gone
- Only use if you're absolutely sure

**Real Example from Our Session:**
- ❌ We did NOT use this command
- The Chrome AI guide and Copilot both suggested it
- Copilot itself admitted it was "too destructive" and "risky"
- Documented here as a WARNING, not a recommendation

**Related Commands:**
- `docker compose down` — safe version (preserves data)
- `docker volume rm n8n_data` — delete specific volume (still dangerous)

---

### ⚠️ docker system prune -a --volumes

```bash
docker system prune -a --volumes
```

**Purpose:** Remove ALL unused Docker resources (containers, images, networks, volumes).

**What It Does:**
- Removes all stopped containers
- Removes all unused networks
- Removes all unused images (not just dangling)
- Removes all unused volumes
- **Essentially factory-resets Docker**

**When to Use:**
- ❌ **Almost NEVER** in normal operation
- Only when you want to completely reset Docker
- Only when you've backed up everything
- Only as a last resort

**When NOT to Use:**
- For routine cleanup → use `docker container prune` or `docker image prune`
- When you have data in volumes you want to keep
- When debugging → there's always a less destructive option

**Precautions:**
- 🚨 **DELETES ALL UNUSED VOLUMES** (including your n8n data if containers are stopped)
- 🚨 **DELETES ALL UNUSED IMAGES** (you'll need to re-download)
- There is NO undo
- Copilot used this during our session and later admitted it was a mistake

**Real Example from Our Session:**
- ❌ Copilot ran this command during the debugging session
- Copilot later said: "too destructive for this stage"
- This is documented as a WARNING of what NOT to do

**Related Commands:**
- `docker container prune` — only stopped containers (safer)
- `docker image prune` — only unused images (safer)
- `docker volume prune` — only unused volumes (still risky)

---

### ⚠️ rm -rf n8n_data

```bash
rm -rf n8n_data
```

**Purpose:** Force-remove the n8n data directory (if using bind mount instead of volume).

**What It Does:**
- Recursively force-removes the `n8n_data` directory
- Deletes all n8n workflows, credentials, settings
- No confirmation prompt

**When to Use:**
- ❌ **Almost NEVER**
- Only when you want a complete fresh start
- Only when you've backed up your workflows

**When NOT to Use:**
- For routine cleanup
- When you want to keep your workflows
- When debugging — there's always a less destructive option

**Precautions:**
- 🚨 **DELETES YOUR N8N DATA**
- No undo
- Copilot used this during our session and later admitted it was "risky"

**Real Example from Our Session:**
- ❌ Copilot ran this during the debugging session
- Copilot later said: "risky"
- Documented as a WARNING

**Related Commands:**
- `docker compose down` — safe shutdown (preserves data)
- Backing up data: `docker run --rm -v n8n_data:/data -v $(pwd):/backup alpine tar czf /backup/n8n-backup.tar.gz /data`

---

## Quick Reference Table

| Command | Purpose | Safe? |
|---|---|---|
| `docker compose up -d` | Start services | ✅ Yes |
| `docker compose up -d --build` | Rebuild and start | ✅ Yes |
| `docker compose down` | Stop and remove containers | ✅ Yes (preserves data) |
| `docker compose down -v` | Stop, remove, DELETE VOLUMES | 🚨 DANGEROUS |
| `docker ps` | List running containers | ✅ Yes |
| `docker ps -a` | List all containers | ✅ Yes |
| `docker logs n8n` | View logs | ✅ Yes |
| `docker logs n8n --tail 20` | Recent logs | ✅ Yes |
| `docker logs -f n8n` | Live logs | ✅ Yes (Ctrl+C to exit) |
| `docker exec n8n python3 --version` | Run command in container | ✅ Yes |
| `docker exec -it n8n sh` | Interactive shell | ✅ Yes |
| `docker inspect n8n` | Container details | ✅ Yes |
| `docker rm -f n8n` | Force remove container | ⚠️ Removes container (not data) |
| `docker container prune` | Remove stopped containers | ⚠️ Removes containers (not data) |
| `docker image prune` | Remove unused images | ✅ Yes |
| `docker system prune -a --volumes` | Remove EVERYTHING unused | 🚨 DANGEROUS |
| `rm -rf n8n_data` | Delete data directory | 🚨 DANGEROUS |
| `docker version` | Check Docker version | ✅ Yes |
| `docker compose config` | Validate compose file | ✅ Yes |
| `docker run --rm --entrypoint sh ...` | Inspect image contents | ✅ Yes |

---

## Common Patterns

### The "Start Fresh" Pattern
```bash
docker compose down
docker compose up -d --build
sleep 30
docker ps
docker logs n8n --tail 15
```

### The "Quick Health Check" Pattern
```bash
docker ps
docker logs n8n --tail 10
curl -I http://localhost:5678
```

### The "Debug Origin Errors" Pattern
```bash
docker logs n8n --tail 50 | grep -i "origin"
docker logs n8n-nginx --tail 30
docker inspect --format '{{range .Config.Env}}{{println .}}{{end}}' n8n
```

### The "Safe Shutdown" Pattern
```bash
docker compose down
# Then: Ctrl+Shift+P → "Codespaces: Stop Codespace"
```

---

*Last updated: July 2026*
