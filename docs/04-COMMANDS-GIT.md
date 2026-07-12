# Git Commands Reference

**Purpose:** Complete reference for every Git command used in this project, with purpose, usage context, precautions, and real examples from our debugging session.

**How to use:** Look up a command by name or browse by category. Each entry follows the same template so you can quickly find what you need.

---

## Table of Contents

1. [Status & Information](#status--information)
2. [Staging Changes](#staging-changes)
3. [Committing Changes](#committing-changes)
4. [Pushing to Remote](#pushing-to-remote)
5. [Branch Management](#branch-management)
6. [Viewing History](#viewing-history)
7. [File Inspection](#file-inspection)
8. [Cleanup & Maintenance](#cleanup--maintenance)
9. [Recovery & Undo](#recovery--undo)
10. [Dangerous Commands — Read First](#dangerous-commands--read-first)
11. [Quick Reference Table](#quick-reference-table)
12. [Common Patterns](#common-patterns)

---

## Status & Information

### git status

```bash
git status
```

**Purpose:** Show the current state of your working directory and staging area.

**What It Does:**
- Shows which branch you're on
- Shows whether your branch is up to date with the remote
- Lists untracked files (new files not yet in git)
- Lists modified files (tracked files that changed)
- Lists staged files (ready to commit)

**When to Use:**
- Before committing — to see what will be committed
- After running commands — to verify changes
- When confused about what state your repo is in
- First step in any Git workflow

**When NOT to Use:**
- If you just want the branch name → use `git branch` (faster)

**Precautions:**
None — completely read-only and safe.

**Real Example from Our Session:**
```bash
git status
```
Output:
```
On branch feat-workflow-final-polish
Your branch is up to date with 'origin/feat-workflow-final-polish'.

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        docs/01-SETUP-GUIDE.md

nothing added to commit but untracked files present
```
This showed us that `01-SETUP-GUIDE.md` existed but hadn't been added to git yet.

**Related Commands:**
- `git branch` — just show branches
- `git log --oneline -5` — recent commits
- `git diff` — see what changed

**Common Mistakes:**
- Trying to commit without checking status first → committing wrong files
- Ignoring untracked files → accidentally leaving important files unsaved

---

### git branch

```bash
git branch
```

**Purpose:** List all local branches and show which one you're currently on.

**What It Does:**
- Lists all branches in your local repository
- Marks the current branch with an asterisk (`*`)
- Does NOT show remote branches (use `-a` for that)

**When to Use:**
- Checking which branch you're on
- Seeing what branches exist locally
- Before switching branches

**When NOT to Use:**
- If you want to see remote branches too → use `git branch -a`
- If you want to create a new branch → use `git checkout -b <name>`

**Precautions:**
None — read-only.

**Real Example from Our Session:**
```bash
git branch
```
Output:
```
* feat-workflow-final-polish
  main
```
The `*` shows we were on `feat-workflow-final-polish`.

**Related Commands:**
- `git branch -a` — include remote branches
- `git checkout <branch>` — switch to a branch
- `git checkout -b <new-branch>` — create and switch

**Common Mistakes:**
- Confusing `git branch` (list) with `git checkout` (switch)
- Forgetting the `*` indicates the current branch

---

### git branch -a

```bash
git branch -a
```

**Purpose:** List ALL branches — local AND remote.

**What It Does:**
- Lists local branches (with `*` for current)
- Lists remote-tracking branches (prefixed with `remotes/origin/`)
- Shows the complete branch picture

**When to Use:**
- Seeing what branches exist on GitHub
- Verifying a branch was pushed successfully
- Before creating a new branch (to avoid name conflicts)

**When NOT to Use:**
- If you only care about local branches → use `git branch`

**Precautions:**
None — read-only.

**Real Example from Our Session:**
```bash
git branch -a
```
Output:
```
* feat-workflow-final-polish
  main
  remotes/origin/feat-workflow-final-polish
  remotes/origin/main
```
This confirmed both branches existed locally and on GitHub.

**Related Commands:**
- `git branch` — local branches only
- `git remote -v` — show remote URLs

---

## Staging Changes

### git add <file>

```bash
git add docs/01-SETUP-GUIDE.md
```

**Purpose:** Stage a specific file for the next commit.

**What It Does:**
- Adds the specified file to the staging area
- The file is now tracked and will be included in the next commit
- Other modified files are NOT staged

**When to Use:**
- When you want to commit specific files only
- When you have multiple changes but want separate commits
- Precise control over what gets committed

**When NOT to Use:**
- If you want to stage everything → use `git add .`
- If you want to stage by pattern → use `git add *.md`

**Precautions:**
- Only stages the files you specify
- Doesn't modify the actual files — just marks them for commit
- Safe to run multiple times

**Real Example from Our Session:**
```bash
git add docs/01-SETUP-GUIDE.md
```
This staged the setup guide file so it could be committed.

**Related Commands:**
- `git add .` — stage all changes
- `git add -A` — stage all (including deletions)
- `git reset <file>` — unstage a file

**Common Mistakes:**
- Forgetting to `git add` before `git commit` → "nothing added to commit"
- Adding files you didn't mean to → use `git reset <file>` to unstage

---

### git add .

```bash
git add .
```

**Purpose:** Stage ALL changes in the current directory and subdirectories.

**What It Does:**
- Stages all new files
- Stages all modified files
- Stages all deletions
- The `.` means "current directory and everything below"

**When to Use:**
- When you want to commit all your changes at once
- Quick staging when you know all changes should be committed
- After verifying with `git status` that everything looks right

**When NOT to Use:**
- If you want separate commits for different changes → use `git add <file>`
- If you have sensitive files (like `.env`) → stage files individually

**Precautions:**
- ⚠️ Stages EVERYTHING — check `git status` first!
- Make sure your `.gitignore` is correct (excludes sensitive files)
- Doesn't stage files outside the current directory

**Real Example from Our Session:**
```bash
git add .
```
Used when we wanted to stage all documentation files at once.

**Related Commands:**
- `git add -A` — stage everything (including parent directory changes)
- `git add <file>` — stage specific files
- `git reset` — unstage everything

**Common Mistakes:**
- Not checking `git status` first → accidentally committing sensitive files
- Confusing `git add .` with `git add -A` (slightly different scope)

---

### git add -A

```bash
git add -A
```

**Purpose:** Stage ALL changes in the entire repository.

**What It Does:**
- Stages new files, modifications, and deletions
- Works across the ENTIRE repository (not just current directory)
- More comprehensive than `git add .`

**When to Use:**
- When you've moved or deleted files
- When changes span multiple directories
- When you want to ensure EVERYTHING is staged

**When NOT to Use:**
- If you only want specific files → use `git add <file>`
- If you want to review changes first → use `git add .` after checking status

**Precautions:**
- ⚠️ Stages EVERYTHING across the whole repo
- Always check `git status` afterward

**Real Example from Our Session:**
```bash
git add -A
```
Used when we moved files between folders (e.g., fixing the `docs/docs/` nesting issue).

**Related Commands:**
- `git add .` — current directory only
- `git add <file>` — specific files

---

## Committing Changes

### git commit -m "message"

```bash
git commit -m "Add setup guide (01-SETUP-GUIDE.md)"
```

**Purpose:** Save a snapshot of your staged changes with a message.

**What It Does:**
- Creates a new commit with all staged changes
- The `-m` flag lets you provide the commit message inline
- The commit is saved locally (not yet on GitHub)

**When to Use:**
- After staging files with `git add`
- When you've completed a logical unit of work
- Before pushing to GitHub

**When NOT to Use:**
- If you haven't staged anything → "nothing added to commit"
- If you want a longer multi-line message → use `git commit` (without `-m`)

**Precautions:**
- You MUST `git add` files first
- Commit messages should be descriptive (explain WHY, not just WHAT)
- Commits are local until you `git push`

**Real Example from Our Session:**
```bash
git add docs/01-SETUP-GUIDE.md
git commit -m "Add setup guide (01-SETUP-GUIDE.md)"
```

**Related Commands:**
- `git add` — stage files first
- `git push` — send commits to GitHub
- `git commit --amend` — modify the last commit

**Common Mistakes:**
- Trying to commit without `git add` first → "nothing added to commit"
- Vague messages like "update" or "fix" → be descriptive!
- Forgetting to push → commits stay local

---

### git commit -m "message" (multi-line)

```bash
git commit -m "Add Nginx reverse proxy to fix n8n Connection Lost in Codespaces

- Adds nginx.conf with Origin header rewriting
- Fixes the known n8n Origin header mismatch bug in Codespaces
- Both n8n and nginx now run as Docker Compose services"
```

**Purpose:** Create a commit with a detailed multi-line message.

**What It Does:**
- First line is the commit title
- Blank line
- Subsequent lines are the description/body
- Useful for explaining complex changes

**When to Use:**
- For significant changes that need explanation
- When future you will need context
- For commits that fix bugs (explain the bug and the fix)

**When NOT to Use:**
- For trivial changes → single-line message is fine

**Precautions:**
- Keep the first line under 50 characters if possible
- Leave a blank line between title and body
- Wrap body text at 72 characters

**Real Example from Our Session:**
```bash
git commit -m "Add Nginx reverse proxy to fix n8n Connection Lost in Codespaces

- Adds nginx.conf with Origin header rewriting
- Fixes the known n8n Origin header mismatch bug in Codespaces
- Both n8n and nginx now run as Docker Compose services"
```

**Related Commands:**
- `git commit -m "single line"` — simpler version
- `git log` — view commit messages

---

## Pushing to Remote

### git push

```bash
git push
```

**Purpose:** Upload your local commits to GitHub.

**What It Does:**
- Sends your local commits to the remote repository (GitHub)
- Updates the remote branch to match your local branch
- Requires that you've set up an upstream branch

**When to Use:**
- After committing changes you want to save to GitHub
- Before ending a work session
- When you want others to see your changes

**When NOT to Use:**
- If no upstream is set → use `git push --set-upstream origin <branch>`
- If you haven't committed anything → nothing to push

**Precautions:**
- Requires internet connection
- If push is rejected → run `git pull` first (someone else pushed changes)

**Real Example from Our Session:**
```bash
git push
```
Output:
```
To github.com:kami551/ai-cold-email-outreach.git
   abc1234..def5678  feat-workflow-final-polish -> feat-workflow-final-polish
```

**Related Commands:**
- `git push --set-upstream origin <branch>` — first push for a new branch
- `git pull` — get changes from GitHub
- `git fetch` — download without merging

**Common Mistakes:**
- Forgetting to commit before pushing → "Everything up-to-date"
- Not setting upstream on a new branch → "no upstream branch" error

---

### git push --set-upstream origin <branch>

```bash
git push --set-upstream origin feat-workflow-final-polish
```

**Purpose:** Push a new branch to GitHub AND set up tracking.

**What It Does:**
- Creates the branch on GitHub (remote)
- Sets up the link between local and remote branch
- Future `git push` commands will work without extra flags

**When to Use:**
- First time pushing a new branch
- When you see "no upstream branch" error
- After creating a new branch with `git checkout -b`

**When NOT to Use:**
- If upstream is already set → use plain `git push`
- If you're just updating an existing branch → use `git push`

**Precautions:**
- Only needed ONCE per branch
- After this, `git push` alone will work

**Real Example from Our Session:**
```bash
git push --set-upstream origin feat-workflow-final-polish
```
Output:
```
Enumerating objects: 15, done.
...
To github.com:kami551/ai-cold-email-outreach.git
 * [new branch]      feat-workflow-final-polish -> feat-workflow-final-polish
branch 'feat-workflow-final-polish' set up to track 'origin/feat-workflow-final-polish'.
```

**Related Commands:**
- `git push` — after upstream is set
- `git checkout -b <new-branch>` — create a new branch

**Common Mistakes:**
- Running this on an existing branch → harmless but unnecessary
- Forgetting to do this on a new branch → `git push` fails with "no upstream"

---

### git pull

```bash
git pull
```

**Purpose:** Download changes from GitHub and merge them into your local branch.

**What It Does:**
- Fetches changes from the remote
- Merges them into your current branch
- Combines `git fetch` + `git merge` in one command

**When to Use:**
- Before pushing if push is rejected
- When collaborating (others may have pushed changes)
- When you've made changes on GitHub directly (web editor)

**When NOT to Use:**
- If you have uncommitted changes → commit or stash first
- If you want to see what changed without merging → use `git fetch`

**Precautions:**
- Can cause merge conflicts if you and someone else changed the same lines
- Always commit your work before pulling

**Real Example from Our Session:**
Used after uploading files via GitHub's web interface to sync the Codespace.

**Related Commands:**
- `git fetch` — download without merging
- `git merge` — merge a specific branch

---

## Branch Management

### git checkout <branch>

```bash
git checkout main
git checkout feat-workflow-final-polish
```

**Purpose:** Switch to a different branch.

**What It Does:**
- Changes your working directory to match the target branch
- Updates all files to the branch's state
- Changes the active branch for future commits

**When to Use:**
- Switching between feature branches
- Going back to `main` branch
- Before creating a new branch

**When NOT to Use:**
- If you have uncommitted changes → commit or stash first
- If you want to create a new branch → use `git checkout -b <name>`

**Precautions:**
- Uncommitted changes may prevent switching → commit or stash first
- Your working directory updates to match the target branch

**Real Example from Our Session:**
```bash
git checkout feat-workflow-final-polish
```

**Related Commands:**
- `git checkout -b <new-branch>` — create and switch
- `git switch <branch>` — newer alternative (Git 2.23+)

---

### git checkout -b <new-branch>

```bash
git checkout -b feat-workflow-final-polish
```

**Purpose:** Create a new branch AND switch to it in one command.

**What It Does:**
- Creates a new branch from the current branch
- Switches to the new branch immediately
- Combines `git branch <name>` + `git checkout <name>`

**When to Use:**
- Starting a new feature
- Creating a branch for experiments
- When you want to work on something without affecting `main`

**When NOT to Use:**
- If the branch already exists → use `git checkout <existing-branch>`

**Precautions:**
- The new branch starts from your current branch's state
- Remember to push with `--set-upstream` when ready

**Real Example from Our Session:**
The `feat-workflow-final-polish` branch was created this way at the start of the project.

**Related Commands:**
- `git branch <name>` — create without switching
- `git push --set-upstream origin <branch>` — push new branch

---

## Viewing History

### git log --oneline -5

```bash
git log --oneline -5
```

**Purpose:** Show the last 5 commits in a compact format.

**What It Does:**
- Shows recent commits (last 5)
- Each commit on one line: hash + message
- Compact, easy to read

**When to Use:**
- Checking what you've committed recently
- Verifying a commit was successful
- Seeing commit history at a glance

**When NOT to Use:**
- If you want full details → use `git log` (without `--oneline`)
- If you want to see who committed → use `git log --author`

**Precautions:**
None — read-only.

**Real Example from Our Session:**
```bash
git log --oneline -5
```
Output:
```
def5678 Add setup guide (01-SETUP-GUIDE.md)
abc1234 Add documentation index (00-INDEX.md)
9ab1234 Working n8n setup with Nginx reverse proxy for Codespaces
...
```

**Related Commands:**
- `git log` — full commit details
- `git log --oneline --graph` — with branch visualization

---

### git log

```bash
git log
```

**Purpose:** Show full commit history with details.

**What It Does:**
- Shows all commits (most recent first)
- Each commit shows: hash, author, date, full message
- Opens in a pager (press `q` to quit)

**When to Use:**
- Detailed review of commit history
- Finding when a change was made
- Seeing full commit messages

**When NOT to Use:**
- Quick checks → use `git log --oneline -5`

**Precautions:**
- Output can be very long → use `q` to quit, `/` to search

**Real Example from Our Session:**
Used to verify all documentation files were committed.

**Related Commands:**
- `git log --oneline` — compact view
- `git log --graph --oneline` — visual branch history

---

## File Inspection

### git ls-files

```bash
git ls-files
git ls-files | grep -E "nginx|docker-compose|Dockerfile|devcontainer"
```

**Purpose:** List all files tracked by git.

**What It Does:**
- Shows every file git is tracking
- Doesn't show untracked files (use `git status` for those)
- Useful for verifying files are tracked

**When to Use:**
- Verifying a file was added to git
- Checking what's in the repository
- Filtering for specific files (with `grep`)

**When NOT to Use:**
- If you want to see untracked files too → use `git status`

**Precautions:**
None — read-only.

**Real Example from Our Session:**
```bash
git ls-files | grep -E "nginx|docker-compose|Dockerfile|devcontainer"
```
Output:
```
.devcontainer/devcontainer.json
Dockerfile
docker-compose.yml
nginx.conf
```
This confirmed all 4 critical files were tracked by git.

**Related Commands:**
- `git status` — includes untracked files
- `ls` — shows all files (not just git-tracked)

---

### git diff

```bash
git diff
```

**Purpose:** Show changes that are NOT yet staged.

**What It Does:**
- Compares your working directory to the staging area
- Shows what you've changed but haven't staged
- Line-by-line diff with `+` (additions) and `-` (deletions)

**When to Use:**
- Reviewing changes before staging
- Understanding what you modified
- Debugging "what did I change?"

**When NOT to Use:**
- If you want to see staged changes → use `git diff --staged`
- If you want to see all changes → use `git diff HEAD`

**Precautions:**
None — read-only.

**Real Example from Our Session:**
Used to check what changes were pending before committing.

**Related Commands:**
- `git diff --staged` — staged changes
- `git diff HEAD` — all changes vs last commit

---

## Cleanup & Maintenance

### git stash

```bash
git stash
git stash pop
```

**Purpose:** Temporarily save changes without committing them.

**What It Does:**
- `git stash` — saves your changes and reverts to clean state
- `git stash pop` — restores the stashed changes
- Useful when you need to switch branches but aren't ready to commit

**When to Use:**
- When you need to switch branches but have uncommitted changes
- When you want to test something without committing
- Before pulling changes that might conflict

**When NOT to Use:**
- If your changes are ready → just commit them
- If you don't need to switch contexts

**Precautions:**
- Stashes are local (not pushed to GitHub)
- You can have multiple stashes → use `git stash list` to see them

**Real Example from Our Session:**
Not used — we committed everything instead.

**Related Commands:**
- `git stash list` — see all stashes
- `git stash drop` — delete a stash

---

### git clean

```bash
git clean -n      # dry run (show what would be deleted)
git clean -fd     # actually delete untracked files and directories
```

**Purpose:** Remove untracked files from your working directory.

**What It Does:**
- Removes files that aren't tracked by git
- `-f` = force (required)
- `-d` = include directories
- `-n` = dry run (preview, don't delete)

**When to Use:**
- Cleaning up build artifacts
- Removing temporary files
- Resetting to a clean state

**When NOT to Use:**
- If you have untracked files you want to keep → they'll be deleted!
- Without `-n` first to preview

**Precautions:**
- ⚠️ **DELETES untracked files permanently**
- Always use `-n` (dry run) first to see what will be deleted
- Doesn't affect tracked files

**Real Example from Our Session:**
Not used — we were careful about file management.

**Related Commands:**
- `git clean -n` — preview (always do this first!)
- `git reset --hard` — reset tracked files (different purpose)

---

## Recovery & Undo

### git reset <file>

```bash
git reset docs/01-SETUP-GUIDE.md
```

**Purpose:** Unstage a file (remove from staging area, keep changes).

**What It Does:**
- Removes the file from the staging area
- The file's changes remain in your working directory
- The opposite of `git add`

**When to Use:**
- When you staged a file by mistake
- When you want to split a commit into smaller commits
- Before re-staging with different files

**When NOT to Use:**
- If you want to discard changes entirely → use `git checkout -- <file>`

**Precautions:**
- Doesn't delete your changes — just unstages them
- Safe to use

**Real Example from Our Session:**
Used to unstage files when we wanted to reorganize a commit.

**Related Commands:**
- `git reset` — unstage everything
- `git checkout -- <file>` — discard changes

---

### git checkout -- <file>

```bash
git checkout -- docker-compose.yml
```

**Purpose:** Discard changes to a file (revert to last commit).

**What It Does:**
- Replaces the file with the version from the last commit
- Your uncommitted changes are LOST
- The `--` separates the file from branch names

**When to Use:**
- When you've made mistakes and want to start over
- When a file is broken and you want the last good version

**When NOT to Use:**
- If you want to keep your changes → use `git stash` instead
- Without thinking — your changes are permanently lost

**Precautions:**
- ⚠️ **Changes are permanently lost** — no undo
- Only affects the specified file

**Real Example from Our Session:**
Not used — we were careful to commit before making major changes.

**Related Commands:**
- `git reset <file>` — unstage (keep changes)
- `git stash` — save changes temporarily

---

## Dangerous Commands — Read First

### ⚠️ git push --force

```bash
git push --force
git push -f
```

**Purpose:** Force-push, overwriting the remote branch.

**What It Does:**
- Overwrites the remote branch with your local branch
- **Discards any commits on GitHub that aren't in your local branch**
- Can destroy others' work if collaborating

**When to Use:**
- ❌ **Almost NEVER** when collaborating
- Only when you're the only person on the branch
- After rewriting history (e.g., `git rebase`)

**When NOT to Use:**
- When others might have pulled from the branch
- For routine pushes → use `git push`
- When unsure → don't use it

**Precautions:**
- 🚨 **Can destroy others' work**
- 🚨 **No undo for remote changes**
- Use `git push --force-with-lease` instead (safer)

**Real Example from Our Session:**
- ❌ We did NOT use this command
- Documented as a WARNING

**Related Commands:**
- `git push --force-with-lease` — safer alternative
- `git push` — normal push

---

### ⚠️ git reset --hard

```bash
git reset --hard HEAD~1
git reset --hard origin/main
```

**Purpose:** Reset your branch to a specific commit, DISCARDING all changes.

**What It Does:**
- Moves your branch pointer to the specified commit
- **DELETES all uncommitted changes**
- **DELETES commits after the target**

**When to Use:**
- ❌ **Almost NEVER** in normal operation
- Only when you want to completely undo recent work
- Only when you're absolutely sure

**When NOT to Use:**
- If you want to keep your changes → use `git stash` or `git reset` (soft)
- For routine undo → use `git reset HEAD~1` (without `--hard`)

**Precautions:**
- 🚨 **PERMANENTLY DELETES uncommitted changes**
- 🚨 **PERMANENTLY DELETES commits after the target**
- No undo

**Real Example from Our Session:**
- ❌ We did NOT use this command
- Documented as a WARNING

**Related Commands:**
- `git reset HEAD~1` — undo commit, keep changes (safer)
- `git reset --soft HEAD~1` — undo commit, keep staged
- `git revert <commit>` — create a new commit that undoes (safest)

---

### ⚠️ git push --force-with-lease

```bash
git push --force-with-lease
```

**Purpose:** Safer version of force-push — only pushes if no one else has pushed.

**What It Does:**
- Force-pushes ONLY if the remote hasn't changed since your last fetch
- Prevents overwriting others' work
- Still overwrites if you're the only one who pushed

**When to Use:**
- After a `git rebase` (when you need to force-push)
- Safer alternative to `git push --force`

**When NOT to Use:**
- For routine pushes → use `git push`

**Precautions:**
- Safer than `--force`, but still overwrites your own remote commits
- Always `git fetch` first to have accurate remote state

**Real Example from Our Session:**
Not used — we didn't need to force-push.

**Related Commands:**
- `git push --force` — dangerous version
- `git push` — normal push

---

## Quick Reference Table

| Command | Purpose | Safe? |
|---|---|---|
| `git status` | Show current state | ✅ Yes |
| `git branch` | List local branches | ✅ Yes |
| `git branch -a` | List all branches | ✅ Yes |
| `git add <file>` | Stage a file | ✅ Yes |
| `git add .` | Stage all changes | ✅ Yes |
| `git add -A` | Stage everything | ✅ Yes |
| `git commit -m "msg"` | Commit staged changes | ✅ Yes |
| `git push` | Upload to GitHub | ✅ Yes |
| `git push --set-upstream origin <branch>` | First push of new branch | ✅ Yes |
| `git pull` | Download and merge | ✅ Yes |
| `git checkout <branch>` | Switch branch | ✅ Yes |
| `git checkout -b <new>` | Create and switch | ✅ Yes |
| `git log --oneline -5` | Recent commits | ✅ Yes |
| `git ls-files` | List tracked files | ✅ Yes |
| `git diff` | Show unstaged changes | ✅ Yes |
| `git reset <file>` | Unstage a file | ✅ Yes |
| `git stash` | Temporarily save changes | ✅ Yes |
| `git checkout -- <file>` | Discard changes | ⚠️ Loses changes |
| `git clean -fd` | Delete untracked files | ⚠️ Deletes files |
| `git push --force` | Overwrite remote | 🚨 DANGEROUS |
| `git reset --hard` | Discard all changes | 🚨 DANGEROUS |

---

## Common Patterns

### The "Save My Work" Pattern
```bash
git status
git add .
git commit -m "Descriptive message about what changed"
git push
```

### The "New Branch" Pattern
```bash
git checkout -b my-new-feature
# ... make changes ...
git add .
git commit -m "Add new feature"
git push --set-upstream origin my-new-feature
```

### The "Quick Check" Pattern
```bash
git status
git log --oneline -5
git branch
```

### The "Verify Files Are Tracked" Pattern
```bash
git ls-files | grep -E "Dockerfile|docker-compose|nginx|devcontainer"
```

### The "Safe Undo" Pattern (undo last commit, keep changes)
```bash
git reset HEAD~1
# Your changes are now unstaged but still in your working directory
```

### The "Fix a Mistake in Last Commit" Pattern
```bash
# Make the fix
git add <fixed-file>
git commit --amend -m "Updated commit message"
# Note: Don't amend if you've already pushed!
```

---

## Git Workflow Rules to Remember

1. **Always check `git status` before committing** — know what you're committing
2. **Write descriptive commit messages** — future you will thank you
3. **Commit often** — small commits are easier to understand and undo
4. **Push after committing** — don't leave commits only on your machine
5. **Never commit secrets** — use `.gitignore` for `.env`, credentials, keys
6. **When in doubt, `git status`** — it's always safe and always helpful
7. **Avoid `--force` and `--hard`** — there's usually a safer alternative
8. **Use branches for experiments** — keep `main` clean

---

*Last updated: July 2026*
