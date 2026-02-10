#!/bin/bash
# Claude-GLM Server-Friendly Installer
# Works without sudo, installs to user's home directory

# Configuration
USER_BIN_DIR="$HOME/.local/bin"
GLM_CONFIG_DIR="$HOME/.claude-glm"
GLM_FAST_CONFIG_DIR="$HOME/.claude-glm-fast"
ZAI_API_KEY="YOUR_ZAI_API_KEY_HERE"

# Detect shell and rc file
detect_shell_rc() {
    local shell_name=$(basename "$SHELL")
    local rc_file=""
    
    case "$shell_name" in
        bash)
            rc_file="$HOME/.bashrc"
            [ -f "$HOME/.bash_profile" ] && rc_file="$HOME/.bash_profile"
            ;;
        zsh)
            rc_file="$HOME/.zshrc"
            ;;
        ksh)
            rc_file="$HOME/.kshrc"
            [ -f "$HOME/.profile" ] && rc_file="$HOME/.profile"
            ;;
        csh|tcsh)
            rc_file="$HOME/.cshrc"
            ;;
        *)
            rc_file="$HOME/.profile"
            ;;
    esac
    
    echo "$rc_file"
}

# Ensure user bin directory exists and is in PATH
setup_user_bin() {
    # Create user bin directory
    mkdir -p "$USER_BIN_DIR"
    
    local rc_file=$(detect_shell_rc)
    
    # Check if PATH includes user bin
    if [[ ":$PATH:" != *":$USER_BIN_DIR:"* ]]; then
        echo "📝 Adding $USER_BIN_DIR to PATH in $rc_file"
        
        # Add to PATH based on shell type
        if [[ "$rc_file" == *".cshrc" ]]; then
            echo "setenv PATH \$PATH:$USER_BIN_DIR" >> "$rc_file"
        else
            echo "export PATH=\"\$PATH:$USER_BIN_DIR\"" >> "$rc_file"
        fi
        
        echo "⚠️  IMPORTANT: Run this after installation to update PATH:"
        echo "   source $rc_file"
    fi
}

# Create the standard glm-4.7 wrapper
create_claude_glm_wrapper() {
    local wrapper_path="$USER_BIN_DIR/claude-glm"
    
    cat > "$wrapper_path" << EOF
#!/bin/bash
# Claude-GLM - Claude Code with Z.AI glm-4.7  (Standard Model)

# Set Z.AI environment variables
export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"
export ANTHROPIC_AUTH_TOKEN="$ZAI_API_KEY"
export ANTHROPIC_MODEL="glm-4.7"
export ANTHROPIC_SMALL_FAST_MODEL="glm-4.5-air"

# Use custom config directory to avoid conflicts
export CLAUDE_HOME="\$HOME/.claude-glm"

# Create config directory if it doesn't exist
mkdir -p "\$CLAUDE_HOME"

# Create/update settings file with GLM configuration
cat > "\$CLAUDE_HOME/settings.json" << SETTINGS
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://api.z.ai/api/anthropic",
    "ANTHROPIC_AUTH_TOKEN": "$ZAI_API_KEY",
    "ANTHROPIC_MODEL": "glm-4.7",
    "ANTHROPIC_SMALL_FAST_MODEL": "glm-4.5-air"
  }
}
SETTINGS

# Launch Claude Code with custom config
echo "🚀 Starting Claude Code with glm-4.7 (Standard Model)..."
echo "📁 Config directory: \$CLAUDE_HOME"
echo ""

# Check if claude exists
if ! command -v claude &> /dev/null; then
    echo "❌ Error: 'claude' command not found!"
    echo "Please ensure Claude Code is installed and in your PATH"
    exit 1
fi

# Run the actual claude command
claude "\$@"
EOF
    
    chmod +x "$wrapper_path"
    echo "✅ Installed claude-glm at $wrapper_path"
}

