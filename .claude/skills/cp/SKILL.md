---
name: cp
description: Universal commit-and-push. Detects dotfiles bare repo vs regular git repo automatically, generates a commit message from the diff, and pushes. Never adds Co-Authored-By.
---

# Commit & Push

## Step 1 — Detect repo mode

Run this to determine which git context we're in:

```bash
git rev-parse --is-inside-work-tree 2>/dev/null
```

- **If it outputs `true`** → we're in a normal git repo. Use standard `git` commands from here.
- **If it fails or outputs nothing** → check whether `$HOME/.dotfiles` exists:
  ```bash
  test -d "$HOME/.dotfiles" && echo "dotfiles" || echo "no repo"
  ```
  If dotfiles: use `git --git-dir=$HOME/.dotfiles --work-tree=$HOME` for all subsequent commands.

Set GIT to either `git` or `git --git-dir=$HOME/.dotfiles --work-tree=$HOME` based on the above.

## Step 2 — Show what's changed

Run:
```bash
$GIT status
$GIT diff --stat HEAD 2>/dev/null || $GIT diff --stat
```

If nothing is changed or staged, report "Nothing to commit." and stop.

## Step 3 — Stage changes

- For a **normal repo**: stage all modified/untracked files with `git add -A`, but never add `.env`, credentials, or secrets.
- For the **dotfiles repo**: stage only the files that show up in `git --git-dir=$HOME/.dotfiles --work-tree=$HOME status --porcelain` — do not use `-A` (it would sweep `$HOME` indiscriminately). Stage each changed file explicitly by path.

## Step 4 — Generate commit message

Read the full diff:
```bash
$GIT diff --cached
```

Write a concise commit message:
- One short subject line (imperative mood, ≤72 chars)
- Optional body if multiple distinct changes are worth listing
- **No** `Co-Authored-By` line — never add it

If `$ARGUMENTS` were passed to the skill invocation, use them as the commit message verbatim instead of generating one.

## Step 5 — Commit

```bash
$GIT commit -m "$(cat <<'EOF'
<generated or provided message>
EOF
)"
```

## Step 6 — Push

```bash
$GIT push
```

If push fails due to no upstream set, run:
```bash
$GIT push --set-upstream origin <current-branch>
```

Report success with the commit hash and branch pushed to.
