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