# Create the fast glm-4.5-air wrapper
create_claude_glm_fast_wrapper() {
    local wrapper_path="$USER_BIN_DIR/claude-glm-fast"
    
    cat > "$wrapper_path" << EOF
#!/bin/bash
# Claude-GLM-Fast - Claude Code with Z.AI glm-4.5-air (Fast Model)

# Set Z.AI environment variables
export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"
export ANTHROPIC_AUTH_TOKEN="$ZAI_API_KEY"
export ANTHROPIC_MODEL="glm-4.5-air"
export ANTHROPIC_SMALL_FAST_MODEL="glm-4.5-air"

# Use custom config directory to avoid conflicts
export CLAUDE_HOME="\$HOME/.claude-glm-fast"

# Create config directory if it doesn't exist
mkdir -p "\$CLAUDE_HOME"

# Create/update settings file with GLM-Air configuration
cat > "\$CLAUDE_HOME/settings.json" << SETTINGS
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://api.z.ai/api/anthropic",
    "ANTHROPIC_AUTH_TOKEN": "$ZAI_API_KEY",
    "ANTHROPIC_MODEL": "glm-4.5-air",
    "ANTHROPIC_SMALL_FAST_MODEL": "glm-4.5-air"
  }
}
SETTINGS

# Launch Claude Code with custom config
echo "⚡ Starting Claude Code with glm-4.5-air (Fast Model)..."
echo "📁 Config directory: \$CLAUDE_HOME"
echo ""

# Check if claude exists
if ! command -v claude &> /dev/null; then
    echo "❌ Error: 'claude' command not found!"
    echo "Please ensure Claude Code is installed and in your PATH"
    exit 1
fi

# Run the actual claude command
claude "\$@"
EOF
    
    chmod +x "$wrapper_path"
    echo "✅ Installed claude-glm-fast at $wrapper_path"
}

# Create the Anthropic wrapper
create_claude_anthropic_wrapper() {
    local wrapper_path="$USER_BIN_DIR/claude-anthropic"
    
    cat > "$wrapper_path" << 'EOF'
#!/bin/bash
# Claude-Anthropic - Claude Code with original Anthropic models

# Clear any Z.AI environment variables
unset ANTHROPIC_BASE_URL
unset ANTHROPIC_AUTH_TOKEN
unset ANTHROPIC_MODEL
unset ANTHROPIC_SMALL_FAST_MODEL

# Use default Claude config directory
unset CLAUDE_HOME

echo "🚀 Starting Claude Code with Anthropic Claude models..."
echo ""

# Check if claude exists
if ! command -v claude &> /dev/null; then
    echo "❌ Error: 'claude' command not found!"
    echo "Please ensure Claude Code is installed and in your PATH"
    exit 1
fi

# Run the actual claude command
claude "$@"
EOF
    
    chmod +x "$wrapper_path"
    echo "✅ Installed claude-anthropic at $wrapper_path"
}

# Create shell aliases
create_shell_aliases() {
    local rc_file=$(detect_shell_rc)
    
    if [ -z "$rc_file" ] || [ ! -f "$rc_file" ]; then
        echo "⚠️  Could not detect shell rc file, skipping aliases"
        return
    fi
    
    # Remove old aliases if they exist
    if grep -q "# Claude Code Model Switcher Aliases" "$rc_file" 2>/dev/null; then
        # Use temp file for compatibility
        grep -v "# Claude Code Model Switcher Aliases" "$rc_file" | \
        grep -v "alias cc=" | \
        grep -v "alias ccg=" | \
        grep -v "alias ccf=" | \
        grep -v "alias cca=" > "$rc_file.tmp"
        mv "$rc_file.tmp" "$rc_file"
    fi
    
    # Add aliases based on shell type
    if [[ "$rc_file" == *".cshrc" ]]; then
        cat >> "$rc_file" << 'EOF'

# Claude Code Model Switcher Aliases
alias cc 'claude'
alias ccg 'claude-glm'
alias ccf 'claude-glm-fast'
alias cca 'claude-anthropic'
EOF
    else
        cat >> "$rc_file" << 'EOF'

# Claude Code Model Switcher Aliases
alias cc='claude'
alias ccg='claude-glm'
alias ccf='claude-glm-fast'
alias cca='claude-anthropic'
EOF
    fi
    
    echo "✅ Added aliases to $rc_file"
}

