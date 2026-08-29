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

fix_compinit() {
  echo "🧹 Rebuilding completion cache..."
  rm -f "$ZCOMPDUMP"
  compinit -d "$ZCOMPDUMP"
}

refresh_old_compdump

_rebuild_compdump=0

if [[ ! -f "$ZCOMPDUMP" ]]; then
  _rebuild_compdump=1
else
  for config_file in "$HOME/.zshrc" "$ZSH_CONFIG_DIR"/*.zsh(N); do
    if [[ "$ZCOMPDUMP" -ot "$config_file" ]]; then
      _rebuild_compdump=1
      break
    fi
  done
fi

if (( _rebuild_compdump )); then
  compinit -d "$ZCOMPDUMP"
else
  compinit -C -d "$ZCOMPDUMP"
fi

if command -v register-python-argcomplete >/dev/null 2>&1; then
  eval "$(register-python-argcomplete pipx)"
fi
