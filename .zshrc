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

ZSH_CONFIG_DIR="$HOME/.zsh"

source "$ZSH_CONFIG_DIR/environment.zsh"
source "$ZSH_CONFIG_DIR/path.zsh"
source "$ZSH_CONFIG_DIR/completions.zsh"
source "$ZSH_CONFIG_DIR/nvm.zsh"
source "$ZSH_CONFIG_DIR/python.zsh"
source "$ZSH_CONFIG_DIR/prompt.zsh"
source "$ZSH_CONFIG_DIR/utilities.zsh"
source "$ZSH_CONFIG_DIR/wireguard.zsh"
source "$ZSH_CONFIG_DIR/aliases.zsh"
