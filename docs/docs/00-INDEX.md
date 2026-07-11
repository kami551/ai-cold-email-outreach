# n8n + GitHub Codespaces — Knowledge Base Index

**Project:** `ai-cold-email-outreach`
**Codespace:** `curly-succotash-gx4g7x9pq47pcw6pq`
**Branch:** `feat-workflow-final-polish`
**Created:** July 2026
**Status:** ✅ Working — n8n fully operational in GitHub Codespaces

---

## What This Knowledge Base Is

This is a complete, honest record of a **4-day debugging journey** to run n8n (workflow automation) inside a GitHub Codespace using Docker-in-Docker.

The journey ended with a **working solution that is not documented anywhere else on the internet** — an Nginx reverse proxy that rewrites the `Origin` header to bypass a known n8n security check that breaks in Codespaces' proxy environment.

This knowledge base exists so that:
1. **Future you** can reproduce or repair the setup in minutes, not days
2. **Other developers** hitting the same wall can find a real solution
3. **The lessons learned** are preserved, not just the commands

---

## Why This Exists (The Short Story)

n8n's editor uses a WebSocket connection to talk to its backend. When n8n runs inside a GitHub Codespace, the Codespace port-forwarding proxy **rewrites the `Origin` header** of incoming WebSocket requests to `localhost:5678`. But n8n expects the Origin to match its configured public URL (`https://<codespace-name>-5678.app.github.dev`). When they don't match, n8n rejects the WebSocket → the browser shows **"Connection Lost"**.

