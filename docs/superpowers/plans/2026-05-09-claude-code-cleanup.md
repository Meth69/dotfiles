# Claude Code Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove unused Claude Code tooling and move shell secrets out of tracked dotfiles.

**Architecture:** Dotfiles changes are tracked in the bare repo. Machine-local secrets remain in `~/.config/shell/secrets.zsh`, which is explicitly ignored, while `secrets.zsh.example` documents what future setups need.

**Tech Stack:** Bash, zsh, Arch/CachyOS pacman, bare git dotfiles repo.

---

### Task 1: Secret split and zsh cleanup

**Files:**
- Modify: `.zshrc`
- Create: `.config/shell/secrets.zsh.example`
- Create local-only: `.config/shell/secrets.zsh`
- Modify: `.dotfiles/.gitignore`
- Test: `tests/scripts/test_shell_cleanup.sh`

- [ ] **Step 1: Write failing test**

Create `tests/scripts/test_shell_cleanup.sh` to assert that tracked shell config has no literal token values, no `ccg` alias, sources `~/.config/shell/secrets.zsh`, and the example file documents `ZHIPUAI_API_KEY`, optional `HF_TOKEN`, and retired `ANTHROPIC_AUTH_TOKEN`.

- [ ] **Step 2: Run test to verify it fails**

Run `bash tests/scripts/test_shell_cleanup.sh`. It should fail because `.zshrc` still contains literal tokens and `ccg`.

- [ ] **Step 3: Implement minimal cleanup**

Move the live Zhipu key into `.config/shell/secrets.zsh`, remove `HF_TOKEN` and `ccg` from `.zshrc`, add the source block, and add tracked docs plus ignore protection.

- [ ] **Step 4: Run test to verify it passes**

Run `bash tests/scripts/test_shell_cleanup.sh`.

### Task 2: Claude Code dotfiles cleanup

**Files:**
- Modify: `bootstrap.sh`
- Delete: `scripts/setup-claude.sh`
- Delete tracked files under `.claude/skills/`
- Keep deleted: `CLAUDE.md`

- [ ] **Step 1: Remove bootstrap hook**

Delete the `bash ~/scripts/setup-claude.sh` call from `bootstrap.sh`.

- [ ] **Step 2: Remove tracked Claude Code setup artifacts**

Remove `scripts/setup-claude.sh` and tracked `.claude/skills/*` files from the dotfiles index.

- [ ] **Step 3: Verify tracked Claude artifacts are gone**

Run `git --git-dir=$HOME/.dotfiles --work-tree=$HOME ls-tree -r --name-only HEAD | rg '(^|/)(CLAUDE\.md|\.claude/|setup-claude|claude|anthropic|settings-glm)'` after commit to verify none remain.

### Task 3: Local package and state cleanup

**Files:**
- Local package: `claude-code`
- Local directories: `~/.claude`, `~/.claude-pulse`

- [ ] **Step 1: Remove package**

Run `sudo pacman -Rns --noconfirm claude-code`.

- [ ] **Step 2: Remove local state with no backup**

Run `rm -rf ~/.claude ~/.claude-pulse` only after explicit approval. The user approved no backups.

- [ ] **Step 3: Verify command is gone**

Run `command -v claude` and expect no result.

### Task 4: Commit and push

**Files:**
- All safe tracked dotfiles changes after staged secret scan.

- [ ] **Step 1: Run verification**

Run shell tests, `bash -n`, and staged secret scans.

- [ ] **Step 2: Commit**

Commit all intended safe dotfiles changes.

- [ ] **Step 3: Push**

Push to `origin/main`.

- [ ] **Step 4: Remind user**

Tell the user to rotate the Z.ai/Zhipu API key because it was already in git history.
