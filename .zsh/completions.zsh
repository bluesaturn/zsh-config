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
