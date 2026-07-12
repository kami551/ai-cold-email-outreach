# Command Syntax Guide — How to Read the Command Line

**Purpose:** Teach you how to READ command-line syntax so you can decode any command you've never seen before. This isn't about memorizing commands — it's about understanding the patterns.

**How to use:** Read this once end-to-end. After that, refer back when you encounter unfamiliar syntax.

---

## Table of Contents

1. [The Anatomy of a Command](#the-anatomy-of-a-command)
2. [Single Dash vs Double Dash](#single-dash-vs-double-dash)
3. [Three Types of Options](#three-types-of-options)
4. [Combining Short Flags](#combining-short-flags)
5. [The Equals Sign (=) vs Space](#the-equals-sign--vs-space)
6. [Pipes (|)](#pipes-)
7. [Redirects (>, >>, 2>&1, 2>/dev/null)](#redirects--2_1-2devnull)
8. [The && and || Operators](#the--and--operators)
9. [Quotes (Single vs Double)](#quotes-single-vs-double)
10. [Environment Variables ($VAR)](#environment-variables-var)
11. [Special Characters Cheat Sheet](#special-characters-cheat-sheet)
12. [Decoding Practice](#decoding-practice)

---

## The Anatomy of a Command

Most commands follow this pattern:

```
command [subcommand] [options] [arguments]
```

### Example Breakdown

```bash
docker compose up -d --build
│       │        │  │  │
│       │        │  │  └─ long option (--build = rebuild images)
│       │        │  └─ short option (-d = detached mode)
│       │        └─ subcommand (what to do)
│       └─ command (the program)
└─ the command itself
```

### Another Example

```bash
git commit -m "Fix bug" --no-verify -a
│       │       │  │          │         │
│       │       │  │          │         └─ short boolean flag (-a = all)
│       │       │  │          └─ long boolean flag (--no-verify)
│       │       │  └─ short value option (-m takes "Fix bug" as its value)
│       │       └─ subcommand
│       └─ command
└─ command itself
```

### The Parts

| Part | Required? | Example |
|---|---|---|
| Command | ✅ Yes | `docker`, `git`, `curl` |
| Subcommand | Sometimes | `compose`, `commit`, `push` |
| Options (flags) | Optional | `-d`, `--build`, `--name=myapp` |
| Arguments | Optional | `n8n`, `https://example.com` |

---

## Single Dash vs Double Dash

This is the most confusing part for beginners. Here's the truth:

| Style | Format | Length | Example |
|---|---|---|---|
| **Single dash** | `-d`, `-f`, `-v` | Usually 1 letter | `docker compose up -d` |
| **Double dash** | `--detach`, `--force`, `--verbose` | Full word | `docker compose up --detach` |

### Key Insight

`-d` and `--detach` usually mean the **same thing** — they're just two ways to write the same option.

- Use `-d` for speed (when typing in terminal)
- Use `--detach` for clarity (in scripts)

### Why Do Both Exist?

**History.** In the 1970s-80s, terminal screens were tiny, so short flags (`-d`) were preferred. As commands got more options, single letters ran out, so long flags (`--detach`) were added.

### Examples from Our Session

| Short | Long | Meaning |
|---|---|---|
| `-d` | `--detach` | Run in background |
| `-f` | `--force` | Don't ask for confirmation |
| `-v` | `--volumes` | Include volumes |
| `-a` | `--all` | All items |
| `-p` | `--port` | Port mapping |

---

## Three Types of Options

Every option falls into one of three categories. Knowing which type helps you read commands correctly.

### Type 1: Boolean Flags (On/Off Switches)

- No value follows them
- Just their presence turns them on
- Examples: `-d`, `--force`, `-a`

```bash
docker compose up -d          # -d is boolean (detached mode ON)
git commit --amend            # --amend is boolean (modify last commit)
docker rm -f n8n              # -f is boolean (force ON)
```

**How to recognize:** No `=` and no value after the flag.

---

### Type 2: Options That Take a Value (Space-Separated)

- The next word is the value
- Examples: `-m "message"`, `-p 8080:80`, `-e KEY=value`

```bash
git commit -m "My message"     # -m takes "My message" as its value
docker run -p 8080:80 nginx    # -p takes "8080:80" as its value
docker run -e KEY=value nginx  # -e takes "KEY=value" as its value
```

**How to recognize:** A space, then a value (often quoted if it contains spaces).

---

### Type 3: Options with Attached Values (= Sign)

- Value is connected with `=` (no space)
- Examples: `--name=container`, `--build-arg=KEY=value`

```bash
docker run --name=myapp nginx              # --name takes "myapp"
docker build --build-arg=VERSION=1.0 .     # --build-arg takes "VERSION=1.0"
git log --format="%H"                      # --format takes "%H"
```

**How to recognize:** An `=` sign immediately after the option name.

---

## Combining Short Flags

Multiple short boolean flags can be combined into one:

```bash
# These are equivalent:
docker rm -f -v n8n
docker rm -fv n8n          # Combined: -f and -v together
```

### How It Works

- `-fv` means `-f` AND `-v`
- Order doesn't matter: `-vf` is the same as `-fv`
- Only works with **short** (single-dash) boolean flags

### Common Combinations

| Combined | Means |
|---|---|
| `-fv` | `-f` (force) + `-v` (volumes) |
| `-la` | `-l` (long format) + `-a` (all) |
| `-rf` | `-r` (recursive) + `-f` (force) |

### ⚠️ Warning: Don't Combine Value-Taking Flags

```bash
# ❌ WRONG — -p takes a value, can't combine
docker run -pd 8080:80 nginx    # Confusing — is -d part of -p's value?

# ✅ CORRECT — keep them separate
docker run -p 8080:80 -d nginx
```

**Rule:** Only combine boolean (on/off) flags. Never combine value-taking flags.

---

## The Equals Sign (=) vs Space

Some options accept both formats:

```bash
# These are equivalent:
docker run --name myapp nginx
docker run --name=myapp nginx

# These are equivalent:
git log --format "%H"
git log --format="%H"
```

### When to Use Each

| Style | Best for |
|---|---|
| Space (`--name myapp`) | Interactive terminal (easier to type) |
| Equals (`--name=myapp`) | Scripts (clearer, no ambiguity) |

### When Equals Is Required

Some commands require `=` for values with special characters:

```bash
# ✅ Works (value has = sign, need = syntax)
docker build --build-arg=VERSION=1.0 .

# ❌ Might not work
docker build --build-arg VERSION=1.0 .
```

---

## Pipes (|)

The pipe (`|`) takes the output of one command and feeds it as input to another.

```bash
command1 | command2
```

### Example

```bash
docker logs n8n | grep "error"
│              │      │
│              │      └─ Second command: search for "error"
│              └─ Pipe: feed output to next command
└─ First command: get n8n logs
```

**What happens:**
1. `docker logs n8n` outputs all logs
2. `|` sends that output to `grep`
3. `grep "error"` filters for lines containing "error"
4. You only see lines with "error"

### Common Pipe Examples from Our Session

```bash
# Filter logs for origin errors
docker logs n8n | grep -i "origin"

# Count running containers
docker ps | wc -l

# Filter container list
docker ps | grep n8n

# Pipe multiple commands
docker logs n8n | grep -i "error" | tail -10
```

### Chaining Pipes

You can chain multiple pipes:

```bash
command1 | command2 | command3 | command4
```

Each command processes the output of the previous one.

---

## Redirects (>, >>, 2>&1, 2>/dev/null)

Redirects change where output goes — to files instead of the screen, or to hide errors.

### Standard Output Redirect: `>`

```bash
command > file.txt
```

- Takes the output of `command`
- Writes it to `file.txt`
- **Overwrites** the file if it exists

```bash
docker logs n8n > logs.txt          # Save logs to file
docker ps > containers.txt          # Save container list
```

### Append Redirect: `>>`

```bash
command >> file.txt
```

- Same as `>`, but **appends** instead of overwrites

```bash
docker logs n8n >> all-logs.txt     # Add to existing file
```

### Standard Error Redirect: `2>`

```bash
command 2> errors.txt
```

- `2` represents stderr (error output)
- Only redirects errors, not normal output

```bash
docker logs n8n 2> errors.txt       # Save only errors
```

### Discard Errors: `2>/dev/null`

```bash
command 2>/dev/null
```

- `/dev/null` is a "black hole" — anything sent there disappears
- `2>/dev/null` discards all error messages
- Useful when you don't care about errors

```bash
docker rm -f n8n 2>/dev/null        # Remove container, ignore "not found" errors
```

### Combine stdout and stderr: `2>&1`

```bash
command 2>&1
```

- `2>&1` means "redirect stderr (2) to wherever stdout (1) goes"
- Combines normal output and errors into one stream

```bash
docker logs n8n 2>&1 | tail -200    # Get all logs (including errors), show last 200
```

### Full Example from Our Session

```bash
docker rm -f n8n 2>/dev/null || true
```

Breaking this down:
- `docker rm -f n8n` — force remove the container
- `2>/dev/null` — discard any errors (e.g., "container doesn't exist")
- `|| true` — if the command fails, run `true` (which always succeeds)

**Result:** Remove n8n if it exists, silently continue if it doesn't.

---

## The && and || Operators

These operators chain commands together based on success or failure.

### && (AND — Run if previous succeeded)

```bash
command1 && command2
```

- Runs `command2` only if `command1` succeeded
- If `command1` fails, `command2` doesn't run

```bash
docker stop n8n && docker rm n8n    # Remove only if stop succeeded
git add . && git commit -m "Update" # Commit only if add succeeded
```

### || (OR — Run if previous failed)

```bash
command1 || command2
```

- Runs `command2` only if `command1` failed
- If `command1` succeeds, `command2` doesn't run

```bash
docker rm -f n8n || true            # If rm fails, run `true` (no-op)
mkdir myfolder || echo "Already exists"
```

### Combining && and ||

```bash
command1 && command2 || command3
```

- If `command1` succeeds → run `command2`
- If `command1` fails → run `command3`

```bash
docker ps | grep n8n && echo "Running" || echo "Not running"
```

### Semicolon (;) — Run regardless

```bash
command1 ; command2
```

- Runs `command2` regardless of `command1`'s result
- Both commands always run

```bash
docker compose down ; docker compose up -d    # Always restart
```

---

## Quotes (Single vs Double)

Quotes group words together and handle special characters.

### Single Quotes ('...')

- **No interpretation** — everything is literal
- Environment variables are NOT expanded

```bash
echo '$HOME'                    # Output: $HOME (literally)
git commit -m 'Fix bug in $VAR' # Message is literally "Fix bug in $VAR"
```

### Double Quotes ("...")

- **Interpretation happens** — variables ARE expanded
- Most common type of quotes

```bash
echo "$HOME"                    # Output: /home/user (expanded)
git commit -m "Fix bug in $VAR" # Message is "Fix bug in <value of VAR>"
```

### When to Use Which

| Situation | Use |
|---|---|
| Literal text, no variables | Single quotes |
| Text with variables | Double quotes |
| Text with spaces | Either |
| Text with single quotes inside | Double quotes |
| Text with double quotes inside | Single quotes |

### Examples

```bash
# Single quotes — literal
git commit -m 'Add nginx.conf'

# Double quotes — with variable
git commit -m "Update for $CODESPACE_NAME"

# Double quotes — text with spaces
docker run --name "my n8n container" n8nio/n8n

# Heredoc — multi-line (uses 'EOF' to prevent expansion)
cat > Dockerfile <<'EOF'
FROM n8nio/n8n:latest
USER root
EOF
```

---

## Environment Variables ($VAR)

Environment variables store values that can be referenced with `$`.

### Reading a Variable

```bash
echo $CODESPACE_NAME                    # Print the value
echo "URL: https://$CODESPACE_NAME"     # Use in a string
```

### Assigning a Variable

```bash
# Temporary (only in current shell)
export MY_VAR="hello"

# Use it
echo $MY_VAR                            # Output: hello
```

### Built-in Codespace Variables

```bash
$CODESPACE_NAME                                     # e.g., curly-succotash-...
$GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN           # e.g., app.github.dev
```

### Using in Docker Compose

```yaml
environment:
  - N8N_EDITOR_BASE_URL=https://${CODESPACE_NAME}-5678.app.github.dev
```

Docker Compose expands `${CODESPACE_NAME}` to the actual value.

### Seeing All Variables

```bash
printenv                    # All variables
printenv | grep CODESPACE   # Filter for Codespace variables
env                         # Alternative to printenv
```

---

## Special Characters Cheat Sheet

| Character | Name | Meaning |
|---|---|---|
| `-` | Single dash | Short option (1 letter) |
| `--` | Double dash | Long option (full word) |
| `|` | Pipe | Feed output to next command |
| `>` | Redirect | Send output to file (overwrite) |
| `>>` | Append | Send output to file (append) |
| `2>` | Stderr redirect | Send errors to file |
| `2>&1` | Combine streams | Merge stderr into stdout |
| `/dev/null` | Black hole | Discard output |
| `&&` | AND | Run next if previous succeeded |
| `\|\|` | OR | Run next if previous failed |
| `;` | Semicolon | Run next regardless |
| `&` | Background | Run in background |
| `$VAR` | Dollar | Reference environment variable |
| `'...'` | Single quotes | Literal (no expansion) |
| `"..."` | Double quotes | Expand variables |
| `=` | Equals | Attach value to option |
| `#` | Hash | Comment (ignored) |
| `\` | Backslash | Line continuation |
| `~` | Tilde | Home directory |

---

## Decoding Practice

Let's decode some real commands from our session.

### Example 1

```bash
docker logs n8n --tail 200 --timestamps 2>&1 | grep -i "origin"
```

**Decoding:**
1. `docker logs n8n` — get logs from n8n container
2. `--tail 200` — only last 200 lines
3. `--timestamps` — include timestamps
4. `2>&1` — combine stderr (errors) with stdout (normal output)
5. `|` — pipe to next command
6. `grep -i "origin"` — search for "origin" (case-insensitive due to `-i`)

**Meaning:** "Get the last 200 log lines with timestamps, including errors, and search for lines containing 'origin'."

---

### Example 2

```bash
docker rm -f n8n 2>/dev/null || true
```

**Decoding:**
1. `docker rm -f n8n` — force-remove the n8n container
2. `2>/dev/null` — discard any error messages
3. `||` — if the previous command failed...
4. `true` — run `true` (a command that always succeeds)

**Meaning:** "Remove the n8n container if it exists. If it doesn't exist (error), silently continue as if it succeeded."

---

### Example 3

```bash
docker run --rm -it --name n8n -p 8080:5678 \
  -e N8N_PUSH_BACKEND=sse \
  -e N8N_TRUSTED_ORIGINS='*' \
  -v "$(pwd)/n8n_data:/home/node/.n8n" \
  n8nio/n8n
```

**Decoding:**
1. `docker run` — create and start a container
2. `--rm` — remove container when it exits (boolean flag)
3. `-it` — combined: `-i` (interactive) + `-t` (terminal) (combined short flags)
4. `--name n8n` — name the container "n8n" (option with space-separated value)
5. `-p 8080:5678` — map host port 8080 to container port 5678
6. `\` — line continuation (command continues on next line)
7. `-e N8N_PUSH_BACKEND=sse` — set environment variable
8. `-e N8N_TRUSTED_ORIGINS='*'` — set environment variable (single-quoted value)
9. `-v "$(pwd)/n8n_data:/home/node/.n8n"` — mount volume (`$(pwd)` expands to current directory)
10. `n8nio/n8n` — the image to use

**Meaning:** "Run n8n in an interactive terminal, auto-remove on exit, named 'n8n', port 8080→5678, with two environment variables and a volume mount, using the n8nio/n8n image."

---

### Example 4

```bash
curl -i -H "Host: curly-succotash-...app.github.dev" http://localhost:5678/
```

**Decoding:**
1. `curl` — the command (HTTP client)
2. `-i` — include response headers in output (boolean flag)
3. `-H "Host: ..."` — set a custom HTTP header (option with value)
4. `http://localhost:5678/` — the URL (argument)

**Meaning:** "Send an HTTP request to localhost:5678, with a custom Host header, and show me the response headers."

---

### Example 5

```bash
git add . && git commit -m "Update config" && git push
```

**Decoding:**
1. `git add .` — stage all changes
2. `&&` — only continue if add succeeded
3. `git commit -m "Update config"` — commit with message
4. `&&` — only continue if commit succeeded
5. `git push` — push to GitHub

**Meaning:** "Stage, commit, and push — but stop if any step fails."

---

## How to Get Help

### The `--help` Flag

Every command supports `--help`:

```bash
docker --help                      # Docker help
docker compose --help              # Docker Compose help
docker compose up --help           # Specific subcommand help
git --help                         # Git help
git commit --help                  # Specific subcommand help
curl --help                        # curl help
```

### The `man` Command (Manual Pages)

For deeper documentation:

```bash
man docker                         # Docker manual
man git-commit                     # Git commit manual (note the dash)
man curl                           # curl manual
```

- Press `q` to quit
- Press `/` to search
- Press `n` for next match

### The `tldr` Tool (If Installed)

Some systems have `tldr` (too long; didn't read) — simplified help with examples:

```bash
tldr tar                            # Quick examples for tar
tldr docker                         # Quick examples for docker
```

---

## Common Patterns to Remember

### The "Save My Work" Pattern
```bash
git add . && git commit -m "message" && git push
```

### The "Safe Cleanup" Pattern
```bash
docker rm -f <name> 2>/dev/null || true
```

### The "Filter Logs" Pattern
```bash
docker logs <container> 2>&1 | grep -i "<keyword>"
```

### The "Multi-Step with Conditions" Pattern
```bash
command1 && command2 && command3 || echo "Something failed"
```

### The "Discard Output" Pattern
```bash
command > /dev/null 2>&1
```

---

## Key Takeaways

1. **Single dash (`-d`) = short, double dash (`--detach`) = long** — usually the same thing
2. **Boolean flags** don't take values; **value options** do
3. **Combine short boolean flags**: `-fv` = `-f` + `-v`
4. **Pipe (`|`)** feeds output to another command
5. **`2>/dev/null`** discards errors; **`2>&1`** combines errors with output
6. **`&&`** runs next if success; **`||`** runs next if failure
7. **Single quotes** = literal; **double quotes** = expand variables
8. **`$VAR`** references environment variables
9. **Always use `--help`** to learn a command's options
10. **Don't memorize — understand the patterns** and you can decode anything

---

## Practice Exercise

Try decoding this command from our session:

```bash
sudo ss -ltnp | grep :5678
```

**Hints:**
- What does `sudo` do?
- What are the flags `-l`, `-t`, `-n`, `-p`?
- What does `|` do?
- What does `grep :5678` do?

**Answer:**
- `sudo` — run with administrator privileges
- `ss` — socket statistics
- `-l` — listening sockets only
- `-t` — TCP only
- `-n` — numeric (don't resolve names)
- `-p` — show process info
- `|` — pipe to next command
- `grep :5678` — filter for port 5678

**Meaning:** "Show me which process is listening on port 5678, with administrator privileges to see process names."

---

*Last updated: July 2026*
*Don't memorize commands. Memorize principles.*
