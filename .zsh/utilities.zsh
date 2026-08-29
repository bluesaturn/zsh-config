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
