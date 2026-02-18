#!/bin/bash
# Setup Claude Code configuration

set -e

CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings-glm.json"

echo "🔧 Setting up Claude Code configuration..."

# Create .claude directory if it doesn't exist
mkdir -p "$CLAUDE_DIR"

# Create settings-glm.json if it doesn't exist
if [ ! -f "$SETTINGS_FILE" ]; then
    cat > "$SETTINGS_FILE" << 'EOF'
{
  "env": {
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "glm-4.5-air",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "glm-4.7",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "glm-5"
  }
}
EOF
    echo "✅ Created $SETTINGS_FILE"
else
    echo "✅ $SETTINGS_FILE already exists"
fi