# Check Claude Code availability
check_claude_installation() {
    echo "🔍 Checking Claude Code installation..."
    
    if command -v claude &> /dev/null; then
        echo "✅ Claude Code found at: $(which claude)"
        return 0
    else
        echo "⚠️  Claude Code not found in PATH"
        echo ""
        echo "Options:"
        echo "1. If Claude Code is installed elsewhere, add it to PATH first"
        echo "2. Install Claude Code from: https://www.anthropic.com/claude-code"
        echo "3. Continue anyway (wrappers will be created but won't work until claude is available)"
        echo ""
        read -p "Continue with installation? (y/n): " continue_choice
        if [[ "$continue_choice" != "y" && "$continue_choice" != "Y" ]]; then
            echo "Installation cancelled."
            exit 1
        fi
        return 1
    fi
}

# Main installation
main() {
    echo "🔧 Claude-GLM Server-Friendly Installer"
    echo "========================================"
    echo ""
    echo "This installer:"
    echo "  • Does NOT require sudo/root access"
    echo "  • Installs to: $USER_BIN_DIR"
    echo "  • Works on Unix/Linux servers"
    echo ""
    
    # Check Claude Code
    check_claude_installation
    
    # Setup user bin directory
    setup_user_bin
    
    # Check if already installed
    if [ -f "$USER_BIN_DIR/claude-glm" ] || [ -f "$USER_BIN_DIR/claude-glm-fast" ]; then
        echo ""
        echo "✅ Existing installation detected!"
        echo "1) Update API key only"
        echo "2) Reinstall everything"
        echo "3) Cancel"
        read -p "Choice (1-3): " update_choice
        
        case "$update_choice" in
            1)
                read -p "Enter your Z.AI API key: " input_key
                if [ -n "$input_key" ]; then
                    ZAI_API_KEY="$input_key"
                    create_claude_glm_wrapper
                    create_claude_glm_fast_wrapper
                    echo "✅ API key updated!"
                    exit 0
                fi
                ;;
            2)
                echo "Reinstalling..."
                ;;
            *)
                exit 0
                ;;
        esac
    fi
    
    # Get API key
    echo ""
    echo "Enter your Z.AI API key (from https://z.ai/manage-apikey/apikey-list)"
    read -p "API Key: " input_key
    
    if [ -n "$input_key" ]; then
        ZAI_API_KEY="$input_key"
        echo "✅ API key received (${#input_key} characters)"
    else
        echo "⚠️  No API key provided. Add it manually later to:"
        echo "   $USER_BIN_DIR/claude-glm"
        echo "   $USER_BIN_DIR/claude-glm-fast"
    fi
    
    # Create wrappers
    create_claude_glm_wrapper
    create_claude_glm_fast_wrapper
    create_claude_anthropic_wrapper
    create_shell_aliases
    
    # Final instructions
    local rc_file=$(detect_shell_rc)
    
    echo ""
    echo "✅ Installation complete!"
    echo ""
    echo "📝 Next steps:"
    echo ""
    echo "1. Update your PATH (REQUIRED):"
    echo "   source $rc_file"
    echo ""
    echo "2. Available commands:"
    echo "   claude-glm      - glm-4.7 (standard)"
    echo "   claude-glm-fast - glm-4.5-air (fast)"
    echo "   claude-anthropic - Original Claude"
    echo ""
    echo "3. Aliases (after sourcing):"
    echo "   ccg - claude-glm"
    echo "   ccf - claude-glm-fast"
    echo "   cca - claude-anthropic"
    echo ""
    
    if [ "$ZAI_API_KEY" = "YOUR_ZAI_API_KEY_HERE" ]; then
        echo "⚠️  Don't forget to add your API key to:"
        echo "   $USER_BIN_DIR/claude-glm"
        echo "   $USER_BIN_DIR/claude-glm-fast"
    fi
    
    echo ""
    echo "📁 Installation location: $USER_BIN_DIR"
    echo "📁 Config directories: ~/.claude-glm and ~/.claude-glm-fast"
}

# Run installation
main "$@"
