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

# Android Build Tools: use the latest installed version
if [[ -d "$ANDROID_SDK_ROOT/build-tools" ]]; then
  _android_build_tools=("$ANDROID_SDK_ROOT"/build-tools/*(N/On))
  (( ${#_android_build_tools[@]} )) && path_prepend "$_android_build_tools[1]"
  unset _android_build_tools
fi

# Add important paths
path_prepend "$HOME/.local/bin"
path_prepend "$JAVA_HOME/bin"
path_prepend "$HOME/Applications/MATLAB_R2024b.app/bin"
path_prepend "$ANDROID_SDK_ROOT/platform-tools"
path_prepend "$ANDROID_SDK_ROOT/emulator"
path_prepend "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin"