This is a **known, unresolved issue** in the n8n community (the main community thread was closed in November 2025 without a solution). Multiple AI assistants (including GitHub Copilot and Google's AI) failed to solve it with environment variables alone.

**The fix:** Put an Nginx reverse proxy in front of n8n that explicitly sets the correct `Origin` header before forwarding the request. This works where every environment-variable approach fails.

Full story: [`01-ERROR-RECOVERY-STORY.md`](./01-ERROR-RECOVERY-STORY.md)

---

## How to Use This Knowledge Base

### If you just want n8n running again

1. Open your Codespace
2. Run: `docker compose up -d`
3. Wait 30 seconds
4. Open the URL from the **Ports** tab (port `5678`, set to **Public**)

If that doesn't work, go to [`07-TROUBLESHOOTING-BY-SYMPTOM.md`](./07-TROUBLESHOOTING-BY-SYMPTOM.md) and find your symptom.

### If you want to understand WHY it works

Read [`01-ERROR-RECOVERY-STORY.md`](./01-ERROR-RECOVERY-STORY.md) — the complete narrative.

### If you want to look up a specific command

Go directly to the relevant command reference file (see the File Index below).

### If you're about to do something risky

**Read [`08-DONT-DO-THIS.md`](./08-DONT-DO-THIS.md) first.** It lists every dangerous command and common pitfall we encountered.

### If you're new to command-line syntax

Read [`09-COMMAND-SYNTAX-GUIDE.md`](./09-COMMAND-SYNTAX-GUIDE.md) — it explains `-` vs `--`, flags, options, and how to read any command.

---

## File Index

### 📖 The Story

#### [01 — Error Recovery Story](./01-ERROR-RECOVERY-STORY.md)
The complete 4-day narrative: from "Codespace won't create" to "n8n fully working with workflows saved." Includes every phase, what we tried, what failed, and what finally worked. This is the most valuable file in the knowledge base.

---

### 📚 Command References

#### [02 — Docker Commands](./02-COMMANDS-DOCKER.md)
Every Docker and Docker Compose command we used, with purpose, what it does, when to use it, when NOT to use it, and precautions. Covers `docker ps`, `docker logs`, `docker compose up/down`, `docker inspect`, `docker exec`, and more.

#### [03 — Git Commands](./03-COMMANDS-GIT.md)
Git commands used throughout the project: `status`, `add`, `commit`, `push`, `branch`, `log`, and how to set upstream for a new branch.

#### [04 — Networking Commands](./04-COMMANDS-NETWORKING.md)
Network diagnostic commands: `curl -I`, `curl -i`, `ss -ltnp`, `lsof`, `fuser`, and how to use them to isolate where a connection is failing.

#### [05 — Codespaces Commands & Actions](./05-COMMANDS-CODESPACES.md)
Both CLI (`gh codespace ports`) and UI actions (Ports tab, Port Visibility, Rebuild Container) for managing GitHub Codespaces. Includes the Codespace lifecycle and how to save your free hours.

---

### ⚙️ Configuration

#### [06 — Configuration Files Explained](./06-CONFIGURATION-FILES.md)
Line-by-line explanations of the four files that make up the working setup:
- `.devcontainer/devcontainer.json`
- `Dockerfile` (multi-stage build with Python)
- `docker-compose.yml` (n8n + Nginx services)
- `nginx.conf` (the Origin header fix)

This is the file to read if you want to understand WHAT each config does, not just HOW to run it.

---

### 🔧 Troubleshooting

#### [07 — Troubleshooting by Symptom](./07-TROUBLESHOOTING-BY-SYMPTOM.md)
A lookup table organized by **what you see** (the symptom), not by cause. Each entry has: Symptom → Root Cause → Fix → Verification command. Covers "Connection Lost", "502 Bad Gateway", "Refused to Connect", "apk not found", and more.

#### [08 — Don't Do This](./08-DONT-DO-THIS.md)
⚠️ **Read this before running any command you're unsure about.** Lists dangerous commands (`docker compose down -v`, `docker system prune --volumes`, `rm -rf`), common pitfalls, and false solutions that look correct but don't work (like `N8N_TRUSTED_ORIGINS`).

---

### 📖 Learning & Reference

#### [09 — Command Syntax Guide](./09-COMMAND-SYNTAX-GUIDE.md)
Explains how to READ command-line syntax: single dash (`-d`) vs double dash (`--detach`), boolean flags vs value-taking options, combined flags (`-fv`), the `&&` operator, pipes (`|`), and redirects (`2>&1`, `2>/dev/null`). After reading this, you can decode any command you've never seen before.

#### [10 — Decisions and Lessons](./10-DECISIONS-AND-LESSONS.md)
The "why" behind every choice we made: why `docker-in-docker:4.0.0` and not `:2`, why `moby: false`, why multi-stage Dockerfile, why Nginx instead of env vars, why SQLite instead of Postgres for development. Captures reasoning so you don't re-investigate solved problems.

---

## Quick Navigation by Task

| If you want to... | Go to file |
|---|---|
| Start n8n after waking the Codespace | [`02`](./02-COMMANDS-DOCKER.md) → `docker compose up -d` |
| Stop n8n safely (keep your data) | [`02`](./02-COMMANDS-DOCKER.md) → `docker compose down` |
| Check if n8n is running | [`02`](./02-COMMANDS-DOCKER.md) → `docker ps` |
| View n8n logs | [`02`](./02-COMMANDS-DOCKER.md) → `docker logs n8n --tail 20` |
| Fix "Connection Lost" | [`07`](./07-TROUBLESHOOTING-BY-SYMPTOM.md) → Symptom: Connection Lost |
| Fix "502 Bad Gateway" | [`07`](./07-TROUBLESHOOTING-BY-SYMPTOM.md) → Symptom: 502 Bad Gateway |
| Fix "Refused to Connect" | [`07`](./07-TROUBLESHOOTING-BY-SYMPTOM.md) → Symptom: Refused to Connect |
| Commit your files to git | [`03`](./03-COMMANDS-GIT.md) |
| Make the port public | [`05`](./05-COMMANDS-CODESPACES.md) |
| Understand the docker-compose.yml | [`06`](./06-CONFIGURATION-FILES.md) |
| Know what NOT to run | [`08`](./08-DONT-DO-THIS.md) |
| Understand `-` vs `--` | [`09`](./09-COMMAND-SYNTAX-GUIDE.md) |
| Read the complete story | [`01`](./01-ERROR-RECOVERY-STORY.md) |

---

## The Working Setup at a Glance

```
Browser
  │
  ▼
GitHub Codespace Proxy (rewrites Origin header — this is the problem)
  │
  ▼
Nginx (port 5678 → 80)          ← This is the fix: rewrites Origin back
  │   proxy_set_header Origin https://<codespace>-5678.app.github.dev;
  ▼
n8n container (port 5678, internal only)
  │
  ▼
SQLite database (in n8n_data volume — persists across restarts)
```

**Files in the repo root:**
```
.devcontainer/
  └── devcontainer.json     ← Codespace config (Docker-in-Docker feature)
docker-compose.yml          ← Defines n8n + nginx services
Dockerfile                  ← Multi-stage build: adds Python to n8n image
nginx.conf                  ← The Origin header rewrite (the actual fix)
```

---

## Codespace Quick Facts

| Fact | Value |
|---|---|
| Codespace name | `curly-succotash-gx4g7x9pq47pcw6pq` |
| Public URL | `https://curly-succotash-gx4g7x9pq47pcw6pq-5678.app.github.dev` |
| n8n port | `5678` |
| Nginx port (host) | `5678` (forwards to n8n `5678`) |
| Database | SQLite (stored in Docker volume `n8n_data`) |
| Idle timeout (max) | 4 hours (240 minutes) — set at github.com/settings/codespaces |
| Free hours (Pro) | 180 core hours/month |
| Branch | `feat-workflow-final-polish` |

---

## A Note on Honesty

This knowledge base is **honest about failures**. Several files document commands and approaches that **did not work**. This is intentional:

- ❌ `N8N_TRUSTED_ORIGINS` — does not exist in n8n (documented in [`08`](./08-DONT-DO-THIS.md))
- ❌ `N8N_PUSH_BACKEND=sse` — does not fix the Origin issue (documented in [`01`](./01-ERROR-RECOVERY-STORY.md))
- ❌ `WEBHOOK_URL` alone — does not bypass origin checks (documented in [`08`](./08-DONT-DO-THIS.md))
- ❌ `docker system prune -a --volumes` — too destructive (documented in [`08`](./08-DONT-DO-THIS.md))

**If a command or approach didn't work, it's recorded here as a failure, with evidence.** This saves future you from re-trying dead ends.

---

## Attribution & Sources

This knowledge base was built from:

1. **4+ days of direct debugging** in the Codespace (primary source)
2. **A GitHub Copilot session** (2,666 lines) that independently attempted the same fix and failed — confirming the problem is non-trivial
3. **Web research** across the n8n community forum, GitHub issues, Medium, dev.to, and Reddit — confirming this was an unresolved issue
4. **AI-generated guides** (from Google Chrome and others) that contained false claims — used as cautionary examples

The **working solution** (Nginx reverse proxy with `proxy_set_header Origin` rewriting) was developed after all other approaches failed. While similar techniques exist for VPS deployments (Nginx) and CloudFront deployments (Origin header injection), no published solution was found for the specific Codespaces + Docker-in-Docker + n8n scenario as of July 2026.

---

## Maintenance

**Rule:** Every time you learn a new command or fix a new issue, add it to the relevant file **the same day**.

- New Docker command → [`02-COMMANDS-DOCKER.md`](./02-COMMANDS-DOCKER.md)
- New Git command → [`03-COMMANDS-GIT.md`](./03-COMMANDS-GIT.md)
- New error and fix → [`07-TROUBLESHOOTING-BY-SYMPTOM.md`](./07-TROUBLESHOOTING-BY-SYMPTOM.md)
- New mistake to avoid → [`08-DONT-DO-THIS.md`](./08-DONT-DO-THIS.md)
- New "why did we choose X" → [`10-DECISIONS-AND-LESSONS.md`](./10-DECISIONS-AND-LESSONS.md)

**Don't put it off.** The details fade fast. 30 seconds of documentation today saves hours of re-investigation next month.

---

*Last updated: July 2026*
