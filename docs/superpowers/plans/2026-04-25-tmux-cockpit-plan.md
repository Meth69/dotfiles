# tmux Cockpit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a reproducible tmux cockpit for supervising OpenCode/Codex agents from both the 4K desktop and 14-inch laptop SSH workflows.

**Architecture:** `~/Projects/tmux-cockpit` becomes the source of truth for docs, helper scripts, and tmux fragments. The live `~/.tmux.conf` stays small and sources a project-managed cockpit fragment. Layout behavior is implemented with small zsh scripts that detect terminal size, support manual override, apply desktop/laptop layouts, focus the desktop scratchpad pane, and preserve the existing `opencode-tmux-indicator` attention marker path.

**Tech Stack:** tmux 3.6a, zsh, Kitty, OpenCode, `opencode-tmux-indicator@0.4.0`, dotfiles bare repo, Tailscale SSH.

---

## File Structure

- Modify: `/home/lysergic/Projects/tmux-cockpit/README.md`
  - Entry point for a new agent or fresh-machine restore.
- Modify: `/home/lysergic/Projects/tmux-cockpit/docs/design.md`
  - Canonical user-facing cockpit design.
- Modify: `/home/lysergic/Projects/tmux-cockpit/docs/setup.md`
  - Fresh-machine restoration steps.
- Modify: `/home/lysergic/Projects/tmux-cockpit/docs/verification.md`
  - Verification checklist and commands.
- Modify: `/home/lysergic/Projects/tmux-cockpit/docs/attention-alerts.md`
  - OpenCode/tmux attention marker knowledge.
- Create: `/home/lysergic/Projects/tmux-cockpit/tmux/cockpit.tmux`
  - Project-managed tmux fragment sourced by `~/.tmux.conf`.
- Create: `/home/lysergic/Projects/tmux-cockpit/scripts/tmux-cockpit-mode`
  - zsh helper for mode detection, override storage, and mode printing.
- Create: `/home/lysergic/Projects/tmux-cockpit/scripts/tmux-cockpit-layout`
  - zsh helper for applying desktop, laptop, desktop-two-up, or auto layouts.
- Create: `/home/lysergic/Projects/tmux-cockpit/scripts/tmux-cockpit-scratchpad`
  - zsh helper for focusing the bottom-right desktop scratchpad pane.
- Create: `/home/lysergic/Projects/tmux-cockpit/scripts/tmux-cockpit-verify`
  - zsh helper for non-destructive local verification.
- Modify: `/home/lysergic/.tmux.conf`
  - Source `~/Projects/tmux-cockpit/tmux/cockpit.tmux` after the existing terminal/clipboard basics.
- Modify: `/home/lysergic/.config/kitty/kitty.conf`
  - Finalize the soft bell sound path if the current sound remains unacceptable.

## Notes for Implementers

- Do not create commits unless the user explicitly asks.
- Before editing Hyprland, Kitty, or tmux live configs, create a `.bak.tmux-cockpit` backup.
- Prefer exact, inspectable shell scripts over dense tmux one-liners.
- Do not introduce TPM in this pass.
- Preserve the existing `opencode-tmux-indicator` package and config.
- Use `tmux source-file -n <file>` to parse-check tmux fragments before sourcing live.
- Use `zsh -n <script>` to syntax-check zsh scripts before running them.

### Task 1: Make the project folder self-contained

**Files:**
- Modify: `/home/lysergic/Projects/tmux-cockpit/README.md`
- Modify: `/home/lysergic/Projects/tmux-cockpit/docs/design.md`
- Modify: `/home/lysergic/Projects/tmux-cockpit/docs/setup.md`
- Modify: `/home/lysergic/Projects/tmux-cockpit/docs/verification.md`
- Modify: `/home/lysergic/Projects/tmux-cockpit/docs/attention-alerts.md`

- [ ] **Step 1: Verify project structure exists**

```bash
ls -la "/home/lysergic/Projects/tmux-cockpit" "/home/lysergic/Projects/tmux-cockpit/docs" "/home/lysergic/Projects/tmux-cockpit/scripts" "/home/lysergic/Projects/tmux-cockpit/tmux"
```

Expected: all four directories exist.

- [ ] **Step 2: Replace `README.md` with a complete handoff entry point**

