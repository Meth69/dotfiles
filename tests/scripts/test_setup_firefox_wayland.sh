#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
script="$repo_root/scripts/setup-firefox-wayland.sh"
pref='user_pref("widget.wayland.fractional-scale.enabled", false);'

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

assert_contains_once() {
    local file="$1"
    local expected="$2"
    local count
    count="$(grep -Fxc "$expected" "$file" || true)"
    [ "$count" = "1" ] || fail "$file should contain exactly one '$expected' line, found $count"
}

tmp_home="$(mktemp -d)"
trap 'rm -rf "$tmp_home"' EXIT

profile="$tmp_home/.mozilla/firefox/example.default-release"
mkdir -p "$profile"

HOME="$tmp_home" bash "$script" >/tmp/setup-firefox-wayland-test.out
assert_contains_once "$profile/user.js" "$pref"

HOME="$tmp_home" bash "$script" >/tmp/setup-firefox-wayland-test.out
assert_contains_once "$profile/user.js" "$pref"

printf '%s\n' 'user_pref("widget.wayland.fractional-scale.enabled", true);' > "$profile/user.js"
HOME="$tmp_home" bash "$script" >/tmp/setup-firefox-wayland-test.out
assert_contains_once "$profile/user.js" "$pref"
if grep -Fq 'user_pref("widget.wayland.fractional-scale.enabled", true);' "$profile/user.js"; then
    fail "existing true preference should be replaced"
fi

rm -rf "$tmp_home/.mozilla/firefox"
HOME="$tmp_home" bash "$script" > /tmp/setup-firefox-wayland-test.out
if ! grep -Fq "Firefox profile directory not found" /tmp/setup-firefox-wayland-test.out; then
    fail "missing Firefox directory should print a warning"
fi

echo "PASS: setup-firefox-wayland"
