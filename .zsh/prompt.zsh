# ─── Git Prompt ────────────────────────────────────────────────────

# Zsh prompt expansion reference:
# https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html

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

# ─── Prompt ────────────────────────────────────────────────────────

# Left prompt: user, host, directory, Git status, and optional exit status.
PROMPT=$'%(?..Exit status: %B%F{196}%?%f%b\n)[%B%F{201}%n%f%b at %B%F{81}%m%f%b in %B%F{214}%~%f%b$(git_branch)]%# '

# Right prompt: Python virtualenv or Poetry environment.
RPROMPT='$(python_env)'
