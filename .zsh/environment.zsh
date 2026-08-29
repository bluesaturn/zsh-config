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
