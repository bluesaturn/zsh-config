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
