#!/bin/bash
# Toggles hyprwhspr between translation mode (Italian->English) and transcription mode (Italian->Italian)

CONFIG_FILE="$HOME/.config/hyprwhspr/config.json"
STATE_FILE="$HOME/.config/hyprwhspr/transcribe_mode"  # true = Italian output, false = English output
ICON_PATH="/usr/lib/hyprwhspr/share/assets/hyprwhspr.png"

get_state() {
    if [[ -f "$STATE_FILE" ]]; then
        cat "$STATE_FILE" 2>/dev/null
    else
        # Check config file
        if [[ -f "$CONFIG_FILE" ]]; then
            local lang
            lang=$(python3 -c "import json; d=json.load(open('$CONFIG_FILE')); print(d.get('language', 'null'))" 2>/dev/null)
            [[ "$lang" == "it" ]] && echo "true" && return
        fi
        echo "false"
    fi
}

set_state() {
    local transcribe_mode="$1"  # true = Italian, false = English
    echo "$transcribe_mode" > "$STATE_FILE"

    python3 - <<PY "$CONFIG_FILE" "$transcribe_mode"
import json, sys
from pathlib import Path
config_path = Path(sys.argv[1])
transcribe_mode = sys.argv[2] == 'true'
try:
    data = json.loads(config_path.read_text()) if config_path.exists() else {}
    if transcribe_mode:
        data['language'] = 'it'  # Transcribe in Italian
    else:
        data['language'] = None  # Auto-detect -> translates to English
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
        if [[ "$current" == "true" ]]; then
            set_state "false"
            notify-send -i "$ICON_PATH" "hyprwhspr" "Translation ON (Italian → English)"
        else
            set_state "true"
            notify-send -i "$ICON_PATH" "hyprwhspr" "Transcription ON (Italian → Italian)"
        fi
        ;;
    "status")
        state=$(get_state)
        if [[ "$state" == "true" ]]; then
            echo "Italian output"
        else
            echo "English output"
        fi
        ;;
    "status-full")
        state=$(get_state)
        if [[ "$state" == "true" ]]; then
            echo "Mode: Transcription (Italian → Italian)"
        else
            echo "Mode: Translation (Italian → English)"
        fi
        ;;
esac
