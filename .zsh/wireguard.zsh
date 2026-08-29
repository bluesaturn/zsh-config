# ─── WireGuard ─────────────────────────────────────────────────────

wgup() {
  sudo wg-quick up "$1"
}

wgdown() {
  if [[ -z "$1" ]]; then
    local -a ifaces=(${(f)"$(wg show interfaces 2>/dev/null)"})
    if (( ${#ifaces[@]} == 0 )); then
      echo "🟢 No active WireGuard interfaces."
      return 0
    fi

    echo "🔻 Bringing down all WireGuard interfaces: ${ifaces[*]}"
    for iface in "${ifaces[@]}"; do
      echo "  - down $iface"
      sudo wg-quick down "$iface"
    done
  else
    sudo wg-quick down "$1"
  fi
}

wgshow() {
  sudo wg show "$@"
}

wgrestart() {
  if [[ -z "$1" ]]; then
    local -a ifaces=(${(f)"$(wg show interfaces 2>/dev/null)"})
    if (( ${#ifaces[@]} == 0 )); then
      echo "🟢 No active WireGuard interfaces."
      return 0
    fi

    echo "🔁 Restarting all WireGuard interfaces: ${ifaces[*]}"
    for iface in "${ifaces[@]}"; do
      echo "  - restart $iface"
      sudo wg-quick down "$iface" && sudo wg-quick up "$iface"
    done
  else
    echo "🔁 Restarting WireGuard interface: $1"
    sudo wg-quick down "$1" && sudo wg-quick up "$1"
  fi
}

wgstatus() {
  local -a ifaces=(${(f)"$(wg show interfaces 2>/dev/null)"})
  if (( ${#ifaces[@]} == 0 )); then
    echo "🟢 No active interfaces."
    return 0
  fi

  for iface in "${ifaces[@]}"; do
    echo "🔌 Interface: $iface"
    sudo wg show "$iface" | awk '
      BEGIN { peer=0 }
      /^interface:/ { iface=$2 }
      /^peer:/ {
        if (peer) print ""
        print "→ Peer: "$2
        peer=1
      }
      /public key:/ { print "   🔑 PubKey: "$3 }
      /endpoint:/   { print "   🌍 Endpoint: "$2 }
      /latest handshake:/ { print "   🕓 Handshake: "$3 " " $4 " " $5 " " $6 " " $7 }
      /transfer:/ { print "   📶 Transfer: "$2 " " $3 " / " $5 " " $6 }
    '
    echo ""
  done
}

# Completion for wgup / wgdown: .conf files without extension
_wireguard_conf_completion() {
  local -a configs
  configs=(/opt/homebrew/etc/wireguard/*.conf(N:t:r))
  _describe -t configs 'WireGuard Configs' configs
}

# Completion for wgshow: subcommands + active interfaces
_wireguard_show_completion() {

  # Get active interfaces (e.g. wg0, wg_lan)
  local -a ifaces
  ifaces=(${(f)"$(wg show interfaces 2>/dev/null)"})

  local joined="${(j: :)ifaces}"

  _alternative \
    'subcmds:WireGuard subcommands:((interfaces\:Show\ active\ interfaces conf\:Show\ config dump\:Dump\ all allowed-ips\:Allowed\ IPs peers\:Peers endpoints\:Endpoints public-key\:Public\ key))' \
    "interfaces:Active WireGuard interfaces:(( $joined ))"
}

_wireguard_interface_completion() {
  local -a ifaces=(${(f)"$(wg show interfaces 2>/dev/null)"})
  [[ ${#ifaces[@]} == 0 ]] && return 0
  _describe -t interfaces 'Active WireGuard interfaces' ifaces
}

# Safely initialize completion after compinit
autoload -Uz add-zsh-hook

_init_wireguard_completion() {
  compdef _wireguard_conf_completion wgup
  compdef _wireguard_conf_completion wgdown
  compdef _wireguard_show_completion wgshow
  compdef _wireguard_interface_completion wgrestart
  add-zsh-hook -d precmd _init_wireguard_completion  # Unregister after first run
}

add-zsh-hook precmd _init_wireguard_completion
