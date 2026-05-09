#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
zshrc="$repo_root/.zshrc"
example="$repo_root/.config/shell/secrets.zsh.example"
ignore="$repo_root/.gitignore"

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

assert_contains() {
    local file="$1"
    local text="$2"
    grep -Fq "$text" "$file" || fail "$file should contain: $text"
}

assert_not_contains_regex() {
    local file="$1"
    local regex="$2"
    if grep -Eq "$regex" "$file"; then
        fail "$file should not match regex: $regex"
    fi
}

[ -f "$zshrc" ] || fail ".zshrc is missing"
[ -f "$example" ] || fail "secrets.zsh.example is missing"

assert_contains "$zshrc" 'source "$HOME/.config/shell/secrets.zsh"'
assert_not_contains_regex "$zshrc" 'alias ccg='
assert_not_contains_regex "$zshrc" 'ANTHROPIC_AUTH_TOKEN='
assert_not_contains_regex "$zshrc" 'ZHIPUAI_API_KEY="?[A-Za-z0-9]{16,}\.'
assert_not_contains_regex "$zshrc" 'HF_TOKEN="?hf_[A-Za-z0-9]+'

assert_contains "$example" 'ZHIPUAI_API_KEY'
assert_contains "$example" 'HF_TOKEN'
assert_contains "$example" 'ANTHROPIC_AUTH_TOKEN'
assert_contains "$example" 'retired with the old Claude Code ccg alias'
assert_contains "$ignore" '/.config/shell/secrets.zsh'

echo "PASS: shell cleanup"