Write this exact content to `/home/lysergic/Projects/tmux-cockpit/README.md`:

```markdown
# tmux-cockpit

Reproducible tmux cockpit customization for coding and AI-agent supervision across:

- local desktop: Hyprland + Kitty + 4K monitor
- remote laptop: Tailscale SSH into the desktop, usually from a 14-inch 1080p display

This folder is the source of truth for the tmux cockpit. A fresh agent should be able to read the markdown files here, inspect the scripts/config fragments, and reproduce the setup on a new machine.

## Start Here

1. Read `docs/design.md` for the intended cockpit behavior.
2. Read `docs/attention-alerts.md` for the existing OpenCode/tmux waiting-marker setup.
3. Read `docs/setup.md` before applying changes to a fresh machine.
4. Run through `docs/verification.md` after any implementation change.

## Current Direction

- one long-lived tmux cockpit session
- desktop mode: two large main panes plus right-side watch stack for three agents and scratchpad
- laptop mode: dual-agent windows, with more agent pairs spread across tmux windows
- automatic size-aware layout mode with manual override
- prefix-only cockpit keybinds to avoid Hyprland/KDE/terminal conflicts
- existing `opencode-tmux-indicator` for agent waiting markers

## Live Integration

The live tmux config should source:

```tmux
source-file ~/Projects/tmux-cockpit/tmux/cockpit.tmux
```

The project files remain canonical. Live dotfiles either source these files or copy generated artifacts from them.
```

- [ ] **Step 3: Run documentation gap scan**

```bash
rg -n "TB""D|TO""DO|place""holder|fill ""in|lat""er|implement ""me" "/home/lysergic/Projects/tmux-cockpit" "/home/lysergic/docs/superpowers/specs/2026-04-25-tmux-cockpit-design.md"
```

Expected: no matches.

### Task 2: Create the cockpit mode helper

**Files:**
- Create: `/home/lysergic/Projects/tmux-cockpit/scripts/tmux-cockpit-mode`

- [ ] **Step 1: Write `tmux-cockpit-mode`**

Write this exact script to `/home/lysergic/Projects/tmux-cockpit/scripts/tmux-cockpit-mode`:

```zsh
#!/usr/bin/env zsh
set -euo pipefail

usage() {
  print -r -- "usage: tmux-cockpit-mode detect|print|set <auto|desktop|laptop|two-up>|cycle"
}

require_tmux() {
  if [[ -z "${TMUX:-}" ]]; then
    print -u2 -- "tmux-cockpit-mode: must run inside tmux"
    exit 1
  fi
}

tmux_get() {
  tmux show-option -gqv "$1" 2>/dev/null || true
}

tmux_set() {
  tmux set-option -gq "$1" "$2"
}

client_width() {
  tmux display-message -p '#{client_width}'
}

detected_mode() {
  local width
  width="$(client_width)"
  if [[ "$width" -ge 180 ]]; then
    print -r -- "desktop"
  else
    print -r -- "laptop"
  fi
}

effective_mode() {
  local override
  override="$(tmux_get '@cockpit_mode_override')"
  case "$override" in
    desktop|laptop|two-up) print -r -- "$override" ;;
    auto|"") detected_mode ;;
    *) detected_mode ;;
  esac
}

set_mode() {
  local mode="$1"
  case "$mode" in
    auto|desktop|laptop|two-up)
      tmux_set '@cockpit_mode_override' "$mode"
      tmux display-message "cockpit mode: $mode"
      ;;
    *)
      print -u2 -- "tmux-cockpit-mode: invalid mode: $mode"
      exit 2
      ;;
  esac
}

cycle_mode() {
  local current next
  current="$(tmux_get '@cockpit_mode_override')"
  [[ -z "$current" ]] && current="auto"
  case "$current" in
    auto) next="desktop" ;;
    desktop) next="laptop" ;;
    laptop) next="two-up" ;;
    two-up) next="auto" ;;
    *) next="auto" ;;
  esac
  set_mode "$next"
}

main() {
  require_tmux
  local cmd="${1:-}"
  case "$cmd" in
    detect) detected_mode ;;
    print) effective_mode ;;
    set) [[ $# -eq 2 ]] || { usage; exit 2; }; set_mode "$2" ;;
    cycle) cycle_mode ;;
    *) usage; exit 2 ;;
  esac
}

main "$@"
```

