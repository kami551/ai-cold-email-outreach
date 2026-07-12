# GitHub Codespaces Commands & UI Actions Reference

**Purpose:** Complete reference for GitHub Codespaces commands (CLI and UI), including the Codespace lifecycle, port management, and how to save your free hours.

**How to use:** Look up a command by name or browse by category. Each entry follows the same template so you can quickly find what you need.

---

## Table of Contents

1. [Codespace Lifecycle Management](#codespace-lifecycle-management)
2. [Port Forwarding (CLI)](#port-forwarding-cli)
3. [Port Forwarding (VS Code UI)](#port-forwarding-vs-code-ui)
4. [Codespace Information](#codespace-information)
5. [Codespace Configuration](#codespace-configuration)
6. [Rebuild & Reset](#rebuild--reset)
7. [Free Hours Management](#free-hours-management)
8. [Dangerous Actions — Read First](#dangerous-actions--read-first)
9. [Quick Reference Table](#quick-reference-table)
10. [Common Patterns](#common-patterns)
11. [Codespace Lifecycle Facts](#codespace-lifecycle-facts)

---

## Codespace Lifecycle Management

### Stop Codespace (VS Code UI)

```bash
# Via VS Code Command Palette
# Press: Ctrl+Shift+P
# Type: "Codespaces: Stop Codespace"
# Press: Enter
```

**Purpose:** Stop the Codespace to save free hours when not in use.

**What It Does:**
- Stops the Codespace (similar to shutting down a VM)
- All containers and processes stop
- Files and data are preserved
- Stops billing against your free hours
- The Codespace can be restarted later

**When to Use:**
- At the end of a work session
- Before going to sleep
- When you won't be working for several hours
- To conserve free hours

**When NOT to Use:**
- If you'll be back in 5 minutes → just leave it (idle timeout will handle it)
- If you have long-running processes → let them finish first

**Precautions:**
- Stopping does NOT delete anything
- Your Docker volumes, files, and git history are preserved
- The Codespace can always be restarted

**Real Example from Our Session:**
Used every night before sleeping:
1. `docker compose down` (stop containers)
2. Ctrl+Shift+P → "Codespaces: Stop Codespace"

**Related Actions:**
- Restart Codespace (from github.com/codespaces)
- Codespace auto-stops after idle timeout (default 30 min, max 4 hours)

---

### Open Codespace (from GitHub)

```bash
# Via web browser
# Go to: https://github.com/codespaces
# Find your Codespace
# Click "Open"
```

**Purpose:** Restart a stopped Codespace.

**What It Does:**
- Wakes up the Codespace
- Restores the VS Code environment
- Docker daemon restarts (containers do NOT auto-start)
- Takes 30-60 seconds

**When to Use:**
- Starting a new work session
- After the Codespace auto-slept
- After you manually stopped it

**When NOT to Use:**
- If the Codespace is already running → just open VS Code

**Precautions:**
- Docker containers do NOT auto-start → you must run `docker compose up -d`
- Files and data are preserved
- Git is preserved

**Real Example from Our Session:**
Every morning:
1. Open https://github.com/codespaces
2. Click "Open" on the Codespace
3. Wait 30-60 seconds
4. Run `docker compose up -d`

**Related Actions:**
- Stop Codespace
- Rebuild Container (different — recreates the devcontainer)

---

### Codespace Auto-Sleep

```bash
# No command — this happens automatically
# Default: 30 minutes of inactivity
# Maximum you can set: 4 hours (240 minutes)
```

**Purpose:** Codespaces automatically stop after inactivity to save resources.

**What It Does:**
- Monitors for activity (terminal commands, file saves, etc.)
- After idle timeout, automatically stops the Codespace
- Stops billing against your free hours
- Preserves all files and data

**When to Use:**
- This is automatic — you don't trigger it
- Just be aware it happens

**When NOT to Use:**
- You can't disable it (max is 4 hours)

**Precautions:**
- n8n will stop running when the Codespace sleeps
- Webhooks from external services won't reach n8n while sleeping
- Always commit your work before walking away

**Real Example from Our Session:**
The Codespace auto-slept multiple times during our 4-day debugging session. Each time, we had to:
1. Reopen the Codespace
2. Run `docker compose up -d`
3. Wait 30 seconds

**Related Actions:**
- Set idle timeout (max 4 hours) at github.com/settings/codespaces

---

## Port Forwarding (CLI)

### gh codespace ports list

```bash
gh codespace ports list
```

**Purpose:** List all forwarded ports in the current Codespace.

**What It Does:**
- Uses GitHub CLI (`gh`) to query Codespace port forwarding
- Shows port numbers, visibility (public/private), and URLs
- Alternative to the VS Code Ports tab

**When to Use:**
- Scripting port management
- Quick check from the terminal
- When VS Code UI isn't available

**When NOT to Use:**
- For quick visual checks → VS Code Ports tab is easier
- If `gh` CLI isn't authenticated

**Precautions:**
- Requires `gh` CLI to be authenticated
- May return blank if no ports are forwarded

**Real Example from Our Session:**
```bash
gh codespace ports list
```
Used by Copilot to check the state of port forwarding.

**Related Commands:**
- `gh codespace ports forward` — forward a port
- `gh codespace list` — list all Codespaces

---

### gh codespace ports forward

```bash
gh codespace ports forward -c "curly-succotash-gx4g7x9pq47pcw6pq" 5678:5678
```

**Purpose:** Forward a port from the Codespace to your local machine.

**What It Does:**
- Forwards port 5678 from the Codespace to port 5678 locally
- Allows you to access the service via `localhost:5678`
- Alternative to VS Code's automatic port forwarding

**When to Use:**
- When VS Code's automatic forwarding isn't working
- For scripting
- When you need explicit control

**When NOT to Use:**
- For normal use → VS Code auto-forwards ports declared in devcontainer.json
- When the port is already forwarded

**Precautions:**
- This runs in the foreground (blocks terminal)
- Press Ctrl+C to stop forwarding
- Multiple variants exist (see below)

**Real Example from Our Session:**
Copilot tried several variants:
```bash
gh codespace ports forward -c "curly-succotash-gx4g7x9pq47pcw6pq" --port 5678 --public
gh codespace ports forward -c "curly-succotash-gx4g7x9pq47pcw6pq" 5678:5678 --public
gh codespace ports forward -c "curly-succotash-gx4g7x9pq47pcw6pq" 5678:5678 --visibility public
gh codespace ports forward -c "curly-succotash-gx4g7x9pq47pcw6pq" 5678:5678
```
The exact syntax depends on the `gh` CLI version.

**Related Commands:**
- `gh codespace ports list` — see forwarded ports
- VS Code Ports tab — UI alternative

---

### gh codespace list

```bash
gh codespace list
gh codespace list --repo kami551/ai-cold-email-outreach --json name
```

**Purpose:** List all your Codespaces.

**What It Does:**
- Lists all Codespaces on your account
- Shows names, repositories, last used dates
- With `--json`, outputs structured data

**When to Use:**
- Finding your Codespace name
- Checking which Codespaces exist
- Scripting Codespace management

**When NOT to Use:**
- If you know your Codespace name → just use it

**Precautions:**
None — read-only.

**Real Example from Our Session:**
```bash
gh codespace list --repo kami551/ai-cold-email-outreach --json name
```
Used to find the exact Codespace name for other `gh` commands.

**Related Commands:**
- `gh codespace ports list` — ports for a Codespace
- `echo $CODESPACE_NAME` — current Codespace name (faster)

---

## Port Forwarding (VS Code UI)

### Forward a Port (VS Code Ports Tab)

```bash
# Via VS Code UI:
# 1. Click "Ports" tab (bottom panel)
# 2. Click "Forward a Port" button (or + icon)
# 3. Type: 5678
# 4. Press Enter
```

**Purpose:** Forward a port so it's accessible from the browser.

**What It Does:**
- Creates a port forwarding entry
- Generates a public URL for the port
- Makes the service accessible outside the Codespace

**When to Use:**
- When you need to access a service from the browser
- After starting a new service on a new port
- When a port isn't automatically forwarded

**When NOT to Use:**
- If the port is already forwarded (check the Ports tab first)
- Ports in `forwardPorts` in devcontainer.json are auto-forwarded

**Precautions:**
- New ports default to "Private" visibility
- Change to "Public" for browser access (see next action)

**Real Example from Our Session:**
Port 5678 was auto-forwarded via `forwardPorts: [5678]` in devcontainer.json. We also manually forwarded it when the auto-forwarding got stuck.

---

### Set Port Visibility to Public

```bash
# Via VS Code UI:
# 1. Open "Ports" tab (bottom panel)
# 2. Find port 5678
# 3. Right-click the row
# 4. Hover over "Port Visibility"
# 5. Click "Public"
```

**Purpose:** Make a forwarded port accessible from the browser.

**What It Does:**
- Changes port visibility from Private to Public
- Allows anyone with the URL to access the service
- Required for browser access to n8n

**When to Use:**
- After forwarding a port
- When the browser can't reach your service
- When "Refused to Connect" errors appear

**When NOT to Use:**
- For sensitive services → keep Private
- In shared environments → be cautious

**Precautions:**
- ⚠️ Public ports are accessible to anyone with the URL
- For n8n in Codespaces, Public is necessary
- Anyone with the URL can access your n8n instance (until it sleeps)

**Real Example from Our Session:**
This was the fix for "Refused to Connect" errors. After setting port 5678 to Public, the browser could reach n8n.

---

### Unforward a Port

```bash
# Via VS Code UI:
# 1. Open "Ports" tab
# 2. Find the port
# 3. Right-click the row
# 4. Click "Unforward Port"
```

**Purpose:** Remove port forwarding for a specific port.

**What It Does:**
- Stops forwarding the port
- Removes the public URL
- Frees the port

**When to Use:**
- When port forwarding is stuck
- Before re-adding a port (to reset it)
- When you no longer need the service accessible

**When NOT to Use:**
- If the service is still running and needed

**Precautions:**
- The service keeps running inside the Codespace
- Only the forwarding is removed

**Real Example from Our Session:**
Used to reset stuck port forwarding. After unforwarding, we re-forwarded port 5678 and set it to Public.

---

### Copy Port URL

```bash
# Via VS Code UI:
# 1. Open "Ports" tab
# 2. Find the port
# 3. Right-click the row
# 4. Click "Copy Local Address"
# OR: Click the URL in "Local Address" column
```

**Purpose:** Copy the public URL for a forwarded port.

**What It Does:**
- Copies the URL to your clipboard
- URL looks like: `https://<codespace-name>-<port>.app.github.dev`

**When to Use:**
- When you need to share the URL
- When opening the URL in a browser
- For configuring environment variables

**When NOT to Use:**
- For local testing → use `http://localhost:PORT`

**Real Example from Our Session:**
Used to get the n8n URL for `N8N_EDITOR_BASE_URL` and `WEBHOOK_URL` in docker-compose.yml.

---

## Codespace Information

### echo $CODESPACE_NAME

```bash
echo $CODESPACE_NAME
```

**Purpose:** Get the current Codespace's name.

**What It Does:**
- Prints the Codespace name (e.g., `curly-succotash-gx4g7x9pq47pcw6pq`)
- This is set automatically by Codespaces
- Used to construct URLs

**When to Use:**
- Finding your Codespace name
- Constructing URLs for configuration
- Debugging URL issues

**When NOT to Use:**
- Outside of Codespaces → variable won't be set

**Precautions:**
- If output is empty, you're not in a Codespace

**Real Example from Our Session:**
```bash
echo $CODESPACE_NAME
```
Output: `curly-succotash-gx4g7x9pq47pcw6pq`

**Related Commands:**
- `echo $GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN` — domain suffix
- `printenv | grep CODESPACE` — all Codespace variables

---

### echo $GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN

```bash
echo $GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN
```

**Purpose:** Get the domain suffix for Codespace URLs.

**What It Does:**
- Prints the domain (usually `app.github.dev`)
- Combined with Codespace name and port to form URLs

**When to Use:**
- Constructing URLs programmatically
- Verifying the domain

**When NOT to Use:**
- If you know it's `app.github.dev` (it almost always is)

**Precautions:**
None — read-only.

**Real Example from Our Session:**
```bash
echo "https://${CODESPACE_NAME}-5678.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
```
Output: `https://curly-succotash-gx4g7x9pq47pcw6pq-5678.app.github.dev`

---

### printenv | grep CODESPACE

```bash
printenv | grep CODESPACE
```

**Purpose:** Show all Codespace-related environment variables.

**What It Does:**
- Lists all environment variables containing "CODESPACE"
- Useful for discovering what information is available

**When to Use:**
- Discovering available Codespace variables
- Debugging configuration

**When NOT to Use:**
- If you know which variable you need → use `echo $VAR_NAME`

**Precautions:**
None — read-only.

---

## Codespace Configuration

### Set Idle Timeout

```bash
# Via web browser:
# 1. Go to: https://github.com/settings/codespaces
# 2. Find "Default idle timeout"
# 3. Change to: 240 (max 4 hours)
# 4. Click "Save"
```

**Purpose:** Set how long the Codespace stays awake when idle.

**What It Does:**
- Configures the idle timeout (5 to 240 minutes)
- After this period of inactivity, the Codespace auto-stops
- Maximum is 4 hours (240 minutes)

**When to Use:**
- When the default 30 minutes is too short
- When you want longer uninterrupted work sessions
- To reduce how often you need to restart

**When NOT to Use:**
- Setting it to max (4 hours) if you want to conserve free hours

**Precautions:**
- Maximum is 4 hours — no way to keep Codespace awake indefinitely
- Longer timeout = more free hours consumed
- Known bug: existing Codespaces may not update — may need to recreate

**Real Example from Our Session:**
Set to 240 minutes (4 hours) at https://github.com/settings/codespaces

**Related Actions:**
- View free hours usage at github.com/settings/billing

---

### gh codespace edit

```bash
gh codespace edit -c $CODESPACE_NAME --idle-timeout 240
```

**Purpose:** Update Codespace settings via CLI.

**What It Does:**
- Updates the Codespace's idle timeout
- Alternative to the web UI

**When to Use:**
- Scripting Codespace configuration
- Quick updates from terminal

**When NOT to Use:**
- Web UI is easier for one-time changes

**Precautions:**
- Known bug: may not apply to existing Codespaces
- May need to delete and recreate the Codespace

**Real Example from Our Session:**
Tried this command but it didn't work due to the bug. Used the web UI instead.

---

## Rebuild & Reset

### Rebuild Container

```bash
# Via VS Code Command Palette:
# 1. Press: Ctrl+Shift+P
# 2. Type: "Codespaces: Rebuild Container"
# 3. Press: Enter
# 4. Confirm
# 5. Wait 3-4 minutes
```

**Purpose:** Rebuild the Codespace's devcontainer (apply devcontainer.json changes).

**What It Does:**
- Re-reads `devcontainer.json`
- Rebuilds the Docker container that IS the Codespace
- Installs features, extensions, etc.
- Preserves your files and git history

**When to Use:**
- After modifying `devcontainer.json`
- After adding a new feature
- When Docker-in-Docker isn't working
- As a "reset" when something is fundamentally broken

**When NOT to Use:**
- For app-level changes → just restart Docker containers
- For routine work → unnecessary

**Precautions:**
- Takes 3-4 minutes
- Docker containers inside the Codespace are stopped (but not removed)
- Your files are preserved
- After rebuild, run `docker compose up -d` to restart n8n

**Real Example from Our Session:**
Used after changing `devcontainer.json` to use `docker-in-docker:4.0.0`. After the rebuild, Docker was available.

---

### Full Rebuild (Rebuild Container without Cache)

```bash
# Via VS Code Command Palette:
# 1. Press: Ctrl+Shift+P
# 2. Type: "Codespaces: Rebuild Container Without Cache"
# 3. Press: Enter
# 4. Confirm
```

**Purpose:** Rebuild the Codespace from scratch (no cache).

**What It Does:**
- Same as Rebuild Container, but ignores cache
- Slower but ensures a completely fresh build
- Fixes issues caused by corrupted cache

**When to Use:**
- When regular Rebuild Container doesn't fix the issue
- After major devcontainer.json changes
- When you suspect cache corruption

**When NOT to Use:**
- For routine rebuilds → regular Rebuild is faster
- First try regular Rebuild

**Precautions:**
- Takes longer (5-10 minutes)
- Completely fresh build

---

## Free Hours Management

### Check Free Hours Usage

```bash
# Via web browser:
# Go to: https://github.com/settings/billing
# Find: "Codespaces" section
# View: Used hours and remaining hours
```

**Purpose:** Monitor your Codespaces free hours usage.

**What It Does:**
- Shows how many hours you've used this month
- Shows your monthly quota
- Helps you budget your free hours

**When to Use:**
- When you're running low on hours
- Monthly check
- When planning extended work

**When NOT to Use:**
- Daily checks → the Codespace auto-sleep handles it

**Precautions:**
- Free tier: 60 hours/month (Pro: 180 hours/month)
- 2-core Codespaces use hours faster than 1-core

**Real Example from Our Session:**
Checked periodically to ensure we weren't running out of free hours during the 4-day debugging session.

---

### Stop Codespace to Save Hours

```bash
# The pattern:
docker compose down
# Then: Ctrl+Shift+P → "Codespaces: Stop Codespace"
```

**Purpose:** Stop everything to conserve free hours.

**What It Does:**
- `docker compose down` stops containers (frees resources inside Codespace)
- "Stop Codespace" stops the Codespace itself (stops billing)

**When to Use:**
- At the end of every work session
- Before sleeping
- When you won't work for several hours

**When NOT to Use:**
- For short breaks (5-30 minutes) → let idle timeout handle it

**Precautions:**
- Always commit your work before stopping
- Your data is preserved in Docker volumes
- Restarting takes 30-60 seconds

**Real Example from Our Session:**
Every night:
```bash
git add .
git commit -m "Save work before sleeping"
git push
docker compose down
# Then: Ctrl+Shift+P → "Codespaces: Stop Codespace"
```

---

## Dangerous Actions — Read First

### ⚠️ Delete Codespace

```bash
# Via web browser:
# 1. Go to: https://github.com/codespaces
# 2. Find the Codespace
# 3. Click "..." (three dots)
# 4. Click "Delete"
```

**Purpose:** Permanently delete a Codespace.

**What It Does:**
- 🚨 **Permanently deletes the Codespace**
- All files NOT committed to git are lost
- Docker volumes are lost
- Docker images cached in the Codespace are lost
- Cannot be undone

**When to Use:**
- ❌ **Almost NEVER** — there are safer alternatives
- When you're absolutely done with the Codespace
- When you've committed ALL your work to git
- When you need to free up storage

**When NOT to Use:**
- For routine cleanup → just Stop the Codespace
- When you have uncommitted work → commit first
- When you might need the Codespace later

**Precautions:**
- 🚨 **DATA LOSS** — anything not in git is gone
- 🚨 **NO UNDO** — once deleted, it's gone forever
- Always commit and push before deleting
- Docker volumes (your n8n data) will be lost unless backed up

**Real Example from Our Session:**
- ❌ We did NOT delete the Codespace
- We only Stopped it (which preserves everything)
- Documented as a WARNING

**Related Actions:**
- Stop Codespace (safe — preserves everything)
- Rebuild Container (safe — preserves files)

---

### ⚠️ 30-Day Auto-Deletion

```bash
# This happens automatically — no command
# GitHub auto-deletes Codespaces inactive for 30 days
# (90 days for Pro accounts)
```

**Purpose:** GitHub's automatic cleanup of inactive Codespaces.

**What It Does:**
- Deletes Codespaces that haven't been used for 30 days
- Sends email notifications before deletion
- Cannot be disabled (only the retention period can change with paid plans)

**When to Use:**
- This is automatic — you don't trigger it

**When NOT to Use:**
- N/A — automatic

**Precautions:**
- ⚠️ **Will delete your Codespace if inactive for 30 days**
- Always commit work to git (git is forever; Codespaces are not)
- Check your email for deletion notices
- Open the Codespace periodically to reset the timer

**Real Example from Our Session:**
We ensured all work was committed to git so that even if the Codespace was auto-deleted, the files were safe on GitHub.

---

## Quick Reference Table

| Command / Action | Purpose | Safe? |
|---|---|---|
| Stop Codespace (UI) | Stop to save hours | ✅ Yes (preserves everything) |
| Open Codespace (web) | Restart stopped Codespace | ✅ Yes |
| Codespace auto-sleep | Automatic after idle | ✅ Yes (automatic) |
| `gh codespace ports list` | List forwarded ports | ✅ Yes |
| `gh codespace ports forward` | Forward a port | ✅ Yes |
| `gh codespace list` | List all Codespaces | ✅ Yes |
| Forward Port (UI) | Make port accessible | ✅ Yes |
| Set Port Visibility to Public | Allow browser access | ⚠️ Public = anyone with URL |
| Unforward Port | Remove port forwarding | ✅ Yes (service keeps running) |
| Copy Port URL | Get the public URL | ✅ Yes |
| `echo $CODESPACE_NAME` | Get Codespace name | ✅ Yes |
| `echo $GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN` | Get domain | ✅ Yes |
| Set Idle Timeout (web) | Configure auto-sleep | ✅ Yes |
| Rebuild Container (UI) | Apply devcontainer changes | ✅ Yes (preserves files) |
| Rebuild Without Cache | Fresh rebuild | ✅ Yes (slower) |
| Check Free Hours (web) | Monitor usage | ✅ Yes |
| Delete Codespace | Permanently remove | 🚨 DANGEROUS |

---

## Common Patterns

### The "End of Day" Pattern
```bash
# 1. Commit your work
git add .
git commit -m "Save work before sleeping"
git push

# 2. Stop Docker containers
docker compose down

# 3. Stop the Codespace
# Ctrl+Shift+P → "Codespaces: Stop Codespace"
```

### The "Start of Day" Pattern
```bash
# 1. Open the Codespace from https://github.com/codespaces

# 2. Start Docker containers
docker compose up -d

# 3. Wait for startup
sleep 30

# 4. Verify
docker ps
docker logs n8n --tail 10

# 5. Open n8n from the Ports tab
```

### The "Reset Stuck Port" Pattern
```bash
# 1. In Ports tab, right-click port 5678 → Unforward Port
# 2. Click "Forward a Port" → type 5678
# 3. Right-click → Port Visibility → Public
# 4. Copy URL and open in browser
```

### The "Apply devcontainer.json Changes" Pattern
```bash
# 1. Edit .devcontainer/devcontainer.json
# 2. Ctrl+Shift+P → "Codespaces: Rebuild Container"
# 3. Wait 3-4 minutes
# 4. Verify: docker version
# 5. Restart services: docker compose up -d
```

### The "Check Everything" Pattern
```bash
# 1. Check Codespace name
echo $CODESPACE_NAME

# 2. Check Docker
docker version

# 3. Check containers
docker ps

# 4. Check port forwarding
ss -ltnp | grep :5678

# 5. Check HTTP response
curl -I http://localhost:5678

# 6. Check logs
docker logs n8n --tail 15
```

---

## Codespace Lifecycle Facts

### Important Numbers

| Fact | Value |
|---|---|
| Default idle timeout | 30 minutes |
| Minimum idle timeout | 5 minutes |
| Maximum idle timeout | 240 minutes (4 hours) |
| Free tier hours | 60 hours/month |
| Pro tier hours | 180 hours/month |
| Auto-deletion (free) | 30 days inactive |
| Auto-deletion (Pro) | 90 days inactive |
| Codespace startup time | 30-60 seconds |
| Rebuild Container time | 3-4 minutes |

### What's Preserved When Stopped

| Item | Preserved? |
|---|---|
| Git history | ✅ Yes |
| Files in repo | ✅ Yes |
| Docker volumes (n8n data) | ✅ Yes |
| Docker images | ✅ Yes (cached) |
| Running containers | ❌ No (must restart with `docker compose up -d`) |
| Environment variables | ✅ Yes |

### What's Lost When Deleted

| Item | Lost? |
|---|---|
| Git history | ❌ No (it's on GitHub) |
| Files committed to git | ❌ No (they're on GitHub) |
| Uncommitted files | ✅ Yes |
| Docker volumes | ✅ Yes (unless backed up) |
| Docker images cache | ✅ Yes |
| Environment variables | ✅ Yes |

### Key Rules to Remember

1. **Always commit before stopping** — git is your safety net
2. **Docker containers don't auto-start** — run `docker compose up -d` after waking
3. **Codespaces can't run 24/7** — max 4 hours idle, then sleeps
4. **For 24/7, use a VPS** — deploy the same docker-compose.yml
5. **Public ports are accessible to anyone** — be cautious
6. **30-day inactivity = deletion** — open the Codespace periodically
7. **Stop (not Delete) to save hours** — Stop preserves everything

---

*Last updated: July 2026*
