# ~/.zshrc
# Interactive Zsh configuration for macOS / Apple Silicon.
#
# Principles:
# - Homebrew installed in /opt/homebrew
# - PATH entries added only for existing directories
# - NVM loaded lazily
# - Zsh completions cached
# - Prompt with Git status and Python environment
#
# shellcheck shell=bash
# shellcheck disable=SC2296,SC2206,SC2207,SC2016,SC2034,SC1091,SC1036
# ^ zsh-specific expansions, arrays from command output, prompts, sourced files
# Guide: https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html

# ─── Zsh Options ───────────────────────────────────────────────────

setopt prompt_subst         # Required to evaluate $(...) inside PROMPT
setopt no_beep              # Disable shell beeps
setopt autocd               # Enter directories without typing "cd"
setopt correct              # Correct command typos
setopt interactive_comments # Allow comments on the command line
setopt hist_ignore_dups     # Ignore duplicate history entries
setopt share_history        # Share history between terminal sessions
setopt inc_append_history
setopt hist_ignore_space
setopt hist_verify

# ─── Environment ───────────────────────────────────────────────────

# Use Java 21 if installed; fail silently if unavailable
if JAVA_HOME=$(/usr/libexec/java_home -v 21 2>/dev/null); then
  export JAVA_HOME
fi

# Prevent virtualenv activation scripts from modifying the left prompt
export VIRTUAL_ENV_DISABLE_PROMPT=1

export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
export GOPATH="$HOME/.cache/go"
export GOMODCACHE="$GOPATH/pkg/mod"

# Install Homebrew casks for this user instead of /Applications
export HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications"

# ─── PATH management ───────────────────────────────────────────────

# Prepend a directory to PATH only if:
# - it is not empty;
# - it exists;
# - it is not already present.

path_prepend() {
  [[ -n "$1" && -d "$1" ]] || return

  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1:$PATH" ;;
  esac
}

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Add important paths (in priority order)
path_prepend "$HOME/.local/bin"
path_prepend "$JAVA_HOME/bin"
path_prepend "$HOME/Applications/MATLAB_R2024b.app/bin"
path_prepend "$ANDROID_SDK_ROOT/platform-tools"
path_prepend "$ANDROID_SDK_ROOT/emulator"
path_prepend "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin"

# ─── Completion System ─────────────────────────────────────────────

# Completion cache:
# - rebuilt if missing or if ~/.zshrc is newer;
# - automatically removed after 30 days;
# - otherwise compinit -C skips unnecessary checks.

autoload -Uz compinit

ZCOMPDUMP="${ZDOTDIR:-$HOME}/.zcompdump"

refresh_old_compdump() {
  if [[ -f "$ZCOMPDUMP" ]]; then
    local lastmod
    lastmod=$(stat -f "%m" "$ZCOMPDUMP")
    local now
    now=$(date +%s)
    local age=$(( (now - lastmod) / 86400 )) # Age in days

    if (( age > 30 )); then
      echo "🧹 Cleaning completion cache (older than 30 days)..."
      rm -f "$ZCOMPDUMP"
    fi
  fi
}

refresh_old_compdump

if [[ ! -f "$ZCOMPDUMP" || "$ZCOMPDUMP" -ot "$HOME/.zshrc" ]]; then
  compinit -d "$ZCOMPDUMP"
else
  compinit -C -d "$ZCOMPDUMP"
fi

if command -v register-python-argcomplete >/dev/null 2>&1; then
  eval "$(register-python-argcomplete pipx)"
fi

# ─── Node.js / NVM ─────────────────────────────────────────────────

# NVM is relatively slow to initialize, so it is loaded only on the
# first use of nvm/node/npm/npx.
#
# - `nvm ...` loads NVM without requiring a default Node.js version.
# - `node`, `npm`, and `npx` load NVM and activate the `default` version.

# NVM - Lazy Loading
export NVM_DIR="$HOME/.nvm"

load_nvm() {
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && . "/opt/homebrew/opt/nvm/nvm.sh"
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && . "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
}

_nvm_lazy_load() {
  unset -f nvm node npm npx
  load_nvm

  if ! typeset -f nvm >/dev/null; then
    echo "❌ Unable to load NVM." >&2
    return 127
  fi
}

_nvm_use_default() {
  _nvm_lazy_load || return

  nvm use --silent default >/dev/null || {
    echo "⚠️ No default Node.js version is configured." >&2
    return 127
  }
}

nvm() {
  _nvm_lazy_load || return
  nvm "$@"
}

node() {
  _nvm_use_default || return
  node "$@"
}

npm() {
  _nvm_use_default || return
  npm "$@"
}

npx() {
  _nvm_use_default || return
  npx "$@"
}

