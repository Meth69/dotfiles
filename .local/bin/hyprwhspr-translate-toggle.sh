#!/bin/bash
# Cycles hyprwhspr between English translation, Italian transcription, and Persian transcription.

CONFIG_FILE="$HOME/.config/hyprwhspr/config.json"
STATE_FILE="$HOME/.config/hyprwhspr/transcribe_mode"
ICON_PATH="/usr/lib/hyprwhspr/share/assets/hyprwhspr.png"

normalize_state() {
    case "${1:-}" in
        "true"|"italian"|"it") echo "italian" ;;
        "persian"|"farsi"|"fa") echo "persian" ;;
        "false"|"english"|"translation"|"") echo "english" ;;
        *) echo "english" ;;
    esac
}

get_state() {
    if [[ -f "$STATE_FILE" ]]; then
        normalize_state "$(cat "$STATE_FILE" 2>/dev/null)"
    else
        # Check config file
        if [[ -f "$CONFIG_FILE" ]]; then
            local lang
            lang=$(python3 -c "import json; d=json.load(open('$CONFIG_FILE')); print(d.get('language', 'null'))" 2>/dev/null)
            [[ "$lang" == "it" ]] && echo "italian" && return
            [[ "$lang" == "fa" ]] && echo "persian" && return
        fi
        echo "english"
    fi
}

set_state() {
    local mode
    mode=$(normalize_state "$1")
    mkdir -p "$(dirname "$STATE_FILE")"
    echo "$mode" > "$STATE_FILE"

    python3 - <<PY "$CONFIG_FILE" "$mode"
import json, sys
from pathlib import Path
config_path = Path(sys.argv[1])
mode = sys.argv[2]
try:
    data = json.loads(config_path.read_text()) if config_path.exists() else {}
    if mode == 'italian':
        data['language'] = 'it'
        data['task'] = 'transcribe'
    elif mode == 'persian':
        data['language'] = 'fa'
        data['task'] = 'transcribe'
        data['whisper_prompt_fa'] = 'Transcribe in Persian script only. Do not transliterate into Latin letters.'
    else:
        data['language'] = None
        data.pop('task', None)
    config_path.write_text(json.dumps(data, indent=2))
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
PY

    systemctl --user restart hyprwhspr.service 2>/dev/null
}

case "${1:-toggle}" in
    "toggle")
        current=$(get_state)
        case "$current" in
            "english")
                set_state "italian"
                notify-send -i "$ICON_PATH" "hyprwhspr" "Italian transcription ON"
                ;;
            "italian")
                set_state "persian"
                notify-send -i "$ICON_PATH" "hyprwhspr" "Persian transcription ON"
                ;;
            *)
                set_state "english"
                notify-send -i "$ICON_PATH" "hyprwhspr" "English translation ON"
                ;;
        esac
        ;;
    "status")
        state=$(get_state)
        case "$state" in
            "italian") echo "Italian output" ;;
            "persian") echo "Persian output" ;;
            *) echo "English translation" ;;
        esac
        ;;
    "status-full")
        state=$(get_state)
        case "$state" in
            "italian") echo "Mode: Transcription (Italian → Italian)" ;;
            "persian") echo "Mode: Transcription (Persian script)" ;;
            *) echo "Mode: Translation (English output)" ;;
        esac
        ;;
esac
