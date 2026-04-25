# Tmux Cockpit Design

## Purpose

Create a long-lived tmux cockpit for coding and AI-agent supervision on a powerful desktop, while remaining comfortable over Tailscale SSH from a 14-inch laptop. The cockpit should make it easy to watch multiple OpenCode/Codex sessions, notice when an agent needs input, promote an agent into focus, and prepare prompts in a scratchpad before sending them.

## Implemented State

- `~/.tmux.conf` is minimal and sources `~/Projects/tmux-cockpit/tmux/cockpit.tmux` after terminal, OSC52 clipboard, and pane join/break basics.
- No TPM/plugin-manager setup is currently in use.
- `opencode-tmux-indicator@0.4.0` is installed in `~/.config/opencode/package.json` and enabled in `~/.config/opencode/opencode.json`.
- The OpenCode indicator plugin sets `@opencode-waiting` and emits BEL when an agent asks for input.
- Live tmux options include waiting-dot window formats, focus-clear hooks, `monitor-bell on`, `bell-action other`, compact status with `#h` host display, effective mode display, and prefix F5-F12 cockpit bindings.
- Kitty's built-in audio bell is disabled and `command_on_bell` runs `paplay /usr/share/sounds/freedesktop/stereo/dialog-warning.oga`.
- Local desktop verification and local laptop-mode simulation have run. Real laptop-over-Tailscale SSH, SSH-context visibility beyond the `#h` host field, and live OpenCode prompt end-to-end verification remain pending.

## Design Direction

Use one long-lived tmux session as the cockpit. The design should be agent-first, mostly direct tmux keybinds behind the tmux prefix, compact/adaptive in the status line, and visually similar to the user's Hyprland master workflow: focused working panes plus smaller watch lanes, with explicit promotion when a side item needs attention.

The cockpit should not introduce a full tmux theme framework or plugin manager yet. Keep it config-driven, adding small helper scripts only where tmux configuration alone becomes brittle.

## Reproducible Project Folder

All tmux cockpit work should live in a dedicated project folder:

```text
~/Projects/tmux-cockpit/
```

This folder is the source of truth for the customization, separate from the live `~/.tmux.conf`. A brand new agent should be able to read this folder and reproduce the setup on a fresh machine.

Required structure:

```text
~/Projects/tmux-cockpit/
  README.md                  # entry point and reproduction guide
  docs/
    design.md                # product/UX design for the cockpit
    setup.md                 # installation and fresh-machine restoration steps
    verification.md          # desktop/laptop test checklist
    attention-alerts.md      # OpenCode indicator + bell behavior knowledge
  tmux/
    cockpit.tmux             # canonical tmux config fragment sourced by ~/.tmux.conf
  scripts/
    tmux-cockpit-mode        # mode detection/override helper
    tmux-cockpit-layout      # desktop/laptop/two-up/auto layout helper
    tmux-cockpit-scratchpad  # focus bottom-right desktop scratchpad pane
    tmux-cockpit-verify      # non-destructive local verification helper
```

The live dotfiles should either source files from this project or copy generated artifacts from it. The project folder should contain enough documentation and scripts that machine resets do not lose the cockpit design or implementation knowledge.

## Layout Model

### Desktop Mode: 4K Cockpit

Desktop mode is implemented as a managed six-pane large-screen cockpit in the `cockpit-desktop` window:

- Main area: two large panes for the two most important active agents or agent + coding shell.
- Right-side stack:
  - agent watch 1
  - agent watch 2
  - agent watch 3
  - bottom-right scratchpad pane for prompt drafting or notes

The intended mental model remains two high-attention agents plus lower-attention watch context. The scratchpad lives in the bottom pane of the right-side stack, inside the `cockpit-desktop` window.

### Laptop Mode: Dual-Agent Windows

Laptop mode uses simple two-pane windows. Each window can hold a pair of OpenCode/Codex sessions. If more than two agents are active, the user switches between additional tmux windows, each of which may also use the dual-agent layout.

Laptop mode optimizes for readability and context, not maximum visible panes.

When `laptop` is applied from a window with more than two panes, the layout helper switches to or creates the dedicated `cockpit-laptop` window, ensures two panes, and applies `even-horizontal`. If the current window has one or two panes, it operates in place.

### Desktop Two-Up Mode: Dedicated Dual-Agent Window

Two-up mode is the desktop override for exactly two agents. When `two-up` is applied from a window with more than two panes, the helper switches to or creates the dedicated `cockpit-two-up` window, ensures two panes, and applies `even-horizontal`. If the current window has one or two panes, it operates in place.

