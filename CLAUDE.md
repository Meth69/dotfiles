# System Notes

## OS & Environment
- Arch Linux, Wayland/Hyprland desktop
- Shell: zsh
- Prefer modern CLI tools: `rg` over grep, `fd` over find, `bat` over cat

## Package Management
Before installing any package, follow this protocol:
1. `yay -Ss <name>` — list all variants, note `-bin` and `-git` options
2. `yay -Si <package>` — show dependencies and installed size
3. `yay -S --print <package>` — check for conflicts with currently installed packages
4. Flag if any dependency would remove an existing package — never silently remove packages
5. Prefer `-bin` over source builds unless told otherwise
6. Only install after confirmation
7. If the package fails after install, check the Arch Wiki and AUR comments for known Wayland/Hyprland compatibility issues before troubleshooting

## Hyprland & Wayland Configs
When making any change to a Hyprland, hyprpaper, hypridle, hyprlock, or Waybar config:
1. Check the installed version first (`tool --version`) and look for recent breaking changes
2. Back up the current config: `cp file.conf file.conf.bak`
3. Apply the change
4. If a config check command exists, run it to validate
5. If the change breaks things, restore the backup: `cp file.conf.bak file.conf`
6. Report what went wrong rather than attempting more changes on a broken state

## Search & Research
- Use `mcp__searxng__search` for web searches instead of other search tools

## Web Fetching
- **NEVER** use the built-in `WebFetch` tool to fetch/read URLs
- **ALWAYS** use `mcp__MCP_DOCKER__fetch` instead for all URL fetching
- This applies to all URL reading: documentation, pages, links shared by the user, etc.
- If `mcp__MCP_DOCKER__fetch` fails, try `mcp__MCP_DOCKER__fetch_content` as a fallback
- Do NOT fall back to the built-in `WebFetch` under any circumstances

## Git & Commits
- Don't add "Co-Authored-By: Claude" to commits

## Dotfiles Bare Repo
- Dotfiles are tracked in a bare git repo at `~/.dotfiles`
- Commands: `git --git-dir=$HOME/.dotfiles --work-tree=$HOME <command>`
- Alias available after sourcing .zshrc: `dotfiles <command>`
- For focused dotfiles work, use `~/dots/` which has a `.git` pointer to `~/.dotfiles`
