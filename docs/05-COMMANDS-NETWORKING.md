# Networking Commands Reference

**Purpose:** Complete reference for networking diagnostic commands used in this project, including curl, ss, lsof, and port diagnostics. These commands help isolate where connection issues are occurring.

**How to use:** Look up a command by name or browse by category. Each entry follows the same template so you can quickly find what you need.

---

## Table of Contents

1. [HTTP Testing with curl](#http-testing-with-curl)
2. [Port & Process Diagnostics](#port--process-diagnostics)
3. [Environment Variables for Networking](#environment-variables-for-networking)
4. [WebSocket Diagnostics](#websocket-diagnostics)
5. [Dangerous Commands — Read First](#dangerous-commands--read-first)
6. [Quick Reference Table](#quick-reference-table)
7. [Common Patterns](#common-patterns)

---

## HTTP Testing with curl

### curl -I http://localhost:5678

```bash
curl -I http://localhost:5678
```

**Purpose:** Send a HEAD request to get HTTP response headers only (no body).

**What It Does:**
- `-I` (capital I) sends a HEAD request
- Returns only the response headers (not the page content)
- Shows status code (200, 404, 502, etc.), content type, server info

**When to Use:**
- Quick check if a server is responding
- Verify HTTP status codes
- Check response headers without downloading the full page
- First step in diagnosing "can't connect" issues

**When NOT to Use:**
- If you need the page content → use `curl http://localhost:5678` (no flag)
- If you need to see request AND response headers → use `curl -v`
- If you need verbose output → use `curl -iv`

**Precautions:**
None — completely read-only and safe.

**Real Example from Our Session:**
```bash
curl -I http://localhost:5678
```
Output:
```
HTTP/1.1 200 OK
Accept-Ranges: bytes
Cache-Control: public, max-age=86400
Content-Type: text/html; charset=utf-8
Content-Length: 19800
Date: Wed, 08 Jul 2026 20:54:59 GMT
Connection: keep-alive
Keep-Alive: timeout=5
```
The `200 OK` confirmed n8n was running and responding locally — narrowing the problem to the proxy/browser layer.

**Related Commands:**
- `curl -i http://localhost:5678` — headers AND body
- `curl -Iv http://localhost:5678` — verbose (shows request + response)
- `curl -Ik https://...` — HTTPS with cert validation disabled

**Common Mistakes:**
- Using lowercase `-i` when you want headers only (lowercase includes body)
- Forgetting to include `http://` (some systems require it)

---

### curl -i http://localhost:5678

```bash
curl -i http://localhost:5678
```

**Purpose:** Send a GET request and show response headers PLUS body.

**What It Does:**
- `-i` (lowercase) includes headers in the output
- Returns the full HTTP response: headers + body
- Useful for seeing what the server actually returns

**When to Use:**
- When you need to see the page content along with headers
- Debugging what the server returns
- Verifying the HTML/body is correct

**When NOT to Use:**
- If you only want headers → use `curl -I` (capital I)
- If the response is large → use `curl -I` to save screen space

**Precautions:**
- Output can be very long (includes full HTML)
- Pipe to `head` if you only want the beginning: `curl -i http://localhost:5678 | head -50`

**Real Example from Our Session:**
```bash
curl -i http://localhost:5678/
```
Output included the full HTML of the n8n editor page, confirming the server was serving content correctly.

**Related Commands:**
- `curl -I http://localhost:5678` — headers only
- `curl http://localhost:5678` — body only (no headers)

---

### curl -Iv http://localhost:5678

```bash
curl -Iv http://localhost:5678
```

**Purpose:** Verbose HEAD request — shows the full HTTP handshake.

**What It Does:**
- `-I` — HEAD request (headers only)
- `-v` — verbose mode
- Shows: connection details, request headers, response headers
- Useful for deep debugging

**When to Use:**
- Debugging connection issues
- Seeing exactly what headers are sent and received
- Understanding the HTTP handshake

**When NOT to Use:**
- Quick checks → `curl -I` is simpler
- When output is too verbose → use `curl -I`

**Precautions:**
- Output is very detailed (can be overwhelming)
- The `>` lines are request headers, `<` lines are response headers, `*` lines are curl info

**Real Example from Our Session:**
Used when we needed to see the full HTTP handshake to understand what the Codespace proxy was doing.

**Related Commands:**
- `curl -I` — non-verbose
- `curl -v` — verbose GET

---

### curl -Ik https://...

```bash
curl -Ik https://curly-succotash-gx4g7x9pq47pcw6pq-5678.app.github.dev
```

**Purpose:** Test an HTTPS URL while ignoring certificate validation.

**What It Does:**
- `-I` — HEAD request (headers only)
- `-k` — insecure (skip SSL/TLS certificate verification)
- Tests HTTPS URLs that might have self-signed or invalid certs

**When to Use:**
- Testing HTTPS URLs in development
- When you get SSL certificate errors
- Testing the Codespace public URL

**When NOT to Use:**
- In production — always verify certs
- When security matters — `-k` bypasses a key security check

**Precautions:**
- ⚠️ `-k` disables certificate verification — don't use with sensitive data
- Fine for testing your own Codespace URLs
- Never use `-k` when transmitting passwords or secrets

**Real Example from Our Session:**
```bash
curl -Ik https://curly-succotash-gx4g7x9pq47pcw6pq-5678.app.github.dev
```
Output showed `HTTP/2 200` — confirming the Codespace proxy was reachable and returning a valid response.

**Related Commands:**
- `curl -I https://...` — with cert validation (safer)
- `curl -Ik -H "Host: ..." https://...` — with custom Host header

---

### curl -i -H "Host: ..." http://localhost:5678

```bash
curl -i -H "Host: curly-succotash-gx4g7x9pq47pcw6pq-5678.app.github.dev" http://localhost:5678/
```

**Purpose:** Send a request with a custom Host header to simulate a proxy.

**What It Does:**
- `-H "Host: ..."` — overrides the default Host header
- Simulates what the Codespace proxy does when forwarding requests
- Tests whether n8n behaves differently with different Host headers

**When to Use:**
- Simulating proxy behavior
- Testing virtual host configurations
- Debugging origin/host header issues

**When NOT to Use:**
- Normal testing → use `curl -I http://localhost:5678`
- When you don't need to manipulate headers

**Precautions:**
None — read-only, safe to use.

**Real Example from Our Session:**
```bash
curl -i -H "Host: curly-succotash-gx4g7x9pq47pcw6pq-5678.app.github.dev" http://localhost:5678/
```
This was suggested by Copilot to simulate the Codespace proxy and test n8n's behavior with the correct Host header.

**Related Commands:**
- `curl -i -H "Origin: ..." http://localhost:5678` — test Origin header
- `curl -i -H "X-Forwarded-For: ..." http://localhost:5678` — test proxy headers

---

### curl -Ik -H "Origin: ..." https://...

```bash
curl -Ik -H "Origin: https://curly-succotash-gx4g7x9pq47pcw6pq-5678.app.github.dev" https://curly-succotash-gx4g7x9pq47pcw6pq-5678.app.github.dev
```

**Purpose:** Test an HTTPS URL with a custom Origin header.

**What It Does:**
- Sends a request with a specific Origin header
- Useful for testing CORS and WebSocket origin checks
- Helps diagnose origin mismatch issues

**When to Use:**
- Debugging "Origin header does NOT match" errors
- Testing CORS configurations
- Verifying WebSocket origin validation

**When NOT to Use:**
- Normal testing → use `curl -I`

**Precautions:**
None — read-only, safe.

**Real Example from Our Session:**
Used to test how n8n responded to different Origin headers, helping us understand the origin mismatch issue.

**Related Commands:**
- `curl -i -H "Host: ..."` — test Host header
- `curl -v` — verbose output

---

## Port & Process Diagnostics

### ss -ltnp | grep :5678

```bash
ss -ltnp | grep :5678
```

**Purpose:** Show what process is listening on port 5678.

**What It Does:**
- `ss` — socket statistics (modern replacement for `netstat`)
- `-l` — listening sockets only
- `-t` — TCP sockets only
- `-n` — numeric ports (don't resolve to names)
- `-p` — show process info
- `| grep :5678` — filter for port 5678

**When to Use:**
- Checking if a port is actually listening
- Finding which process owns a port
- Debugging "port already in use" errors
- Verifying Docker port mappings

**When NOT to Use:**
- If you need more detail → use `lsof -i :5678`
- If `ss` isn't available → use `netstat`

**Precautions:**
- May need `sudo` to see process names (otherwise shows PID only)
- Read-only — safe to run

**Real Example from Our Session:**
```bash
ss -tlnp | grep 5678
```
Output confirmed that `docker-proxy` was listening on port 5678, verifying Docker's port mapping was correct.

**Related Commands:**
- `sudo ss -ltnp | grep :5678` — with sudo (shows process names)
- `lsof -nP -iTCP:5678 -sTCP:LISTEN` — alternative
- `netstat -tuln | grep 5678` — older alternative

**Common Mistakes:**
- Forgetting `sudo` → process names not shown
- Using `:5678` vs `5678` (both work, but `:5678` is more precise)

---

### sudo ss -ltnp | grep :5678

```bash
sudo ss -ltnp | grep :5678
```

**Purpose:** Same as above, but with sudo to see process names.

**What It Does:**
- Same as `ss -ltnp | grep :5678`
- `sudo` allows seeing the actual process name (not just PID)
- More informative for debugging

**When to Use:**
- When you need to know WHICH process owns the port
- When the non-sudo version only shows PIDs

**When NOT to Use:**
- If you don't have sudo access → use `ss -ltnp` without sudo
- For quick checks → `ss -ltnp` may be enough

**Precautions:**
- Requires sudo privileges
- Read-only — safe to run

**Real Example from Our Session:**
```bash
sudo ss -ltnp | grep :5678
```
Output showed the `docker-proxy` process name, confirming Docker was the process listening on port 5678.

**Related Commands:**
- `ss -ltnp | grep :5678` — without sudo
- `lsof -nP -iTCP:5678 -sTCP:LISTEN` — alternative

---

### lsof -nP -iTCP:5678 -sTCP:LISTEN

```bash
lsof -nP -iTCP:5678 -sTCP:LISTEN
```

**Purpose:** Show which process is listening on port 5678 (alternative to ss).

**What It Does:**
- `lsof` — list open files (network sockets count as files in Linux)
- `-n` — numeric addresses (don't resolve DNS)
- `-P` — numeric ports (don't convert to service names)
- `-iTCP:5678` — TCP connections on port 5678
- `-sTCP:LISTEN` — only listening sockets

**When to Use:**
- Alternative to `ss` (some systems don't have `ss`)
- When you need detailed process info
- Cross-platform compatibility (lsof is available on macOS too)

**When NOT to Use:**
- `ss` is usually faster and more modern
- If `lsof` isn't installed

**Precautions:**
- May need `sudo` for full process info
- Not installed on all systems by default

**Real Example from Our Session:**
Suggested by Copilot as an alternative when `ss` didn't give enough detail.

**Related Commands:**
- `ss -ltnp | grep :5678` — modern alternative
- `netstat -tuln | grep 5678` — older alternative

---

### netstat -tuln | grep 5678

```bash
netstat -tuln | grep 5678
```

**Purpose:** Show listening ports (older alternative to ss).

**What It Does:**
- `netstat` — network statistics (older tool)
- `-t` — TCP
- `-u` — UDP
- `-l` — listening
- `-n` — numeric
- `| grep 5678` — filter for port 5678

**When to Use:**
- On older systems where `ss` isn't available
- When `ss` isn't installed
- For compatibility with older tutorials

**When NOT to Use:**
- `ss` is the modern replacement (faster, more features)
- On modern systems → prefer `ss`

**Precautions:**
- `netstat` is deprecated on some systems
- May need `sudo` for process info

**Real Example from Our Session:**
Not used directly — we used `ss` instead, which is the modern standard.

**Related Commands:**
- `ss -ltnp | grep :5678` — modern alternative
- `lsof -nP -iTCP:5678 -sTCP:LISTEN` — another alternative

---

### docker port n8n

```bash
docker port n8n
```

**Purpose:** Show port mappings for a Docker container.

**What It Does:**
- Lists which container ports are mapped to which host ports
- Helps verify Docker's port forwarding

**When to Use:**
- Verifying port mappings after starting a container
- Debugging "can't access the app" issues
- Checking if a port is exposed

**When NOT to Use:**
- If using Docker Compose → `docker compose ps` shows ports too
- For system-wide port checks → use `ss`

**Precautions:**
None — read-only.

**Real Example from Our Session:**
```bash
docker port n8n && echo '---' && curl -I http://127.0.0.1:8080
```
Combined command to verify port mapping AND test HTTP response.

**Related Commands:**
- `docker ps` — shows ports in table format
- `docker compose port n8n 5678` — specific port query

---

### docker port n8n && echo '---' && curl -I http://127.0.0.1:8080

```bash
docker port n8n && echo '---' && curl -I http://127.0.0.1:8080
```

**Purpose:** Combined command — verify port mapping AND test HTTP response.

**What It Does:**
- `docker port n8n` — shows port mappings
- `&&` — runs next command only if previous succeeds
- `echo '---'` — prints a separator line
- `&&` — runs next command
- `curl -I http://127.0.0.1:8080` — tests HTTP response

**When to Use:**
- Quick two-in-one diagnostic
- Verifying both port mapping and HTTP response
- When you want clean, separated output

**When NOT to Use:**
- If you need to check each separately
- In scripts where you need to handle failures independently

**Precautions:**
None — read-only.

**Real Example from Our Session:**
Used to verify that Docker was publishing port 8080 to container port 5678 AND that n8n was responding.

**Related Commands:**
- `docker port n8n` — just port mapping
- `curl -I http://localhost:5678` — just HTTP test

---

## Environment Variables for Networking

### echo $CODESPACE_NAME

```bash
echo $CODESPACE_NAME
```

**Purpose:** Print the Codespace name (used to construct URLs).

**What It Does:**
- Outputs the value of the `CODESPACE_NAME` environment variable
- This is set automatically by GitHub Codespaces
- Used to construct your Codespace's public URL

**When to Use:**
- Finding your Codespace name
- Constructing URLs for configuration files
- Debugging URL issues

**When NOT to Use:**
- Outside of Codespaces → the variable won't be set

**Precautions:**
- If output is empty, you're not in a Codespace (or the variable isn't set)
- The variable is set by Codespaces, not by you

**Real Example from Our Session:**
```bash
echo $CODESPACE_NAME
```
Output: `curly-succotash-gx4g7x9pq47pcw6pq`

**Related Commands:**
- `echo $GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN` — the domain suffix
- `printenv | grep CODESPACE` — all Codespace-related variables

---

### echo "https://${CODESPACE_NAME}-5678.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"

```bash
echo "https://${CODESPACE_NAME}-5678.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
```

**Purpose:** Construct and print your Codespace's public URL for a specific port.

**What It Does:**
- Combines two environment variables to build the URL
- `${CODESPACE_NAME}` — your Codespace's name
- `${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}` — the domain suffix (usually `app.github.dev`)
- Outputs the full URL

**When to Use:**
- Finding your n8n URL for configuration
- Verifying environment variables are set correctly
- Debugging URL configuration issues

**When NOT to Use:**
- If the variables aren't set (output will be malformed)

**Precautions:**
- If output is `https://-5678.` (empty middle), the variables aren't set
- Variables are automatically set by Codespaces

**Real Example from Our Session:**
```bash
echo "URL=https://${CODESPACE_NAME}-5678.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
```
Output: `URL=https://curly-succotash-gx4g7x9pq47pcw6pq-5678.app.github.dev`

**Related Commands:**
- `echo $CODESPACE_NAME` — just the name
- `printenv | grep CODESPACE` — all Codespace variables

---

### printenv | grep CODESPACE

```bash
printenv | grep CODESPACE
```

**Purpose:** Show all Codespace-related environment variables.

**What It Does:**
- `printenv` — print all environment variables
- `| grep CODESPACE` — filter for Codespace-related ones
- Shows all variables that contain "CODESPACE" in their name

**When to Use:**
- Discovering what Codespace variables are available
- Debugging configuration that depends on Codespace variables
- Learning what information Codespaces provides

**When NOT to Use:**
- If you know which variable you need → use `echo $VAR_NAME`

**Precautions:**
None — read-only.

**Real Example from Our Session:**
Used to discover all available Codespace environment variables for configuration.

**Related Commands:**
- `echo $CODESPACE_NAME` — specific variable
- `env | grep CODESPACE` — alternative to printenv

---

## WebSocket Diagnostics

### curl -i -H "Connection: Upgrade" -H "Upgrade: websocket" ...

```bash
curl -i -H "Connection: Upgrade" -H "Upgrade: websocket" -H "Sec-WebSocket-Version: 13" -H "Sec-WebSocket-Key: test" http://localhost:5678/rest/push-websocket
```

**Purpose:** Simulate a WebSocket handshake to test if the WebSocket endpoint is working.

**What It Does:**
- Sends the headers needed for a WebSocket upgrade
- Tests if the server accepts WebSocket connections
- If successful, returns `HTTP/1.1 101 Switching Protocols`

**When to Use:**
- Debugging WebSocket connection issues
- Testing if the WebSocket endpoint is reachable
- Verifying WebSocket upgrade is working

**When NOT to Use:**
- Normal HTTP testing → use `curl -I`
- For full WebSocket testing → use a WebSocket client

**Precautions:**
- This is a simplified test — doesn't complete the WebSocket handshake
- Useful for verifying the endpoint exists and accepts upgrades

**Real Example from Our Session:**
Used to verify that the WebSocket endpoint at `/rest/push-websocket` was accepting connections. After the Nginx fix, this returned `101 Switching Protocols`.

**Related Commands:**
- `curl -I http://localhost:5678` — basic HTTP test
- `curl -v ...` — verbose output

---

### Testing the /rest/push-websocket endpoint

```bash
curl -I http://localhost:5678/rest/push-websocket
```

**Purpose:** Test if n8n's WebSocket endpoint is reachable.

**What It Does:**
- Sends a HEAD request to the WebSocket endpoint
- Returns the HTTP status code
- Helps verify the endpoint exists and is responding

**When to Use:**
- Debugging "Connection Lost" errors
- Verifying the WebSocket endpoint is accessible
- Testing the push backend

**When NOT to Use:**
- For full WebSocket testing → use a browser or WebSocket client

**Precautions:**
- May return 401 (unauthorized) or 426 (upgrade required) — these are normal
- 404 means the endpoint doesn't exist

**Real Example from Our Session:**
Used to verify the push-websocket endpoint was accessible.

**Related Commands:**
- `curl -I http://localhost:5678/rest/settings` — test settings endpoint
- `curl -I http://localhost:5678/healthz` — health check endpoint

---

### curl -s http://localhost:5678/rest/settings

```bash
curl -s http://localhost:5678/rest/settings | head -200
```

**Purpose:** Fetch n8n's frontend configuration to see what URLs it sends to the browser.

**What It Does:**
- `-s` — silent mode (no progress bar)
- Fetches the JSON configuration n8n sends to the browser
- `| head -200` — show first 200 lines

**When to Use:**
- Debugging why the browser is using the wrong URL
- Checking what configuration n8n sends to the frontend
- Investigating WebSocket URL issues

**When NOT to Use:**
- For basic health checks → use `curl -I`

**Precautions:**
- Output is JSON — can be large
- May contain sensitive info (don't share publicly without reviewing)

**Real Example from Our Session:**
Used to check if n8n was sending `localhost` as the WebSocket URL to the browser, which would explain the "Connection Lost" error.

**Related Commands:**
- `curl -I http://localhost:5678/rest/settings` — headers only
- `curl -s http://localhost:5678/rest/settings | python3 -m json.tool` — pretty-print JSON

---

## Dangerous Commands — Read First

### ⚠️ fuser -k 5678/tcp

```bash
fuser -k 5678/tcp
```

**Purpose:** Kill all processes using port 5678.

**What It Does:**
- Finds all processes listening on or connected to port 5678
- `-k` — kills them
- Force-frees the port

**When to Use:**
- ❌ **Almost NEVER** — there are safer alternatives
- When a port is stuck and you can't free it any other way
- Last resort for port conflicts

**When NOT to Use:**
- For routine port conflicts → use `docker compose down` to stop containers
- When Docker is managing the port → stop the container instead
- Without checking what's using the port first

**Precautions:**
- 🚨 **Kills processes without warning** — can cause data loss
- 🚨 **Can kill Docker** if Docker is using the port
- Always check `ss -ltnp | grep :5678` first to see what you're killing
- Copilot used this during our session and it was unnecessary

**Real Example from Our Session:**
- ❌ Copilot ran this command
- It was unnecessary — `docker compose down` would have been safer
- Documented as a WARNING

**Related Commands:**
- `ss -ltnp | grep :5678` — check what's using the port (safe)
- `docker compose down` — stop containers safely
- `kill <PID>` — kill a specific process (more targeted)

---

### ⚠️ pkill -f "gh codespace ports"

```bash
pkill -f "gh codespace ports"
```

**Purpose:** Kill all processes matching "gh codespace ports".

**What It Does:**
- `-f` — match against the full command line
- Kills all processes whose command includes "gh codespace ports"
- Used to clean up stuck `gh` port-forwarding processes

**When to Use:**
- When `gh codespace ports forward` is stuck
- Cleaning up stray port-forwarding processes
- When `gh` commands are hanging

**When NOT to Use:**
- Without checking what processes it will kill first
- When you're not sure what's running

**Precautions:**
- ⚠️ Kills all matching processes — check with `ps aux | grep "gh codespace ports"` first
- Can disrupt active port forwarding
- Use carefully

**Real Example from Our Session:**
Used to clean up stuck `gh` port-forwarding processes that were interfering with the Codespace tunnel.

**Related Commands:**
- `ps aux | grep "gh codespace ports"` — see processes before killing
- `kill <PID>` — kill specific process

---

## Quick Reference Table

| Command | Purpose | Safe? |
|---|---|---|
| `curl -I http://localhost:5678` | Test HTTP (headers only) | ✅ Yes |
| `curl -i http://localhost:5678` | Test HTTP (headers + body) | ✅ Yes |
| `curl -Iv http://localhost:5678` | Verbose HTTP test | ✅ Yes |
| `curl -Ik https://...` | HTTPS test (skip cert check) | ⚠️ Skip cert validation |
| `curl -i -H "Host: ..." http://...` | Custom Host header | ✅ Yes |
| `curl -i -H "Origin: ..." http://...` | Custom Origin header | ✅ Yes |
| `ss -ltnp \| grep :5678` | Check listening port | ✅ Yes |
| `sudo ss -ltnp \| grep :5678` | Check port (with process name) | ✅ Yes (needs sudo) |
| `lsof -nP -iTCP:5678 -sTCP:LISTEN` | Alternative port check | ✅ Yes |
| `netstat -tuln \| grep 5678` | Older port check | ✅ Yes |
| `docker port n8n` | Show container port mappings | ✅ Yes |
| `echo $CODESPACE_NAME` | Get Codespace name | ✅ Yes |
| `echo "https://..."` | Construct Codespace URL | ✅ Yes |
| `printenv \| grep CODESPACE` | All Codespace variables | ✅ Yes |
| `curl -s http://localhost:5678/rest/settings` | n8n frontend config | ✅ Yes |
| `fuser -k 5678/tcp` | Kill processes on port | 🚨 DANGEROUS |
| `pkill -f "gh codespace ports"` | Kill gh port processes | ⚠️ Use carefully |

---

## Common Patterns

### The "Is the Server Alive?" Pattern
```bash
curl -I http://localhost:5678
```
If this returns `200 OK` — the server is alive. If it fails — the server is down or not listening.

### The "Full Network Diagnostic" Pattern
```bash
# 1. Check if port is listening
ss -ltnp | grep :5678

# 2. Check HTTP response
curl -I http://localhost:5678

# 3. Check container port mapping
docker port n8n

# 4. Check container logs
docker logs n8n --tail 20
```

### The "Find My Codespace URL" Pattern
```bash
echo "https://${CODESPACE_NAME}-5678.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
```

### The "Test Public URL" Pattern
```bash
curl -Ik https://${CODESPACE_NAME}-5678.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}
```

### The "Debug Origin Issues" Pattern
```bash
# 1. Check n8n logs for origin errors
docker logs n8n --tail 50 | grep -i "origin"

# 2. Check what n8n thinks its URL is
docker logs n8n --tail 10

# 3. Check the env vars
docker inspect --format '{{range .Config.Env}}{{println .}}{{end}}' n8n | grep -E "URL|ORIGIN|HOST"

# 4. Test the WebSocket endpoint
curl -I http://localhost:5678/rest/push-websocket
```

### The "Port Conflict Resolution" Pattern
```bash
# 1. Check what's using the port
ss -ltnp | grep :5678

# 2. If it's Docker, stop the container
docker compose down

# 3. Verify the port is free
ss -ltnp | grep :5678

# 4. Restart
docker compose up -d
```

### The "Combined Port + HTTP Check" Pattern
```bash
docker port n8n && echo '---' && curl -I http://localhost:5678
```

---

## Key Principles for Network Debugging

1. **Test locally first** — `curl http://localhost:PORT` before testing the public URL
2. **If local works but public doesn't** — the issue is in the proxy, not your app
3. **Check what's listening** — `ss -ltnp | grep :PORT` is your friend
4. **Check container port mappings** — `docker port <container>`
5. **Check logs** — `docker logs <container>` often reveals the real error
6. **Use `-I` for quick checks** — no need to download the full page
7. **Use `-v` for deep debugging** — shows the full HTTP handshake
8. **Use `-k` for HTTPS testing** — but never in production
9. **Don't kill processes blindly** — always check `ss` or `ps` first
10. **Verify env vars** — `echo $VAR` confirms they're set

---

*Last updated: July 2026*
