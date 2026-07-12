# ⚠️ Don't Do This — Dangerous Commands & Pitfalls

**Purpose:** A dedicated guide to dangerous commands, common pitfalls, and false solutions. **Read this before running any command you're unsure about.**

**How to use:** Before running any command — especially one from an AI or online guide — check if it's listed here. If it is, understand the risk before proceeding.

---

## Table of Contents

1. [🚨 CRITICAL — Data Loss Risk](#-critical--data-loss-risk)
2. [⚠️ WARNINGS — Will Break Your Setup](#-warnings--will-break-your-setup)
3. [💡 COMMON MISTAKES — Wastes Time But Not Fatal](#-common-mistakes--wastes-time-but-not-fatal)
4. [❌ FALSE SOLUTIONS — Don't Believe These Myths](#-false-solutions--dont-believe-these-myths)
5. [🤖 AI-Generated Misinformation](#-ai-generated-misinformation)
6. [Quick Reference Table](#quick-reference-table)

---

## 🚨 CRITICAL — Data Loss Risk

Commands in this section can **permanently destroy your data**. Never run these unless you intentionally want to wipe everything.

---

### 🚨 docker compose down -v

```bash
docker compose down -v    # ⚠️ NEVER RUN THIS
```

**Why It's Dangerous:**
- The `-v` flag tells Docker to **DELETE ALL VOLUMES**
- Volumes contain your n8n workflows, credentials, settings, owner account
- **ALL YOUR DATA IS PERMANENTLY DESTROYED**
- There is NO undo

**What to Do Instead:**
```bash
docker compose down       # Safe — preserves volumes
```

**If You Ran It By Accident:**
- Your data is gone. Restore from backup or start fresh.
- Going forward, NEVER type `-v` after `down`

**How It Was Misused in Our Session:**
- ❌ The Chrome AI guide and Copilot both suggested this command
- Copilot itself later admitted it was "too destructive"
- We specifically avoided it throughout our session

**The Rule:**
> `docker compose down` = safe (preserves data)
> `docker compose down -v` = DESTRUCTIVE (deletes data)
>
> The `-v` makes ALL the difference. Never add it unless you want to wipe everything.

---

### 🚨 docker system prune -a --volumes

```bash
docker system prune -a --volumes    # ⚠️ NEVER RUN THIS
```

**Why It's Dangerous:**
- Removes ALL stopped containers
- Removes ALL unused networks
- Removes ALL unused images (forces re-download)
- Removes ALL unused volumes (including your n8n data if containers are stopped)
- **Essentially factory-resets Docker**

**What to Do Instead:**
For routine cleanup, use safer alternatives:
```bash
docker container prune       # Only stopped containers
docker image prune           # Only unused images
docker volume prune          # Only unused volumes (still risky)
```

**If You Ran It By Accident:**
- Your n8n data is likely gone
- Docker images need to be re-downloaded (slow)
- Rebuild with `docker compose up -d --build`

**How It Was Misused in Our Session:**
- ❌ Copilot ran this during the debugging session
- Copilot later said: "too destructive for this stage"
- It destroyed data unnecessarily

**The Rule:**
> Never use `docker system prune -a --volumes` for routine cleanup.
> It's the nuclear option. Use targeted `prune` commands instead.

---

### 🚨 rm -rf n8n_data

```bash
rm -rf n8n_data    # ⚠️ NEVER RUN THIS
```

**Why It's Dangerous:**
- Force-removes the n8n data directory
- Deletes all workflows, credentials, settings
- No confirmation prompt
- No undo

**What to Do Instead:**
- For routine shutdown: `docker compose down` (preserves data)
- For backups:
  ```bash
  docker run --rm -v n8n_data:/data -v $(pwd):/backup alpine \
    tar czf /backup/n8n-backup.tar.gz /data
  ```

**If You Ran It By Accident:**
- Your n8n data is gone
- Restore from backup or start fresh with `docker compose up -d`

**How It Was Misused in Our Session:**
- ❌ Copilot ran `rm -rf n8n_data` followed by `mkdir n8n_data`
- Copilot later admitted it was "risky"
- This was unnecessary and destroyed data

**The Rule:**
> Never `rm -rf` your data directory. If you need a fresh start, use `docker compose down` (without `-v`) and let Docker recreate the volume cleanly.

---

### 🚨 rm -rf (general warning)

```bash
rm -rf /              # ⚠️ DELETES EVERYTHING
rm -rf ~              # ⚠️ DELETES HOME DIRECTORY
rm -rf *              # ⚠️ DELETES EVERYTHING IN CURRENT DIRECTORY
```

**Why It's Dangerous:**
- `-r` = recursive (into directories)
- `-f` = force (no confirmation)
- Combined, they delete everything without asking
- No undo, no trash can, no recovery

**What to Do Instead:**
- Be specific: `rm filename.txt`
- Use `rm -i` for interactive (asks before each deletion)
- For directories: `rmdir` (only works on empty directories)

**The Rule:**
> Never use `rm -rf` unless you're absolutely certain of the path.
> Double-check the path before pressing Enter.
> A typo like `rm -rf /` can destroy an entire system.

---

## ⚠️ WARNINGS — Will Break Your Setup

Commands in this section won't destroy data, but they **will cause errors or break your configuration**.

---

### ⚠️ Using `apk add` in the n8n Dockerfile

```dockerfile
# ⚠️ WON'T WORK
RUN apk add --no-cache python3 py3-pip
```

**Why It Breaks:**
The modern n8n image is "Docker Hardened Alpine" — the `apk` package manager has been removed for security. You'll get:
```
/bin/sh: apk: not found
```

**What to Do Instead:**
Use a multi-stage build with `python:3.12-alpine`:
```dockerfile
FROM python:3.12-alpine AS python-builder
# ... install packages ...
FROM n8nio/n8n:latest
COPY --from=python:3.12-alpine /usr/local/bin/python3 /usr/local/bin/python3
# ... etc ...
```

**Related:** [`07-CONFIGURATION-FILES.md`](./07-CONFIGURATION-FILES.md) → Dockerfile section

---

### ⚠️ Using `apt-get install` in the n8n Dockerfile

```dockerfile
# ⚠️ WON'T WORK
RUN apt-get update && apt-get install -y python3
```

**Why It Breaks:**
The n8n image is Alpine-based, not Debian/Ubuntu. `apt-get` doesn't exist:
```
/bin/sh: apt-get: not found
```

**What to Do Instead:**
Same as above — use the multi-stage build with `python:3.12-alpine`.

---

### ⚠️ Using N8N_TRUSTED_ORIGINS environment variable

```yaml
# ⚠️ THIS VARIABLE DOESN'T EXIST
- N8N_TRUSTED_ORIGINS="*"
```

**Why It's a Problem:**
- `N8N_TRUSTED_ORIGINS` **does not exist** in n8n
- It's likely confused with `N8N_ALLOWED_ORIGINS` (which does exist but doesn't bypass the WebSocket origin check)
- n8n silently ignores unknown environment variables
- You'll think you've fixed the issue, but you haven't

**What to Do Instead:**
- For general origin allowance: `N8N_ALLOWED_ORIGINS=*` (real variable, but doesn't fix the Codespaces bug)
- For Codespaces specifically: Use the Nginx reverse proxy solution (see [`07-CONFIGURATION-FILES.md`](./07-CONFIGURATION-FILES.md))

**How This Myth Spread:**
- Suggested by Google Chrome's AI
- Suggested by GitHub Copilot (6+ times)
- Found in multiple online guides
- All of them wrong

---

### ⚠️ Setting N8N_HOST to your public URL

```yaml
# ⚠️ WRONG
- N8N_HOST=curly-succotash-gx4g7x9pq47pcw6pq-5678.app.github.dev
```

**Why It Breaks:**
- `N8N_HOST` is for **what interface to bind to**, not the public URL
- Setting it to a domain name makes n8n try to bind to an IP that doesn't exist on the container
- n8n won't start

**What to Do Instead:**
```yaml
- N8N_HOST=0.0.0.0                    # Bind to all interfaces
- N8N_EDITOR_BASE_URL=https://...     # This is where the URL goes
- WEBHOOK_URL=https://...             # And here
```

---

### ⚠️ Using `version: '3.8'` in docker-compose.yml

```yaml
# ⚠️ OBSOLETE
version: '3.8'

services:
  ...
```

**Why It's a Problem:**
- The `version` field is **obsolete** in modern Docker Compose
- You'll get a warning every time you run `docker compose`:
  ```
  WARN[0000]: the attribute `version` is obsolete, it will be ignored
  ```
- It serves no purpose

**What to Do Instead:**
Just remove the `version` line entirely:
```yaml
services:
  ...
```

---

### ⚠️ Accessing n8n via `localhost:5678` in the browser

```bash
# ⚠️ DON'T DO THIS IN THE BROWSER
http://localhost:5678
```

**Why It's a Problem:**
- Accessing n8n via `localhost:5678` triggers the Origin header mismatch
- n8n expects the Origin to be the Codespace URL
- Browser sends `Origin: http://localhost:5678`
- n8n rejects the WebSocket → "Connection Lost"

**What to Do Instead:**
Always use the Codespace URL from the Ports tab:
```
https://curly-succotash-gx4g7x9pq47pcw6pq-5678.app.github.dev
```

**Note:**
- `curl http://localhost:5678` (in the terminal) works fine — it doesn't use WebSockets
- The issue is only with browsers accessing localhost

---

### ⚠️ Using `N8N_PUSH_BACKEND=sse` to fix Connection Lost

```yaml
# ⚠️ DOESN'T FIX THE ISSUE
- N8N_PUSH_BACKEND=sse
```

**Why It Doesn't Work:**
- Switching from WebSocket to SSE doesn't fix the Origin header mismatch
- n8n still checks the Origin header
- "Connection Lost" persists

**What to Do Instead:**
- Use `N8N_PUSH_BACKEND=websocket` (the default)
- Apply the Nginx reverse proxy solution (the actual fix)

**How We Know:**
- We tested `sse` — "Connection Lost" persisted
- The n8n community tried it — same result
- GitHub Issue #21755 confirms it doesn't work

---

## 💡 COMMON MISTAKES — Wastes Time But Not Fatal

These won't break anything, but they'll waste your time and cause confusion.

---

### 💡 Forgetting to `git add` before `git commit`

```bash
# ⚠️ MISTAKE
git commit -m "Add new file"
# Error: nothing added to commit but untracked files present
```

**The Fix:**
```bash
git add <file>
git commit -m "Add new file"
```

**The Rule:**
> Git has a two-step process: `add` (stage) then `commit` (save). Always `add` first.

---

### 💡 Running `docker compose` from the wrong directory

```bash
# ⚠️ MISTAKE
cd /tmp
docker compose up -d
# Error: no configuration file provided: not found
```

**The Fix:**
```bash
cd /workspaces/ai-cold-email-outreach
docker compose up -d
```

**The Rule:**
> Always run `docker compose` from the directory containing `docker-compose.yml`.

---

### 💡 Pasting shell commands into files

```dockerfile
# ⚠️ MISTAKE — This was pasted into a Dockerfile
cat > Dockerfile <<'EOF'
FROM n8nio/n8n:latest
...
EOF
```

**Why It's a Mistake:**
- `cat >`, `<<'EOF'`, and `EOF` are shell commands, not file content
- The file should only contain the content between `EOF` markers

**The Fix:**
Open the file in VS Code and paste only the actual content (starting with `FROM`, ending with `USER node`).

**The Rule:**
> When using `cat > file <<'EOF'`, the `cat`/`EOF` lines are shell syntax — don't paste them into the file itself.

---

### 💡 Not setting port visibility to Public

**The Mistake:**
Starting n8n, getting the URL, but forgetting to set port visibility to Public.

**The Result:**
- Browser shows "Refused to Connect"
- You think n8n is broken
- Actually, the port is just Private

**The Fix:**
In VS Code → Ports tab → right-click port 5678 → Port Visibility → Public

**The Rule:**
> Always set port visibility to Public for browser access. Auto-forwarded ports default to Private.

---

### 💡 Confusing `docker compose down` and `docker compose stop`

| Command | What it does |
|---|---|
| `docker compose stop` | Pauses containers (they still exist) |
| `docker compose down` | Stops AND removes containers |

**The Mistake:**
Using `stop` when you meant to reset, or using `down` when you just wanted to pause.

**The Rule:**
> `stop` = pause, `down` = stop + remove. For routine shutdown, use `down` (cleaner). For quick pauses, use `stop`.

---

### 💡 Hard refreshing without clearing cache

**The Mistake:**
Pressing Ctrl+R (regular refresh) when you need Ctrl+Shift+R (hard refresh).

**The Result:**
- Browser uses cached version of n8n
- Old errors persist even after fixing them

**The Fix:**
- Hard refresh: **Ctrl+Shift+R** (Windows/Linux) or **Cmd+Shift+R** (Mac)
- Or: Open incognito window
- Or: F12 → right-click refresh button → "Empty Cache and Hard Reload"

---

## ❌ FALSE SOLUTIONS — Don't Believe These Myths

These are solutions that look correct but **do not work**. They're often suggested by AI tools and online guides.

---

### ❌ MYTH: "N8N_TRUSTED_ORIGINS bypasses origin checks"

**The Claim:**
> "Set `N8N_TRUSTED_ORIGINS='*'` to disable strict origin checking and solve CORS issues."

**The Truth:**
- `N8N_TRUSTED_ORIGINS` **does not exist** in n8n
- n8n silently ignores unknown environment variables
- This is a placebo — it does nothing

**Evidence:**
1. We tested it on Day 2 — no effect
2. GitHub Copilot tested it 6+ times — no effect
3. The n8n community thread — no resolution
4. GitHub Issue #21755 — same failure

**What Actually Works:**
The Nginx reverse proxy with `proxy_set_header Origin` rewriting.

**Where This Myth Comes From:**
Likely confused with `N8N_ALLOWED_ORIGINS` (which exists but doesn't bypass the check).

---

### ❌ MYTH: "WEBHOOK_URL bypasses origin checks"

**The Claim:**
> "Set `WEBHOOK_URL=https://your-codespace-url` to bypass the strict origin check caused by GitHub's proxying layer."

**The Truth:**
- `WEBHOOK_URL` only tells n8n what URL to use for **outgoing webhook calls**
- It has **nothing to do with** the incoming WebSocket connection from the browser
- It does NOT bypass origin checks

**Evidence:**
1. We tested it — "Connection Lost" persisted
2. Copilot tested it — same result
3. The Chrome AI guide made this false claim
4. GitHub Issue #21755 confirms it doesn't work

**What Actually Works:**
The Nginx reverse proxy solution.

---

### ❌ MYTH: "N8N_PUSH_BACKEND=sse fixes Connection Lost"

**The Claim:**
> "Switch from WebSocket to SSE to avoid the origin check issue."

**The Truth:**
- SSE still goes through the same origin check
- Switching to SSE doesn't fix the Origin header mismatch
- "Connection Lost" persists

**Evidence:**
1. We tested it — no effect
2. The n8n community tried it — no effect
3. GitHub Issue #21755 confirms it doesn't work

**What Actually Works:**
Use `N8N_PUSH_BACKEND=websocket` (the default) and apply the Nginx fix.

---

### ❌ MYTH: "N8N_PROXY_HOPS fixes the origin issue"

**The Claim:**
> "Set `N8N_PROXY_HOPS=1` to fix origin issues behind proxies."

**The Truth:**
- `N8N_PROXY_HOPS` is a real variable
- It handles `X-Forwarded-For` headers behind proxies
- It removes warnings like `ERR_ERL_UNEXPECTED_X_FORWARDED_FOR`
- **It does NOT fix the Origin header mismatch**

**Evidence:**
From GitHub Issue #21755:
> "On newer versions, N8N_PROXY_HOPS removed the ERR_ERL_UNEXPECTED_X_FORWARDED_FOR noise, but did not resolve the Invalid origin on push."

**What Actually Works:**
The Nginx reverse proxy solution.

---

### ❌ MYTH: "N8N_DISABLE_ORIGIN_CHECK=true disables the check"

**The Claim:**
> "Set `N8N_DISABLE_ORIGIN_CHECK=true` to disable origin validation."

**The Truth:**
- This variable does NOT disable the WebSocket origin check
- Mentioned in an Azure Container Apps thread as having "no effect"
- n8n's origin check is a security feature that can't be disabled with an env var

**What Actually Works:**
The Nginx reverse proxy solution — rewrite the Origin header before it reaches n8n.

---

### ❌ MYTH: "Just access n8n via localhost"

**The Claim:**
> "Access n8n at http://localhost:5678 — no need for the Codespace URL."

**The Truth:**
- Accessing via `localhost:5678` triggers the Origin mismatch
- Browser sends `Origin: http://localhost:5678`
- n8n expects `Origin: https://<codespace-url>`
- Result: "Connection Lost"

**What Actually Works:**
Always use the Codespace URL from the Ports tab.

---

## 🤖 AI-Generated Misinformation

AI tools (Google Chrome AI, GitHub Copilot, others) gave us incorrect information during this project. Here's what they got wrong.

---

### Chrome AI Guide — FALSE Claims

**Claim 1:** "WEBHOOK_URL bypasses the strict origin check"
- **Truth:** WEBHOOK_URL only affects outgoing webhooks, not incoming WebSocket origin checks

**Claim 2:** Used `docker-in-docker:2` instead of `:4.0.0`
- **Truth:** Version 2 may work, but `:4.0.0` with `moby: false` is the proven working setup

**Claim 3:** Used `version: '3.8'` in docker-compose.yml
- **Truth:** Obsolete — causes warnings, serves no purpose

**Claim 4:** "Set N8N_HOST to your public URL"
- **Truth:** N8N_HOST is for binding interface (use `0.0.0.0`), not for the URL

---

### GitHub Copilot — Issues

**Issue 1:** Suggested `N8N_TRUSTED_ORIGINS="*"` 6+ times
- **Truth:** This variable doesn't exist

**Issue 2:** Ran `docker system prune -a --volumes`
- **Truth:** Too destructive, destroyed data unnecessarily
- Copilot itself later admitted: "too destructive for this stage"

**Issue 3:** Ran `rm -rf n8n_data`
- **Truth:** Risky, destroyed data
- Copilot itself later admitted: "risky"

**Issue 4:** Couldn't solve the Origin header issue
- **Truth:** Copilot tried 9 steps, all failed to fix the actual problem
- The session ended without a working solution

---

### How to Spot AI-Generated Misinformation

1. **No link to official documentation** — if it doesn't cite docs.n8n.io, be suspicious
2. **Claims "success" without log evidence** — real solutions show clean logs
3. **Uses `N8N_TRUSTED_ORIGINS`** — this variable doesn't exist
4. **Doesn't mention the Codespace proxy behavior** — the real cause
5. **Suggests destructive commands** — `down -v`, `system prune`, `rm -rf`
6. **Looks too simple** — if it were that simple, the community would have solved it

---

## Quick Reference Table

### 🚨 CRITICAL (Data Loss)

| Command | Why It's Dangerous | Safe Alternative |
|---|---|---|
| `docker compose down -v` | Deletes all volumes | `docker compose down` |
| `docker system prune -a --volumes` | Factory-resets Docker | `docker container prune` |
| `rm -rf n8n_data` | Deletes n8n data directory | `docker compose down` |
| `rm -rf /` | Deletes entire system | Don't use `rm -rf` carelessly |

### ⚠️ WARNINGS (Breaks Setup)

| Command/Setting | Why It Breaks | Fix |
|---|---|---|
| `apk add` in Dockerfile | No package manager in n8n image | Multi-stage build |
| `apt-get install` in Dockerfile | Alpine, not Debian | Multi-stage build |
| `N8N_TRUSTED_ORIGINS` | Variable doesn't exist | `N8N_ALLOWED_ORIGINS` + Nginx fix |
| `N8N_HOST=<url>` | Wrong setting (should be `0.0.0.0`) | `N8N_HOST=0.0.0.0` |
| `version: '3.8'` | Obsolete | Remove the line |
| Accessing via `localhost` in browser | Origin mismatch | Use Codespace URL |
| `N8N_PUSH_BACKEND=sse` | Doesn't fix origin issue | Nginx fix |

### ❌ FALSE SOLUTIONS

| Myth | Truth |
|---|---|
| `N8N_TRUSTED_ORIGINS` bypasses origin checks | Variable doesn't exist |
| `WEBHOOK_URL` bypasses origin checks | Only affects outgoing webhooks |
| `N8N_PUSH_BACKEND=sse` fixes Connection Lost | Doesn't fix origin issue |
| `N8N_PROXY_HOPS` fixes origin issue | Only handles X-Forwarded-For |
| `N8N_DISABLE_ORIGIN_CHECK` works | No effect on WebSocket check |
| Access via `localhost` works | Triggers origin mismatch |

### 💡 COMMON MISTAKES

| Mistake | Fix |
|---|---|
| Forgetting `git add` before `commit` | Always `git add` first |
| Running `docker compose` in wrong directory | `cd` to repo root first |
| Pasting shell commands into files | Only paste actual file content |
| Not setting port to Public | Ports tab → Port Visibility → Public |
| Confusing `down` and `stop` | `stop` = pause, `down` = stop + remove |
| Regular refresh instead of hard refresh | Use Ctrl+Shift+R |

---

## The Golden Rules

1. **Never use `-v` with `docker compose down`** unless you want to delete all data
2. **Never use `rm -rf` on data directories** — back up first
3. **Never trust AI-generated solutions blindly** — verify with official docs
4. **Always check `docker logs` first** when debugging
5. **Always use the Codespace URL**, not `localhost`, in the browser
6. **Always `git add` before `git commit`**
7. **Always run `docker compose` from the repo root**
8. **When in doubt, don't run the command** — research first
9. **Back up your data regularly** — before any major change
10. **If 10+ env vars don't fix it, the problem is at a different layer** (proxy, not app)

---

## If You've Already Run a Dangerous Command

### If you ran `docker compose down -v`:
- Your n8n data is gone
- Rebuild: `docker compose up -d`
- Recreate your owner account
- Recreate your workflows (from exports if you have them)

### If you ran `docker system prune -a --volumes`:
- Your n8n data is likely gone
- Docker images need re-downloading
- Rebuild: `docker compose up -d --build`

### If you ran `rm -rf n8n_data`:
- Your n8n data is gone
- Rebuild: `docker compose down && docker compose up -d`
- Recreate your owner account

### If you ran `git push --force`:
- Remote commits may be lost
- Check GitHub for the state of the branch
- If others were working on it, coordinate with them

---

*Last updated: July 2026*
*Read this file BEFORE running any command you're unsure about.*
