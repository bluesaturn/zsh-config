# ─── WireGuard (macOS / Homebrew) ───────────────────────────────────

_wireguard_config_dir=/opt/homebrew/etc/wireguard

# Resolve logical configuration names, preserving explicitly supplied paths.
_wireguard_config_arg() {
  if [[ "$1" != */* && -f "$_wireguard_config_dir/$1.conf" ]]; then
    REPLY="$_wireguard_config_dir/$1.conf"
  else
    REPLY="$1"
  fi
}

# Return active physical interfaces in reply (macOS: e.g. utun4, utun5).
# The output of `wg show interfaces` is space-separated, NOT line-separated.
_wireguard_physical_interfaces() {
  local output
  output="$(sudo wg show interfaces 2>/dev/null)" || return 1
  reply=( ${=output} )
}

# Return logical configuration names corresponding to active interfaces.
# Only names with a matching .conf file are manageable via wg-quick here.
_wireguard_active_configs() {
  local -a physical configs
  local name real
  _wireguard_physical_interfaces || return 1
  physical=( "${reply[@]}" )
  configs=( "$_wireguard_config_dir"/*.conf(N:t:r) )
  reply=()
  for name in "${configs[@]}"; do
    real="$(sudo cat "/var/run/wireguard/$name.name" 2>/dev/null)" || continue
    if (( ${physical[(Ie)$real]} > 0 )); then
      reply+=( "$name" )
    fi
  done
}

# Hide wg-quick's verbose output; provide a concise diagnostic upon failure.
_wireguard_quiet_quick() {
  local action="$1" target="$2" log line result
  log="$(mktemp "${TMPDIR:-/tmp/}wg-quick.XXXXXXXX")" || {
    print -u2 -- '✗ Impossibile creare il log temporaneo.'
    return 1
  }
  # Authenticate before redirecting output so the password prompt stays visible.
  if ! sudo -v; then
    rm -f -- "$log"
    print -u2 -- "✗ Autenticazione sudo non riuscita."
    return 1
  fi
  sudo -n wg-quick "$action" "$target" >"$log" 2>&1
  result=$?
  if (( result != 0 )); then
    # Prefer an actionable error to the routine [#] command trace.
    line="$(awk '!/^\[#\]/ && !/^\[+\]/ && NF { last=$0 } END { print last }' "$log")"
    [[ -n "$line" ]] || line="$(tail -n 1 "$log")"
    print -u2 -- "✗ WireGuard ($action: ${target:t:r}): ${line:-errore sconosciuto} (codice $result)"
  fi
  rm -f -- "$log"
  return "$result"
}

wgup() {
  if (( $# != 1 )); then
    print -u2 -- 'Uso: wgup <configurazione>'
    return 1
  fi
  _wireguard_config_arg "$1"
  local target="$REPLY"
  if _wireguard_quiet_quick up "$target"; then
    print -P -- "%F{green}✓%f WireGuard attivata: ${1:t:r}"
  else
    return 1
  fi
}

wgdown() {
  local -a configs
  local name target failed=0
  if (( $# == 0 )); then
    if ! _wireguard_active_configs; then
      print -u2 -- '✗ Impossibile leggere le interfacce WireGuard attive.'
      return 1
    fi
    configs=( "${reply[@]}" )
    if (( ${#configs} == 0 )); then
      print -- 'Nessuna configurazione WireGuard attiva da arrestare.'
      return 0
    fi
  else
    configs=( "$@" )
  fi

  for name in "${configs[@]}"; do
    _wireguard_config_arg "$name"
    target="$REPLY"
    if _wireguard_quiet_quick down "$target"; then
      print -P -- "%F{green}✓%f WireGuard disattivata: ${name:t:r}"
    else
      failed=1
    fi
  done
  return "$failed"
}

wgshow() {
  sudo wg show "$@"
}

wgrestart() {
  local -a configs
  local name target failed=0
  if (( $# == 0 )); then
    if ! _wireguard_active_configs; then
      print -u2 -- '✗ Impossibile leggere le interfacce WireGuard attive.'
      return 1
    fi
    configs=( "${reply[@]}" )
    if (( ${#configs} == 0 )); then
      print -- 'Nessuna configurazione WireGuard attiva da riavviare.'
      return 0
    fi
  else
    configs=( "$@" )
  fi

  for name in "${configs[@]}"; do
    _wireguard_config_arg "$name"
    target="$REPLY"
    if ! _wireguard_quiet_quick down "$target"; then
      print -u2 -- "✗ Riavvio interrotto per ${name:t:r}: arresto non riuscito."
      failed=1
      continue
    fi
    if _wireguard_quiet_quick up "$target"; then
      print -P -- "%F{green}✓%f WireGuard riavviata: ${name:t:r}"
    else
      failed=1
    fi
  done
  return "$failed"
}

wgstatus() {
  local -a physical configs
  local name real iface label
  if ! _wireguard_physical_interfaces; then
    print -u2 -- '✗ Impossibile leggere lo stato WireGuard.'
    return 1
  fi
  physical=( "${reply[@]}" )
  if (( ${#physical} == 0 )); then
    print -- 'Nessuna interfaccia WireGuard attiva.'
    return 0
  fi

  configs=( "$_wireguard_config_dir"/*.conf(N:t:r) )
  for iface in "${physical[@]}"; do
    label="$iface"
    for name in "${configs[@]}"; do
      real="$(sudo cat "/var/run/wireguard/$name.name" 2>/dev/null)" || continue
      if [[ "$real" == "$iface" ]]; then
        label="$name ($iface)"
        break
      fi
    done
    print -P -- "%F{green}●%f WireGuard attiva: $label"
  done
}

_wireguard_conf_completion() {
  local -a configs
  configs=( "$_wireguard_config_dir"/*.conf(N:t:r) )
  _describe -t configs 'Configurazioni WireGuard' configs
}

_wireguard_active_completion() {
  local -a configs
  _wireguard_active_configs || return 1
  configs=( "${reply[@]}" )
  (( ${#configs} )) && _describe -t interfaces 'Configurazioni WireGuard attive' configs
}

_wireguard_show_completion() {
  local -a ifaces
  local output
  output="$(wg show interfaces 2>/dev/null)"
  ifaces=( ${=output} )
  _alternative \
    'subcmds:WireGuard subcommands:((interfaces\:Show\ active\ interfaces conf\:Show\ config dump\:Dump\ all allowed-ips\:Allowed\ IPs peers\:Peers endpoints\:Endpoints public-key\:Public\ key))' \
    "interfaces:Active WireGuard interfaces:(( ${(j: :)ifaces} ))"
}

# Initialize completion after compinit.
autoload -Uz add-zsh-hook
_init_wireguard_completion() {
  compdef _wireguard_conf_completion wgup
  compdef _wireguard_active_completion wgdown wgrestart
  compdef _wireguard_show_completion wgshow
  add-zsh-hook -d precmd _init_wireguard_completion
}
add-zsh-hook precmd _init_wireguard_completion
