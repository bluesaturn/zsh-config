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