- [ ] **Step 2: Make the helper executable**

```bash
chmod +x "/home/lysergic/Projects/tmux-cockpit/scripts/tmux-cockpit-mode"
```

Expected: command succeeds.

- [ ] **Step 3: Syntax-check the helper**

```bash
zsh -n "/home/lysergic/Projects/tmux-cockpit/scripts/tmux-cockpit-mode"
```

Expected: no output and exit code 0.

- [ ] **Step 4: Verify mode printing inside tmux**

```bash
"/home/lysergic/Projects/tmux-cockpit/scripts/tmux-cockpit-mode" print
```

Expected: prints `desktop`, `laptop`, or `two-up` depending on the current client width and override state.

### Task 3: Create the layout helper

**Files:**
- Create: `/home/lysergic/Projects/tmux-cockpit/scripts/tmux-cockpit-layout`

- [ ] **Step 1: Write `tmux-cockpit-layout`**

Write this exact script to `/home/lysergic/Projects/tmux-cockpit/scripts/tmux-cockpit-layout`:

```zsh
#!/usr/bin/env zsh
set -euo pipefail

ROOT="${TMUX_COCKPIT_ROOT:-/home/lysergic/Projects/tmux-cockpit}"
MODE_SCRIPT="$ROOT/scripts/tmux-cockpit-mode"

require_tmux() {
  if [[ -z "${TMUX:-}" ]]; then
    print -u2 -- "tmux-cockpit-layout: must run inside tmux"
    exit 1
  fi
}

pane_count() {
  tmux list-panes -F '#{pane_id}' | wc -l | tr -d ' '
}

ensure_panes() {
  local target="$1"
  local count
  count="$(pane_count)"
  while [[ "$count" -lt "$target" ]]; do
    tmux split-window -d -c '#{pane_current_path}'
    count=$(( count + 1 ))
  done
}

apply_desktop() {
  ensure_panes 6
  tmux select-layout tiled >/dev/null
  tmux display-message "cockpit layout: desktop 2-up + watch stack"
}

apply_laptop() {
  ensure_panes 2
  tmux select-layout even-horizontal >/dev/null
  tmux display-message "cockpit layout: laptop dual-agent"
}

apply_two_up() {
  ensure_panes 2
  tmux select-layout even-horizontal >/dev/null
  tmux display-message "cockpit layout: desktop two-up"
}

main() {
  require_tmux
  local requested="${1:-auto}"
  local mode
  if [[ "$requested" == "auto" ]]; then
    mode="$($MODE_SCRIPT print)"
  else
    mode="$requested"
  fi

  case "$mode" in
    desktop) apply_desktop ;;
    laptop) apply_laptop ;;
    two-up) apply_two_up ;;
    *) print -u2 -- "tmux-cockpit-layout: invalid mode: $mode"; exit 2 ;;
  esac
}

main "$@"
```

Note: this first implementation uses safe built-in layouts. If exact 2-up-main-plus-right-stack proportions need more precision, refine this script after verification by using `select-layout` strings captured from an ideal manual layout.

- [ ] **Step 2: Make the helper executable**

```bash
chmod +x "/home/lysergic/Projects/tmux-cockpit/scripts/tmux-cockpit-layout"
```

Expected: command succeeds.

- [ ] **Step 3: Syntax-check the helper**

```bash
zsh -n "/home/lysergic/Projects/tmux-cockpit/scripts/tmux-cockpit-layout"
```

Expected: no output and exit code 0.

- [ ] **Step 4: Test laptop layout in a disposable tmux window**

```bash
tmux new-window -n cockpit-test 'zsh'
"/home/lysergic/Projects/tmux-cockpit/scripts/tmux-cockpit-layout" laptop
tmux display-message -p '#{window_name} #{window_panes}'
```

Expected: output includes `cockpit-test 2` or more if the window already had extra panes; the visible layout is side-by-side.

### Task 4: Create the desktop scratchpad focus helper

**Files:**
- Create: `/home/lysergic/Projects/tmux-cockpit/scripts/tmux-cockpit-scratchpad`

- [ ] **Step 1: Write `tmux-cockpit-scratchpad`**

