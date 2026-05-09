# Firefox Wayland Popup Fix Design

## Goal

Make the dotfiles bootstrap preserve the Firefox/Hyprland workaround that fixes extension popup click-through problems on fractional scaling displays.

## Background

On this desktop, Firefox runs as a native Wayland client under Hyprland with monitor scale `1.25` and `input:follow_mouse = 1`. Firefox 150 extension popups can visually appear above the page while pointer input still lands on the page underneath. Setting `widget.wayland.fractional-scale.enabled = false` in Firefox fixes the problem locally.

## Design

Add a focused setup script, `scripts/setup-firefox-wayland.sh`, responsible only for Firefox Wayland compatibility preferences. It will scan `~/.mozilla/firefox` for profile directories, update each profile's `user.js`, and preserve existing unrelated preferences. The script must be idempotent so bootstrap can run repeatedly without duplicating lines.

`scripts/setup-hyprland.sh` will call the Firefox setup script because this preference is tied to the Hyprland fractional-scaling environment. If no Firefox profile exists yet, the script will print a warning telling the user to open Firefox once and rerun it.

## Files

- Create `scripts/setup-firefox-wayland.sh`
- Create `tests/scripts/test_setup_firefox_wayland.sh`
- Modify `scripts/setup-hyprland.sh`

## Error handling

- Missing `~/.mozilla/firefox`: print a warning and exit successfully.
- No profile directories: print a warning and exit successfully.
- Existing matching pref in `user.js`: replace it with the desired value.
- Existing `user.js` without the pref: append the desired value.

## Testing

Use a shell test that runs the setup script against a temporary `HOME`. It verifies new `user.js` creation, replacement of an existing incorrect pref, no duplicate preference lines after repeated runs, and successful warning behavior when no Firefox profile exists.
