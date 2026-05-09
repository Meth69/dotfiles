# Claude Code Cleanup Design

## Goal

Remove unused Claude Code tooling from the desktop and dotfiles while keeping current OpenCode and transcription workflows working.

## Scope

The cleanup removes the Claude Code package, local Claude Code state, Claude Code bootstrap files, and the old `ccg` alias. It also moves shell secrets out of tracked `.zshrc` into a local-only secrets file with a tracked example template.

## Decisions

- No backup archive is created because the user explicitly requested full cleanup with no backups.
- OpenCode files stay because they are the current coding-agent setup.
- `openglm()` stays because it launches OpenCode with the GLM preset, not Claude Code.
- `OPENCODE_DISABLE_CLAUDE_CODE_PROMPT=1` stays because it is an OpenCode compatibility setting.
- Project-level `CLAUDE.md` and `AGENTS.md` files outside the dotfiles worktree stay because they are per-project agent instructions, not the local Claude Code install.

## Files

- Modify `.zshrc` to source `~/.config/shell/secrets.zsh` and remove literal secrets plus `ccg`.
- Add `.config/shell/secrets.zsh.example` as tracked documentation.
- Ignore `.config/shell/secrets.zsh` so the real secrets file cannot be staged.
- Delete `scripts/setup-claude.sh` and remove its call from `bootstrap.sh`.
- Delete tracked `.claude/skills/*` files from the dotfiles repo.

## Local machine cleanup

- Uninstall `claude-code` package.
- Remove `~/.claude` and `~/.claude-pulse`.

## Verification

- Shell test checks `.zshrc` has no literal leaked tokens or `ccg` alias, sources the local secrets file, and the secrets template documents the remaining manual setup.
- Verify `claude` is not on `PATH` after package removal.
- Verify staged diff does not contain token-looking strings.

## Follow-up

The Z.ai/Zhipu token was already committed in previous dotfiles history. Rotate it after this cleanup lands.