Write this exact script to `/home/lysergic/Projects/tmux-cockpit/scripts/tmux-cockpit-scratchpad`:

```zsh
#!/usr/bin/env zsh
set -euo pipefail

ROOT="${TMUX_COCKPIT_ROOT:-${HOME}/Projects/tmux-cockpit}"
LAYOUT_SCRIPT="$ROOT/scripts/tmux-cockpit-layout"

require_tmux() {
  if [[ -z "${TMUX:-}" ]]; then
    print -u2 -- "tmux-cockpit-scratchpad: must run inside tmux"
    exit 1
  fi
}

desktop_scratch_pane() {
  local pane_id pane_left pane_top max_left=-1 max_top=-1 target=""
  tmux list-panes -F $'#{pane_id}\t#{pane_left}\t#{pane_top}' | while IFS=$'\t' read -r pane_id pane_left pane_top; do
    if (( pane_left > max_left || (pane_left == max_left && pane_top > max_top) )); then
      max_left="$pane_left"
      max_top="$pane_top"
      target="$pane_id"
    fi
  done
  print -r -- "$target"
}

focus_scratch() {
  local target
  "$LAYOUT_SCRIPT" desktop
  target="$(desktop_scratch_pane)"
  if [[ -z "$target" ]]; then
    print -u2 -- "tmux-cockpit-scratchpad: could not locate desktop scratch pane"
    exit 1
  fi
  tmux select-pane -t "$target"
  tmux display-message "cockpit scratchpad: focused bottom-right desktop pane"
}

main() {
  require_tmux
  local cmd="${1:-focus}"
  case "$cmd" in
    focus) focus_scratch ;;
    target) "$LAYOUT_SCRIPT" desktop >/dev/null; desktop_scratch_pane ;;
    *) print -u2 -- "usage: tmux-cockpit-scratchpad [focus|target]"; exit 2 ;;
  esac
}

main "$@"
```

- [ ] **Step 2: Make the helper executable**

```bash
chmod +x "/home/lysergic/Projects/tmux-cockpit/scripts/tmux-cockpit-scratchpad"
```

Expected: command succeeds.

- [ ] **Step 3: Syntax-check the helper**

```bash
zsh -n "/home/lysergic/Projects/tmux-cockpit/scripts/tmux-cockpit-scratchpad"
```

Expected: no output and exit code 0.

- [ ] **Step 4: Verify desktop scratchpad pane focus**

```bash
"/home/lysergic/Projects/tmux-cockpit/scripts/tmux-cockpit-scratchpad" focus
tmux display-message -p 'active=#{window_name} panes=#{window_panes} index=#{pane_index} size=#{pane_width}x#{pane_height} pos=#{pane_left},#{pane_top}'
```

Expected: current window is `cockpit-desktop`; active pane is the bottom pane in the right-side stack. Laptop mode has no dedicated scratchpad behavior.

### Task 5: Create the tmux cockpit fragment

**Files:**
- Create: `/home/lysergic/Projects/tmux-cockpit/tmux/cockpit.tmux`

- [ ] **Step 1: Write `cockpit.tmux`**

Write this exact content to `/home/lysergic/Projects/tmux-cockpit/tmux/cockpit.tmux`:

```tmux
##### tmux-cockpit: sourced from ~/Projects/tmux-cockpit/tmux/cockpit.tmux

set -g @cockpit_root "$HOME/Projects/tmux-cockpit"
set -g @cockpit_mode_override "auto"

##### OpenCode attention marker + bell
set -gw monitor-bell on
set -g bell-action other
set -g visual-bell off
set -gw window-status-bell-style default

##### Compact adaptive status
set -g status on
set -g status-interval 5
set -g status-left-length 60
set -g status-right-length 100
set -g status-left '#[bold]#S #[dim]#h#{?client_prefix, #[reverse]PREFIX#[default],}'
set -g status-right '#[dim]mode:#(~/Projects/tmux-cockpit/scripts/tmux-cockpit-mode print 2>/dev/null) #[dim]%H:%M'
setw -g window-status-format ' #{?@opencode-waiting,● ,}#I:#W#F '
setw -g window-status-current-format ' #[bold]#{?@opencode-waiting,● ,}#I:#W#F#[default] '

##### Clear waiting marker when attention is given
set-hook -g after-select-window 'set-option -wq -u @opencode-waiting'
set-hook -g session-window-changed 'set-option -wq -u @opencode-waiting'
set-hook -g client-focus-in 'set-option -wq -u @opencode-waiting'

##### Prefix-only cockpit keybinds
bind C-r source-file ~/.tmux.conf \; display-message 'tmux config reloaded'
bind A run-shell -b '~/Projects/tmux-cockpit/scripts/tmux-cockpit-layout auto'
bind D run-shell -b '~/Projects/tmux-cockpit/scripts/tmux-cockpit-mode set desktop; ~/Projects/tmux-cockpit/scripts/tmux-cockpit-layout desktop'
bind L run-shell -b '~/Projects/tmux-cockpit/scripts/tmux-cockpit-mode set laptop; ~/Projects/tmux-cockpit/scripts/tmux-cockpit-layout laptop'
bind T run-shell -b '~/Projects/tmux-cockpit/scripts/tmux-cockpit-mode set two-up; ~/Projects/tmux-cockpit/scripts/tmux-cockpit-layout two-up'
bind M run-shell -b '~/Projects/tmux-cockpit/scripts/tmux-cockpit-mode cycle; ~/Projects/tmux-cockpit/scripts/tmux-cockpit-layout auto'
bind N next-window -a
bind F12 run-shell -b 'TMUX_COCKPIT_ROOT=#{@cockpit_root} #{@cockpit_root}/scripts/tmux-cockpit-scratchpad focus'
```

- [ ] **Step 2: Parse-check the tmux fragment**

```bash
tmux source-file -n "/home/lysergic/Projects/tmux-cockpit/tmux/cockpit.tmux"
```

Expected: no output and exit code 0.

- [ ] **Step 3: Verify key names do not duplicate existing custom binds unexpectedly**

```bash
tmux list-keys | rg 'bind-key (C-r|A|D|L|T|M|N|F12) '
```

Expected: output shows either no existing bindings for these keys or only the newly planned cockpit meanings after the fragment is sourced in Task 6. `F12` must focus the bottom-right desktop scratchpad pane and must not create a dedicated scratchpad window.

### Task 6: Wire the cockpit fragment into live tmux config

**Files:**
- Modify: `/home/lysergic/.tmux.conf`

- [ ] **Step 1: Back up the live tmux config**

```bash
cp "/home/lysergic/.tmux.conf" "/home/lysergic/.tmux.conf.bak.tmux-cockpit"
```

Expected: backup file exists.

- [ ] **Step 2: Remove duplicated attention block from `.tmux.conf` and source cockpit fragment**

Update `/home/lysergic/.tmux.conf` so it contains exactly this content:

```tmux
# True color support (24-bit)
set -g default-terminal "xterm-kitty"
set -ag terminal-overrides ",xterm-kitty:RGB"

# Undercurl + styled underlines
set -as terminal-overrides ',xterm-kitty:Tc'

# Allow OSC 52 passthrough so clipboard sequences reach the local terminal
set -g allow-passthrough on
set -g set-clipboard on

# Join next window into current as a side-by-side pane; break current pane back out
bind v join-pane -h -s :+
bind b break-pane

# Reproducible cockpit customization
source-file ~/Projects/tmux-cockpit/tmux/cockpit.tmux
```

- [ ] **Step 3: Parse-check live tmux config**

```bash
tmux source-file -n "/home/lysergic/.tmux.conf"
```

Expected: no output and exit code 0.

- [ ] **Step 4: Source live tmux config**

```bash
tmux source-file "/home/lysergic/.tmux.conf"
```

Expected: no errors; tmux status line changes to cockpit format.

### Task 7: Finalize soft bell behavior

**Files:**
- Modify: `/home/lysergic/.config/kitty/kitty.conf`
- Modify: `/home/lysergic/Projects/tmux-cockpit/docs/attention-alerts.md`

- [ ] **Step 1: Back up Kitty config**

```bash
cp "/home/lysergic/.config/kitty/kitty.conf" "/home/lysergic/.config/kitty/kitty.conf.bak.tmux-cockpit"
```

Expected: backup file exists.

- [ ] **Step 2: Preview candidate soft bell sound**

```bash
paplay "/usr/share/sounds/freedesktop/stereo/dialog-warning.oga"
```