# Show whether NVM has already been loaded
nvmstatus() {
  if typeset -f nvm | grep -q '_nvm_lazy_load'; then
    echo "🟡 NVM lazy loading active (not loaded yet)"
  elif typeset -f nvm >/dev/null; then
    echo "🟢 NVM operational (already loaded)"
  else
    echo "🔴 NVM is not defined"
  fi
}

# ─── Git Prompt ────────────────────────────────────────────────────

# Example:
#   git:(main +!?*)↓2/↑1
#
# Working tree status:
#   +  staged changes
#   !  unstaged changes
#   ?  untracked files
#   *  stash present
#   ✗  conflicts
#
# Upstream status:
#   ↓N commits behind
#   ↑N commits ahead

git_branch() {
  local git_output
  git_output=$(git status --porcelain=v2 --branch --show-stash 2>/dev/null) || return

  local branch="HEAD"
  local ahead=0
  local behind=0
  local staged=0
  local unstaged=0
  local untracked=0
  local conflicted=0
  local stash=0

  local line xy

  while IFS= read -r line; do
    case "$line" in
      "# branch.head "*)
        branch="${line#\# branch.head }"
        [[ "$branch" == "(detached)" ]] && branch="HEAD"
        ;;

      "# branch.ab "*)
        # Format: "# branch.ab +2 -3"
        local ab="${line#\# branch.ab }"
        ahead="${${ab%% *}#+}"
        behind="${${ab##* }#-}"
        ;;
      
      "# stash "*)
        [[ "${line#\# stash }" -gt 0 ]] && stash=1
        ;;

      "1 "*|"2 "*)
        # XY are the two status characters after the record type.
        xy="${${(z)line}[2]}"

        [[ "${xy[1]}" != "." ]] && staged=1
        [[ "${xy[2]}" != "." ]] && unstaged=1
        ;;

      "u "*)
        conflicted=1
        ;;

      "? "*)
        untracked=1
        ;;
    esac
  done <<< "$git_output"

  local git_status=""
  local git_status_color=46

  (( staged ))     && git_status+="+"
  (( unstaged ))   && git_status+="!"
  (( untracked ))  && git_status+="?"
  (( stash ))      && git_status+="*"
  (( conflicted )) && git_status+="✗"

  if [[ -n "$git_status" ]]; then
    git_status_color=196
    git_status=" $git_status"
  fi

  local commit_status=""

  if (( behind > 0 && ahead > 0 )); then
    commit_status="%F{72}↓${behind}%f%F{66}/%f%F{72}↑${ahead}%f"
  else
    (( behind > 0 )) && commit_status="%F{72}↓${behind}%f"
    (( ahead > 0 ))  && commit_status="%F{72}↑${ahead}%f"
  fi

  echo " on %B%F{66}git:(%f%F{$git_status_color}${branch}${git_status}%f%F{66})%f${commit_status}%b"
}

# ─── Python Environments ───────────────────────────────────────────

python_env() {
  if [[ -n "$VIRTUAL_ENV" ]]; then
    echo "[%B%F{39}venv:%f%F{81} $(basename "$VIRTUAL_ENV")%f%b]"
    return
  fi

  if command -v poetry &>/dev/null && [[ -f pyproject.toml ]]; then
    local env
    env=$(poetry env info --path 2>/dev/null)
    if [[ -n "$env" ]]; then
      echo "[%B%F{208}poetry:%f%F{214} $(basename "$env")%f%b]"
    fi
  fi
}

mkvenv() {
  python3 -m venv .venv && source .venv/bin/activate && python3 -m pip -q install -U pip wheel setuptools;
}

workon() {
  [ -d .venv ] && source .venv/bin/activate || echo "No .venv found here."
}


# ─── Prompt ────────────────────────────────────────────────────────

# Left prompt: user, host, directory, Git status, and optional exit status.
PROMPT=$'%(?..Exit status: %B%F{196}%?%f%b\n)[%B%F{201}%n%f%b at %B%F{81}%m%f%b in %B%F{214}%~%f%b$(git_branch)]%# '

# Right prompt: Python virtualenv or Poetry environment.
RPROMPT='$(python_env)'

# ─── Utility Functions ─────────────────────────────────────────────

# Validate ~/.zshrc before replacing the current shell.
# If validation fails, keep the current working shell intact.
reload() {
  if zsh -n "$HOME/.zshrc"; then
    echo "🔄 ~/.zshrc is valid. Reloading... (Last modified: $(date -r "$HOME/.zshrc" '+%Y-%m-%d %H:%M:%S'))"
    # printf '\a' # enable for BEEP
    exec zsh
  else
    echo "❌ ~/.zshrc contains errors: reload aborted." >&2
    return 1
  fi
}

