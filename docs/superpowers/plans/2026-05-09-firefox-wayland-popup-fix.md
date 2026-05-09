# Firefox Wayland Popup Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an idempotent dotfiles bootstrap hook that disables Firefox native Wayland fractional scaling to avoid extension popup click-through bugs under Hyprland.

**Architecture:** A dedicated Firefox Wayland setup script owns Firefox profile preference updates. The existing Hyprland setup script calls it after GTK/Qt theming because the workaround is specific to the Hyprland Wayland session.

**Tech Stack:** Bash, Firefox `user.js`, bare git dotfiles repo at `~/.dotfiles`.

---

### Task 1: Firefox Wayland setup script

**Files:**
- Create: `scripts/setup-firefox-wayland.sh`
- Test: `tests/scripts/test_setup_firefox_wayland.sh`

- [ ] **Step 1: Write the failing shell test**

Create `tests/scripts/test_setup_firefox_wayland.sh` with assertions that run `scripts/setup-firefox-wayland.sh` against a temporary `HOME`. The test covers creating `user.js`, replacing an existing `true` preference with `false`, avoiding duplicate pref lines after a second run, and warning successfully when Firefox has no profile yet.

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/scripts/test_setup_firefox_wayland.sh`

Expected: FAIL because `scripts/setup-firefox-wayland.sh` does not exist yet.

- [ ] **Step 3: Write minimal implementation**

Create `scripts/setup-firefox-wayland.sh` that:

```bash
#!/bin/bash
set -euo pipefail

pref_name="widget.wayland.fractional-scale.enabled"
pref_line='user_pref("widget.wayland.fractional-scale.enabled", false);'
firefox_dir="$HOME/.mozilla/firefox"

echo "🦊 Configuring Firefox Wayland compatibility..."

if [ ! -d "$firefox_dir" ]; then
    echo "⚠️  Firefox profile directory not found. Open Firefox once, then run: ~/scripts/setup-firefox-wayland.sh"
    exit 0
fi

shopt -s nullglob
profiles=("$firefox_dir"/*.default "$firefox_dir"/*.default-* "$firefox_dir"/*.default-release)
shopt -u nullglob

if [ ${#profiles[@]} -eq 0 ]; then
    echo "⚠️  Firefox profile not found. Open Firefox once, then run: ~/scripts/setup-firefox-wayland.sh"
    exit 0
fi

updated=0
for profile in "${profiles[@]}"; do
    [ -d "$profile" ] || continue
    user_js="$profile/user.js"
    touch "$user_js"

    if grep -q "user_pref(\"$pref_name\"" "$user_js"; then
        tmp="$(mktemp)"
        sed "s|^user_pref(\"$pref_name\".*|$pref_line|" "$user_js" > "$tmp"
        mv "$tmp" "$user_js"
    else
        printf '\n%s\n' "$pref_line" >> "$user_js"
    fi

    echo "✅ Firefox Wayland fractional scaling disabled in $user_js"
    updated=$((updated + 1))
done

if [ "$updated" -eq 0 ]; then
    echo "⚠️  Firefox profile not found. Open Firefox once, then run: ~/scripts/setup-firefox-wayland.sh"
fi
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/scripts/test_setup_firefox_wayland.sh`

Expected: PASS.

### Task 2: Hyprland setup hook

**Files:**
- Modify: `scripts/setup-hyprland.sh`

- [ ] **Step 1: Add the hook**

At the end of `scripts/setup-hyprland.sh`, call:

```bash
bash "$HOME/scripts/setup-firefox-wayland.sh"
```

- [ ] **Step 2: Verify script syntax**

Run: `bash -n scripts/setup-hyprland.sh scripts/setup-firefox-wayland.sh tests/scripts/test_setup_firefox_wayland.sh`

Expected: no output and exit code 0.

### Task 3: Commit and push

**Files:**
- Review all dotfiles repo changes, including pre-existing dirty files.

- [ ] **Step 1: Inspect status and diff**

Run: `git --git-dir=$HOME/.dotfiles --work-tree=$HOME status --short` and `git --git-dir=$HOME/.dotfiles --work-tree=$HOME diff`.

- [ ] **Step 2: Commit all intended tracked and new files**

Stage relevant files explicitly, including the new Firefox setup script and test, the Hyprland hook, and any user-requested pre-existing dirty dotfiles changes that should be included so the bare repo is clean.

- [ ] **Step 3: Push**

Run: `git --git-dir=$HOME/.dotfiles --work-tree=$HOME push`.