Expected: sound is short and acceptable to the user.

- [ ] **Step 3: Set Kitty bell command**

Ensure `/home/lysergic/.config/kitty/kitty.conf` contains these lines exactly once:

```conf
enable_audio_bell no
command_on_bell paplay /usr/share/sounds/freedesktop/stereo/dialog-warning.oga
```

- [ ] **Step 4: Reload Kitty config**

Use Kitty's reload shortcut or restart the terminal after saving. Then verify the active terminal uses the updated config.

Expected: new bells use `dialog-warning.oga`.

### Task 8: Create local verification helper

**Files:**
- Create: `/home/lysergic/Projects/tmux-cockpit/scripts/tmux-cockpit-verify`
- Modify: `/home/lysergic/Projects/tmux-cockpit/docs/verification.md`

- [ ] **Step 1: Write `tmux-cockpit-verify`**

Write this exact script to `/home/lysergic/Projects/tmux-cockpit/scripts/tmux-cockpit-verify`:

```zsh
#!/usr/bin/env zsh
set -euo pipefail

ROOT="/home/lysergic/Projects/tmux-cockpit"

print_check() {
  print -r -- "==> $1"
}

print_check "zsh syntax"
zsh -n "$ROOT/scripts/tmux-cockpit-mode"
zsh -n "$ROOT/scripts/tmux-cockpit-layout"
zsh -n "$ROOT/scripts/tmux-cockpit-scratchpad"

print_check "tmux fragment parse"
tmux source-file -n "$ROOT/tmux/cockpit.tmux"

print_check "OpenCode plugin config"
rg '"opencode-tmux-indicator"' "/home/lysergic/.config/opencode/opencode.json" "/home/lysergic/.config/opencode/package.json"

print_check "tmux attention options"
tmux show-window-options -g monitor-bell
tmux show-options -g bell-action
tmux show-options -g visual-bell
tmux show-window-options -g window-status-format

print_check "effective cockpit mode"
"$ROOT/scripts/tmux-cockpit-mode" print
```

- [ ] **Step 2: Make helper executable**

```bash
chmod +x "/home/lysergic/Projects/tmux-cockpit/scripts/tmux-cockpit-verify"
```

Expected: command succeeds.

- [ ] **Step 3: Run helper inside tmux**

```bash
"/home/lysergic/Projects/tmux-cockpit/scripts/tmux-cockpit-verify"
```

Expected: each section prints without errors; plugin config matches; effective cockpit mode prints.

### Task 9: Verify desktop workflow manually

**Files:**
- Modify: `/home/lysergic/Projects/tmux-cockpit/docs/verification.md`

- [ ] **Step 1: Apply desktop layout**

```bash
tmux new-window -n cockpit-desktop-test 'zsh'
"/home/lysergic/Projects/tmux-cockpit/scripts/tmux-cockpit-mode" set desktop
"/home/lysergic/Projects/tmux-cockpit/scripts/tmux-cockpit-layout" desktop
tmux display-message -p '#{window_name} #{window_panes}'
```

Expected: output includes `cockpit-desktop-test 6` or higher; layout is usable on the 4K desktop.

- [ ] **Step 2: Apply two-up override**

```bash
"/home/lysergic/Projects/tmux-cockpit/scripts/tmux-cockpit-mode" set two-up
"/home/lysergic/Projects/tmux-cockpit/scripts/tmux-cockpit-layout" two-up
tmux display-message -p '#{window_name} #{window_panes}'
```

Expected: visible primary layout is side-by-side.

- [ ] **Step 3: Test desktop scratchpad focus**

```bash
"/home/lysergic/Projects/tmux-cockpit/scripts/tmux-cockpit-scratchpad" focus
tmux display-message -p 'active=#{window_name} panes=#{window_panes} index=#{pane_index} size=#{pane_width}x#{pane_height} pos=#{pane_left},#{pane_top}'
```

Expected: current window is `cockpit-desktop`; active pane is the bottom-right pane in the right-side stack. No dedicated scratchpad window is created. Laptop mode has no scratchpad behavior for now.

- [ ] **Step 4: Test waiting marker manually**

```bash
tmux set-option -w @opencode-waiting 1
tmux display-message -p '#{window_status_format}'
```

Expected: current window status displays a waiting dot in the tmux status line.

