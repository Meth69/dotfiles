#!/bin/bash
# Wrapper for hyprwhspr tray script that adds translation state to tooltip
# This survives package updates since it's in user space

ORIGINAL_SCRIPT="/usr/lib/hyprwhspr/config/hyprland/hyprwhspr-tray.sh"
TOGGLE_SCRIPT="$HOME/.local/bin/hyprwhspr-translate-toggle.sh"

# Get the original output
original_output=$("$ORIGINAL_SCRIPT" "$@" 2>/dev/null)

if [[ -z "$original_output" ]]; then
    echo "$original_output"
    exit 0
fi

# Get translation state
trans_state=""
if [[ -x "$TOGGLE_SCRIPT" ]]; then
    trans_state=$("$TOGGLE_SCRIPT" status 2>/dev/null)
fi

# If no translation state or not JSON, pass through unchanged
if [[ -z "$trans_state" ]] || [[ "$original_output" != "{"* ]]; then
    echo "$original_output"
    exit 0
fi

# Modify the JSON to update tooltip
python3 - <<PY "$original_output" "$trans_state"
import json, sys
try:
    data = json.loads(sys.argv[1])
    trans_state = sys.argv[2]

    if 'tooltip' in data:
        # Replace "Right-click: Restart service" with translation toggle info
        tooltip = data['tooltip']
        tooltip = tooltip.replace('Right-click: Restart service', f'Right-click: Toggle translation ({trans_state})')

        # Also add translation state on a new line before the right-click instruction
        # Find where right-click line is and add translation state before it
        lines = tooltip.split('\\n')
        new_lines = []
        for line in lines:
            if line.startswith('Right-click:'):
                new_lines.append(f'Translation: {trans_state}')
            new_lines.append(line)
        data['tooltip'] = '\\n'.join(new_lines)

    print(json.dumps(data))
except Exception:
    # On error, output original
    print(sys.argv[1])
PY