### Mode Selection

Mode should be automatic by terminal/client size, with a manual override:

- Automatic desktop mode for large clients.
- Automatic laptop mode for smaller clients.
- Manual override keybinds to force desktop, force laptop, force two-up, cycle overrides, or apply automatic layout.
- Desktop should also support a simple two-agent side-by-side layout override for times when only two agents need attention.

The same session, windows, and keybinds remain consistent across modes. Only layout application changes.

## Scratchpad

The scratchpad is a first-class cockpit component used for preparing prompts before pasting/sending them to agents. It should be fast to reach and should not require creating a dedicated scratchpad window.

Implemented behavior:

- `Prefix F12` focuses the bottom-right pane in the `cockpit-desktop` window.
- If the desktop window/layout is not active, `Prefix F12` switches to or creates `cockpit-desktop`, applies the desktop layout, then selects that pane.
- No dedicated `cockpit-scratch` window is created. Laptop mode has no dedicated scratchpad behavior for now.

## Keymap Direction

Use prefix-only custom keybinds to avoid conflicts with Hyprland on desktop, KDE Plasma on laptop, shells, editors, and terminal applications.

Implemented cockpit prefix bindings:

- `Prefix F5` — reload `~/.tmux.conf` and display confirmation.
- `Prefix F6` — apply automatic layout using the effective cockpit mode.
- `Prefix F7` — set desktop mode and apply desktop layout.
- `Prefix F8` — set laptop mode and apply laptop layout.
- `Prefix F9` — set two-up mode and apply two-up layout.
- `Prefix F10` — cycle mode override `auto -> desktop -> laptop -> two-up -> auto`, then apply automatic layout.
- `Prefix F11` — jump to next attention window using `next-window -a`.
- `Prefix F12` — focus the bottom-right desktop scratchpad pane.

The keymap should preserve core tmux defaults unless there is a clear benefit and explicit approval.

The live `Prefix v` join-pane and `Prefix b` break-pane helpers are preserved in `~/.tmux.conf`.

## Status Line and Attention Signals

Use a compact adaptive status line. It should always communicate:

- Session/window identity.
- Host via tmux `#h`; richer/proven SSH context remains pending real laptop-over-Tailscale verification.
- Current effective cockpit mode (`desktop`, `laptop`, or `two-up`); the status line does not distinguish automatic mode from a forced override.
- OpenCode waiting markers near affected windows.

The attention model is:

- Keep the visual waiting dot from `@opencode-waiting`.
- Keep/restore tmux `window_bell_flag` behavior so `next-window -a` can jump to waiting agents.
- Add a prefix key for jump-to-next-waiting-agent.
- Use a short, soft Kitty bell sound for non-active agent prompts.
- Avoid desktop notifications for now unless soft sound + visual markers prove insufficient.

## Implementation Constraints

- Do not introduce TPM or a full tmux theme framework in the first pass.
- Treat `~/Projects/tmux-cockpit` as the canonical project folder for docs, scripts, and reproducibility knowledge.
- Keep `.tmux.conf` readable; move layout/scratchpad logic into small helper scripts if needed.
- Preserve the existing `opencode-tmux-indicator` integration rather than forking it immediately.
- Do not rely on `Super`/desktop-reserved key chords inside tmux.
- Keep the design compatible with both local Kitty on Hyprland and SSH-attached laptop clients.

## Verification Plan

Implementation should be verified with:

1. Desktop Kitty local tmux client:
   - desktop layout applies correctly
   - two-agent override works
   - scratchpad is reachable
   - waiting marker appears when OpenCode asks for input
   - soft bell sound is audible and not annoying
   - jump-to-waiting binding works
   - marker clears on focus/resume
2. Laptop over Tailscale SSH:
   - laptop layout applies correctly
   - dual-agent windows remain readable
   - host/SSH context is visible
   - window switching between agent pairs works
   - waiting marker and jump-to-waiting behavior work remotely
3. Regression checks:
   - existing clipboard/OSC52 behavior still works
   - existing join/break pane bindings still work or are intentionally replaced
   - tmux config reloads without errors

## Out of Scope for First Pass

- Full theme framework or TPM adoption.
- Desktop notification daemon integration.
- Forking or modifying `opencode-tmux-indicator` unless current behavior blocks the design.
- A full project/session launcher.
- Cross-terminal support beyond the current Kitty + SSH workflow.