- [ ] **Step 5: Clear waiting marker**

```bash
tmux set-option -wq -u @opencode-waiting
```

Expected: waiting dot disappears from the current window status.

### Task 10: Verify OpenCode and laptop SSH workflow

**Files:**
- Modify: `/home/lysergic/Projects/tmux-cockpit/docs/verification.md`

- [ ] **Step 1: Start an OpenCode session inside tmux**

```bash
tmux new-window -n opencode-alert-test 'opencode'
```

Expected: OpenCode starts inside tmux and has `$TMUX` / `$TMUX_PANE` available.

- [ ] **Step 2: Trigger a real OpenCode permission or question state**

Ask OpenCode to perform an action that requires permission or use a question prompt path.

Expected: `@opencode-waiting` is set on the relevant tmux window, the waiting dot appears, and a soft bell plays if the window is not active.

- [ ] **Step 3: Verify jump-to-waiting behavior**

From a different tmux window, press the planned prefix binding for `next-window -a` or run:

```bash
tmux next-window -a
```

Expected: tmux switches to a window with a bell/attention flag.

- [ ] **Step 4: Verify laptop SSH behavior**

From the laptop, connect over Tailscale SSH, attach to the cockpit session, and run:

```bash
"/home/lysergic/Projects/tmux-cockpit/scripts/tmux-cockpit-mode" print
"/home/lysergic/Projects/tmux-cockpit/scripts/tmux-cockpit-layout" laptop
tmux display-message -p '#{client_width} #{window_panes}'
```

Expected: mode is `laptop` unless manually overridden; dual-agent layout is readable.

### Task 11: Sync documentation after implementation

**Files:**
- Modify: `/home/lysergic/Projects/tmux-cockpit/docs/setup.md`
- Modify: `/home/lysergic/Projects/tmux-cockpit/docs/verification.md`
- Modify: `/home/lysergic/Projects/tmux-cockpit/docs/attention-alerts.md`
- Modify: `/home/lysergic/docs/superpowers/specs/2026-04-25-tmux-cockpit-design.md`

- [ ] **Step 1: Update setup docs with final installed file list**

Ensure `/home/lysergic/Projects/tmux-cockpit/docs/setup.md` lists every live file touched:

```markdown
## Live Files

- `~/.tmux.conf` sources `~/Projects/tmux-cockpit/tmux/cockpit.tmux`.
- `~/Projects/tmux-cockpit/tmux/cockpit.tmux` defines status, keybinds, and attention hooks.
- `~/Projects/tmux-cockpit/scripts/tmux-cockpit-mode` detects and stores cockpit mode.
- `~/Projects/tmux-cockpit/scripts/tmux-cockpit-layout` applies layouts.
- `~/Projects/tmux-cockpit/scripts/tmux-cockpit-scratchpad` focuses the bottom-right desktop scratchpad pane.
- `~/Projects/tmux-cockpit/scripts/tmux-cockpit-verify` runs non-destructive checks.
- `~/.config/opencode/opencode.json` includes `opencode-tmux-indicator`.
- `~/.config/opencode/package.json` depends on `opencode-tmux-indicator`.
- `~/.config/kitty/kitty.conf` defines final bell behavior.
```

- [ ] **Step 2: Run final gap scan**

```bash
rg -n "TB""D|TO""DO|place""holder|fill ""in|lat""er|implement ""me" "/home/lysergic/Projects/tmux-cockpit" "/home/lysergic/docs/superpowers/specs/2026-04-25-tmux-cockpit-design.md" "/home/lysergic/docs/superpowers/plans/2026-04-25-tmux-cockpit-plan.md"
```

Expected: no matches.

- [ ] **Step 3: Show final git/dotfiles status without committing**

```bash
git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" status --short --untracked-files=all -- \
  .tmux.conf \
  .config/kitty/kitty.conf \
  .config/opencode/opencode.json \
  .config/opencode/package.json \
  Projects/tmux-cockpit \
  docs/superpowers/specs/2026-04-25-tmux-cockpit-design.md \
  docs/superpowers/plans/2026-04-25-tmux-cockpit-plan.md
```

Expected: output shows tracked changes and untracked tmux cockpit docs/files relevant to this work. Do not commit unless the user explicitly asks.
