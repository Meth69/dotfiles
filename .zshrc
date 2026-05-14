# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# Using starship instead of oh-my-zsh themes
ZSH_THEME=""

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  sudo
  command-not-found
  colored-man-pages
  copypath
  copyfile
  history
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Environment variables
export SUDO_ASKPASS=/usr/bin/ksshaskpass
export TERMINAL=kitty
export EDITOR=hx
export OPENCODE_DISABLE_EXTERNAL_SKILLS=1
export OPENCODE_DISABLE_CLAUDE_CODE_PROMPT=1

# Machine-local secrets live outside the dotfiles repo.
# See ~/.config/shell/secrets.zsh.example for setup notes.
if [[ -f "$HOME/.config/shell/secrets.zsh" ]]; then
  source "$HOME/.config/shell/secrets.zsh"
fi

# Initialize starship prompt
eval "$(starship init zsh)"

# Initialize zoxide (smart cd)
eval "$(zoxide init zsh)"
export PATH="$PATH:$HOME/.local/bin"
alias hx='helix'
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles --work-tree=$HOME'

# Normal OpenCode sessions share one local server so OpenChamber can see them.
# OpenCode TUI instances attach to it, while OpenChamber uses it as external backend.
_opencode_shared_server_url="http://127.0.0.1:4096"

_opencode_ensure_shared_server() {
  local _url="http://127.0.0.1:4096"
  local _health="$_url/session"
  local _state_dir="$HOME/.local/state/opencode"

  if ! curl -fsS "$_health" >/dev/null 2>&1; then
    mkdir -p "$_state_dir"
    setsid -f /usr/bin/opencode serve --hostname 127.0.0.1 --port 4096 \
      > "$_state_dir/server-4096.log" 2>&1 < /dev/null

    local _i
    for _i in {1..30}; do
      curl -fsS "$_health" >/dev/null 2>&1 && break
      sleep 0.1
    done
  fi
}

# OpenChamber depends on native packages that currently need Node LTS.
# Keep system Node unchanged, run OpenChamber through fnm's Node 22, and point
# it at the shared OpenCode server instead of spawning a private backend.
openchamber() {
  case "$1" in
    stop|status|logs|update)
      fnm exec --using=22 "$HOME/.local/bin/openchamber" "$@"
      return
      ;;
  esac

  _opencode_ensure_shared_server
  OPENCODE_HOST="$_opencode_shared_server_url" \
    OPENCODE_SKIP_START=true \
    fnm exec --using=22 "$HOME/.local/bin/openchamber" "$@"
}

# Direct subcommands still bypass the wrapper and go to the real binary.
opencode() {
  local _cmd="$1"

  case "$_cmd" in
    completion|acp|mcp|attach|run|debug|providers|auth|agent|upgrade|uninstall|serve|web|models|stats|export|import|github|pr|session|plugin|plug|db)
      /usr/bin/opencode "$@"
      return
      ;;
  esac

  _opencode_ensure_shared_server

  if [[ -n "$1" && "$1" != -* && -e "$1" ]]; then
    local _dir="$1"
    shift
    /usr/bin/opencode attach "$_opencode_shared_server_url" --dir "$_dir" "$@"
  else
    /usr/bin/opencode attach "$_opencode_shared_server_url" "$@"
  fi
}

_OPENCODE_CONFIG="$HOME/.config/opencode/oh-my-opencode-slim.json"
_OPENCODE_CORE="$HOME/.config/opencode/opencode.json"
openglm() {
  local _tmpdir
  _tmpdir=$(mktemp -d)
  {
    cp -r "$HOME/.config/opencode" "$_tmpdir/opencode"
    sed -i 's/"preset": "openai"/"preset": "glm"/' "$_tmpdir/opencode/oh-my-opencode-slim.json"
    jq '.agent.plan.model = "zai-coding-plan/glm-5.1"' "$_tmpdir/opencode/opencode.json" > "$_tmpdir/opencode/opencode.json.tmp" && mv "$_tmpdir/opencode/opencode.json.tmp" "$_tmpdir/opencode/opencode.json"
    XDG_CONFIG_HOME="$_tmpdir" /usr/bin/opencode "$@"
  } always {
    rm -rf "$_tmpdir"
  }
}