f() {
  find . -iname "*$1*" 2>/dev/null
}

check_bin() {
  if command -v "$1" &>/dev/null; then
    echo "✅ $1: $(command -v "$1")"
  else
    echo "❌ $1: not found"
  fi
}

check_env_info() {
  echo "📦 pip:"
  check_bin pip
  pip --version 2>/dev/null

  echo ""
  echo "📦 pip3:"
  check_bin pip3
  pip3 --version

  echo ""
  echo "🐍 python3:"
  check_bin python3
  python3 --version

  echo ""
  echo "☕ java:"
  check_bin java
  java -version 2>&1 | head -n 1

  echo ""
  echo "🛠️  javac:"
  check_bin javac
  javac -version

  echo ""
  echo "🧠 JAVA_HOME:"
  echo "$JAVA_HOME"

  echo ""
  echo "🧮 MATLAB:"
  check_bin matlab

  echo ""
  echo "🔍 Current PATH:"
  echo "$PATH" | tr ':' '\n'
}

pdfkeep() {

  if [[ $# -eq 1 && "$1" == "--help" ]]; then
    echo "Usage: pdfkeep <input.pdf> <pages_to_keep> [output.pdf]"
    echo ""
    echo "Page ranges:"
    echo " - Single range: 2-5 (pages 2 through 5)"
    echo " - To the end: 3- or 3-z"
    echo " - From the beginning: -5 or 1-5"
    echo " - Multiple ranges: \"1-3, 5-7, 9-z\""
    echo ""
    echo "Examples:"
    echo "  pdfkeep file.pdf 2-5 output.pdf"
    echo "  pdfkeep file.pdf \"1-3,5-7,9-z\" output.pdf"
    return 0
  fi

  if [[ $# -lt 2 ]]; then
    echo "Usage: pdfkeep <input.pdf> <pages_to_keep> [output.pdf]"
    echo "If ranges contain spaces, enclose the entire argument in quotes."
    echo "Example: pdfkeep file.pdf \"1-3, 5-7, 9-z\" file2.pdf"
    return 1
  fi

  local input="$1"
  local pages_raw="$2"
  local output="$3"
  local -a corrected_pages

  if [[ ! -f "$input" ]]; then
    echo "Error: input file '$input' not found."
    return 1
  fi

  # Split manually on commas
  for part in ${(s:,:)pages_raw}; do
    part="${part// /}"  # Remove spaces from each item, NOT from the entire string

    # Skip empty items
    [[ -z "$part" ]] && continue

    # Normalize: 2- => 2-z
    [[ "$part" == *- ]] && part="${part}z"

    # Normalize: -4 => 1-4
    [[ "$part" == -* ]] && part="1${part}"

    # Validate range
    if [[ ! "$part" =~ ^[0-9]+-([0-9]+|[zZ])$ ]]; then
      echo "Error: invalid page range: '$part'"
      echo "Valid examples: 2-5, 2-, -5, 2-z, 1-3,5-7,9-z"
      return 1
    fi

    corrected_pages+=("$part")
  done

  # Reassemble ranges
  local pages_combined
  pages_combined=$(IFS=','; echo "${corrected_pages[*]}")

  if [[ -z "$output" || "$output" == "$input" ]]; then
    qpdf "$input" --pages . "$pages_combined" -- --replace-input
  else
    if [[ -f "$output" ]]; then
      local answer=""
      echo "Warning: output file '$output' already exists."
      read -r "answer?Overwrite? [y/N]: "
      if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        echo "Operation cancelled."
        return 1
      fi
    fi
    qpdf "$input" --pages . "$pages_combined" -- "$output"
  fi
}

fix_compinit() {
  echo "🧹 Rebuilding completion cache..."
  rm -f "$ZCOMPDUMP"
  compinit -d "$ZCOMPDUMP"
}

unexport() {
  if [[ $# -ne 1 ]]; then
    echo "Usage: unexport VARIABLE_NAME" >&2
    return 1
  fi

  local varname="$1"
  local value="${(P)varname}"
  unset "$varname"
  typeset -g "$varname=$value" # zsh: assegna globale esplicita
}

# ─── WireGuard ─────────────────────────────────────────────────────

wgup() {
  sudo wg-quick up "$1"
}

wgdown() {
  if [[ -z "$1" ]]; then
    local -a ifaces=(${(f)"$(wg show interfaces 2>/dev/null)"})
    if (( ${#ifaces[@]} == 0 )); then
      eecho "🟢 No active WireGuard interfaces."
      return 0
    fi

    echo "🔻 Bringing down all WireGuard interfaces: ${ifaces[*]}"
    for iface in "${ifaces[@]}"; do
      echo "  - down $iface"
      sudo wg-quick down "$iface"
    done
  else
    sudo wg-quick down "$1"
  fi
}

wgshow() {
  sudo wg show "$@"
}

wgrestart() {
  if [[ -z "$1" ]]; then
    local -a ifaces=(${(f)"$(wg show interfaces 2>/dev/null)"})
    if (( ${#ifaces[@]} == 0 )); then
      echo "🟢 No active WireGuard interfaces."
      return 0
    fi

    echo "🔁 Restarting all WireGuard interfaces: ${ifaces[*]}"
    for iface in "${ifaces[@]}"; do
      echo "  - restart $iface"
      sudo wg-quick down "$iface" && sudo wg-quick up "$iface"
    done
  else
    echo "🔁 Restarting WireGuard interface: $1"
    sudo wg-quick down "$1" && sudo wg-quick up "$1"
  fi
}

wgstatus() {
  local -a ifaces=(${(f)"$(wg show interfaces 2>/dev/null)"})
  if (( ${#ifaces[@]} == 0 )); then
    echo "🟢 No active interfaces."
    return 0
  fi

  for iface in "${ifaces[@]}"; do
    echo "🔌 Interface: $iface"
    sudo wg show "$iface" | awk '
      BEGIN { peer=0 }
      /^interface:/ { iface=$2 }
      /^peer:/ {
        if (peer) print ""
        print "→ Peer: "$2
        peer=1
      }
      /public key:/ { print "   🔑 PubKey: "$3 }
      /endpoint:/   { print "   🌍 Endpoint: "$2 }
      /latest handshake:/ { print "   🕓 Handshake: "$3 " " $4 " " $5 " " $6 " " $7 }
      /transfer:/ { print "   📶 Transfer: "$2 " " $3 " / " $5 " " $6 }
    '
    echo ""
  done
}

# Completion for wgup / wgdown: .conf files without extension
_wireguard_conf_completion() {
  local -a configs
  configs=(/opt/homebrew/etc/wireguard/*.conf(N:t:r))
  _describe -t configs 'WireGuard Configs' configs
}

# Completion for wgshow: subcommands + active interfaces
_wireguard_show_completion() {

  # Get active interfaces (e.g. wg0, wg_lan)
  local -a ifaces
  ifaces=(${(f)"$(wg show interfaces 2>/dev/null)"})

  local joined="${(j: :)ifaces}"

  _alternative \
    'subcmds:WireGuard subcommands:((interfaces\:Show\ active\ interfaces conf\:Show\ config dump\:Dump\ all allowed-ips\:Allowed\ IPs peers\:Peers endpoints\:Endpoints public-key\:Public\ key))' \
    "interfaces:Active WireGuard interfaces:(( $joined ))"
}

_wireguard_interface_completion() {
  local -a ifaces=(${(f)"$(wg show interfaces 2>/dev/null)"})
  [[ ${#ifaces[@]} == 0 ]] && return 0
  _describe -t interfaces 'Active WireGuard interfaces' ifaces
}

# Safely initialize completion after compinit
autoload -Uz add-zsh-hook

_init_wireguard_completion() {
  compdef _wireguard_conf_completion wgup
  compdef _wireguard_conf_completion wgdown
  compdef _wireguard_show_completion wgshow
  compdef _wireguard_show_completion wgrestart
  add-zsh-hook -d precmd _init_wireguard_completion  # Unregister after first run
}

add-zsh-hook precmd _init_wireguard_completion

# ─── Aliases ───────────────────────────────────────────────────────

alias python=python3
alias pip="python3 -m pip" # Globally: no pip install (PEP 668). Use pipx for global CLI tools.

# Git Aliases

alias gs='git status -sb'                       # Short Git status
alias gd='git diff'                             # Show changes
alias gco='git checkout'                        # Switch branches
alias gb='git branch'                           # List branches
alias gc='git commit'                           # Quick commit
alias gca='git commit -a'                       # Commit all modified tracked files
alias gp='git push'                             # Quick push
alias gl='git log --oneline --graph --decorate' # Compact visual log

# Docker Aliases

alias dps='docker ps'               # Running containers
alias dcu='docker compose up'       # Docker Compose up
alias dcd='docker compose down'     # Docker Compose down
alias drm='docker container prune'  # Remove stopped containers
alias drmi='docker image prune'     # Remove dangling images


# NPM Aliases

alias ncu='npx npm-check-updates' # Run npm-check-updates

# File Management Aliases

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ls='ls -G'
alias l='ls -l'
alias ll='ls -lh'
alias la='ls -la'
alias lt='ls -ltr'
alias c='clear'
