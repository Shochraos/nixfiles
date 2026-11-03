#!/usr/bin/env bash
set -euo pipefail

prog=${0##*/}
lock_file=/run/home-network.lock
in_parent=HOME_LAN_IN
out_parent=HOME_LAN_OUT
in_allow=HOME_LAN_IN_ALLOW
out_allow=HOME_LAN_OUT_ALLOW
owned_chains=("$in_parent" "$out_parent" "$in_allow" "$out_allow")
tcp_ports=${HOME_NETWORK_TCP_PORTS?}
udp_ports=${HOME_NETWORK_UDP_PORTS?}
match_status=1
home_ipv4_prefixes=()
home_ipv6_prefixes=()
trusted_ifaces=()

usage() {
  printf 'usage: %s apply V4_FILE V6_FILE | %s clear | %s cleanup | %s setup-static | %s detach-static\n' \
    "$prog" "$prog" "$prog" "$prog" "$prog" >&2
  exit 2
}

warn() {
  printf '%s: %s\n' "$prog" "$1" >&2
}

acquire_lock() {
  exec 9>"$lock_file"
  if ! flock -w 30 9; then
    warn "cannot acquire reconciliation lock"
    exit 1
  fi
}

canonicalize() {
  local family=$1 value=$2 out
  if ! out=$(iprange --"$family" --merge - <<<"$value" 2>/dev/null); then
    return 1
  fi
  if [[ $out != */* ]]; then
    if [[ $family == ipv4 ]]; then
      out+=/32
    else
      out+=/128
    fi
  fi
  printf '%s' "$out"
}

parse_file() {
  local file=$1 family=$2
  local -A seen=()
  local line n=0 canonical addr first second rest plen
  local min_prefix max_prefix

  if [[ ! -f $file || ! -r $file ]]; then
    warn "$family: prefix file is unavailable"
    return 1
  fi

  if [[ $family == ipv4 ]]; then
    min_prefix=16
    max_prefix=32
  else
    min_prefix=48
    max_prefix=128
  fi

  while IFS= read -r line || [[ -n $line ]]; do
    n=$((n + 1))
    line=${line%$'\r'}
    line=${line#"${line%%[![:space:]]*}"}
    line=${line%"${line##*[![:space:]]}"}
    [[ -n $line ]] || continue

    if [[ $family == ipv4 ]]; then
      if [[ $line == *:* || ! $line =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}/[0-9]{1,2}$ ]]; then
        warn "$family: line $n: not an IPv4 CIDR"
        return 1
      fi
    else
      if [[ $line == *.* || $line != *:* || ! $line =~ ^[0-9A-Fa-f:]+/[0-9]{1,3}$ ]]; then
        warn "$family: line $n: not an IPv6 CIDR"
        return 1
      fi
    fi

    if ! canonical=$(canonicalize "$family" "$line"); then
      warn "$family: line $n: invalid CIDR"
      return 1
    fi
    if [[ $canonical != "$line" ]]; then
      warn "$family: line $n: non-canonical network or host bits set"
      return 1
    fi

    addr=${canonical%/*}
    plen=${canonical##*/}
    if [[ $canonical == "0.0.0.0/0" || $canonical == "::/0" ]]; then
      warn "$family: line $n: default route"
      return 1
    fi
    if ((10#$plen < min_prefix)); then
      warn "$family: line $n: prefix broader than /$min_prefix"
      return 1
    fi
    if ((10#$plen > max_prefix)); then
      warn "$family: line $n: invalid prefix length"
      return 1
    fi

    if [[ $family == ipv4 ]]; then
      first=${addr%%.*}
      rest=${addr#*.}
      second=${rest%%.*}
      first=$((10#$first))
      second=$((10#$second))
      if ((first == 0)); then
        warn "$family: line $n: unspecified or reserved prefix"
        return 1
      fi
      if ((first == 127)); then
        warn "$family: line $n: loopback prefix"
        return 1
      fi
      if ((first == 169 && second == 254)); then
        warn "$family: line $n: link-local prefix"
        return 1
      fi
      if ((first >= 224 && first <= 239)); then
        warn "$family: line $n: multicast prefix"
        return 1
      fi
      if ((first >= 240)); then
        warn "$family: line $n: reserved prefix"
        return 1
      fi
    else
      if [[ $addr == ::* ]]; then
        warn "$family: line $n: loopback, unspecified, or mapped prefix"
        return 1
      fi
      first=${addr%%:*}
      first=$((16#$first))
      if (((first & 0xffc0) == 0xfe80)); then
        warn "$family: line $n: link-local prefix"
        return 1
      fi
      if (((first & 0xffc0) == 0xfec0)); then
        warn "$family: line $n: deprecated site-local prefix"
        return 1
      fi
      if ((first >= 0xff00)); then
        warn "$family: line $n: multicast prefix"
        return 1
      fi
    fi

    if [[ -n ${seen[$canonical]+x} ]]; then
      continue
    fi
    seen[$canonical]=1
    if [[ $family == ipv4 ]]; then
      home_ipv4_prefixes+=("$canonical")
    else
      home_ipv6_prefixes+=("$canonical")
    fi
  done <"$file"
}

address_matches() {
  local family=$1 addr=$2 prefix out
  local -a prefixes=()
  if [[ $family == ipv4 ]]; then
    prefixes=("${home_ipv4_prefixes[@]}")
  else
    prefixes=("${home_ipv6_prefixes[@]}")
  fi
  match_status=1
  for prefix in "${prefixes[@]}"; do
    if ! out=$(iprange --"$family" --common <(printf '%s\n' "$addr") <(printf '%s\n' "$prefix") 2>/dev/null); then
      match_status=2
      return 0
    fi
    if [[ -n $out ]]; then
      match_status=0
      return 0
    fi
  done
  return 0
}

managed_wifi_uuid() {
  local dev=$1 active profiles uuid filename expected matches=0 approved=0
  [[ -n ${HOME_NETWORK_WIFI_FILES:-} ]] || return 1
  if ! active=$(LC_ALL=C nmcli -g GENERAL.CON-UUID device show "$dev" 2>/dev/null); then
    return 1
  fi
  [[ $active =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]] || return 1
  if ! profiles=$(LC_ALL=C nmcli -t --escape no -f UUID,FILENAME connection show 2>/dev/null); then
    return 1
  fi
  while IFS=: read -r uuid filename; do
    [[ $uuid == "$active" ]] || continue
    matches=$((matches + 1))
    filename=${filename/#\/var\/run\//\/run\/}
    while IFS= read -r expected; do
      if [[ -n $expected && $filename == "$expected" ]]; then
        approved=1
      fi
    done <<<"$HOME_NETWORK_WIFI_FILES"
  done <<<"$profiles"
  ((matches == 1 && approved == 1)) || return 1
  printf '%s' "$active"
}

classify() {
  local devices dev type state addrs records family addr trusted wifi_uuid current_uuid
  local -a addresses=()
  local -A seen=()

  if ! devices=$(LC_ALL=C nmcli -t -f DEVICE,TYPE,STATE device status 2>/dev/null); then
    warn "cannot read NetworkManager device state"
    return 1
  fi

  trusted_ifaces=()
  while IFS=: read -r dev type state; do
    [[ -n $dev ]] || continue
    case $type in
    ethernet | wifi | vlan) ;;
    *) continue ;;
    esac
    [[ $state == connected ]] || continue
    [[ $dev != lo ]] || continue
    if [[ ! $dev =~ ^[A-Za-z0-9_.-][A-Za-z0-9_.-]*$ ]]; then
      warn "ignoring device with unsupported name"
      continue
    fi
    if [[ $type == wifi ]] && ! wifi_uuid=$(managed_wifi_uuid "$dev"); then
      warn "skipping device $dev: managed Wi-Fi identity is unavailable or unapproved"
      continue
    fi
    if ! addrs=$(ip -j addr show dev "$dev" 2>/dev/null); then
      warn "skipping device $dev: address state is unavailable"
      continue
    fi
    if ! records=$(jq -r '
      .[0].addr_info[]?
      | select(.scope == "global")
      | select(.family == "inet" or .family == "inet6")
      | select((.tentative // false) == false and (.dadfailed // false) == false)
      | [.family, .local]
      | @tsv
    ' <<<"$addrs" 2>/dev/null); then
      warn "skipping device $dev: address state is unreadable"
      continue
    fi
    mapfile -t addresses <<<"$records"
    trusted=0
    for addr in "${addresses[@]}"; do
      [[ -n $addr ]] || continue
      family=${addr%%$'\t'*}
      addr=${addr#*$'\t'}
      case $family in
      inet) family=ipv4 ;;
      inet6) family=ipv6 ;;
      *) continue ;;
      esac
      address_matches "$family" "$addr"
      if ((match_status == 2)); then
        warn "cannot match $family address on device $dev"
        return 1
      fi
      if ((match_status == 0)); then
        trusted=1
        break
      fi
    done
    if ((trusted == 1)) && [[ $type == wifi ]]; then
      if ! current_uuid=$(managed_wifi_uuid "$dev") || [[ $current_uuid != "$wifi_uuid" ]]; then
        warn "skipping device $dev: managed Wi-Fi identity changed"
        continue
      fi
    fi
    if ((trusted == 1)) && [[ -z ${seen[$dev]+x} ]]; then
      seen[$dev]=1
      trusted_ifaces+=("$dev")
    fi
  done <<<"$devices"
}

ports_for() {
  case $1 in
  tcp) printf '%s' "$tcp_ports" ;;
  udp) printf '%s' "$udp_ports" ;;
  esac
}

jump_specs() {
  local proto ports
  for proto in tcp udp; do
    ports=$(ports_for "$proto")
    [[ -n $ports ]] || continue
    printf '%s dports %s\n' "$proto" "$ports"
    printf '%s sports %s\n' "$proto" "$ports"
  done
}

restore_for() {
  case $1 in
  iptables) printf '%s' iptables-restore ;;
  ip6tables) printf '%s' ip6tables-restore ;;
  *) return 1 ;;
  esac
}

chain_exists() {
  "$1" -w 10 -S "$2" >/dev/null 2>&1
}

ensure_chain() {
  local bin=$1 chain=$2
  if chain_exists "$bin" "$chain"; then
    return 0
  fi
  "$bin" -w 10 -N "$chain" 2>/dev/null || chain_exists "$bin" "$chain"
}

rule_exists() {
  local bin=$1
  shift
  "$bin" -w 10 -C "$@" >/dev/null 2>&1
}

last_rule_is_drop() {
  local bin=$1 chain=$2 last
  last=$("$bin" -w 10 -S "$chain" 2>/dev/null | tail -n 1) || return 1
  [[ $last == "-A $chain -j DROP" ]]
}

static_body() {
  printf '*filter\n'
  printf ':%s - [0:0]\n' "$in_parent"
  printf '%s\n' "-A $in_parent -i lo -j RETURN"
  printf '%s\n' "-A $in_parent -j $in_allow"
  printf '%s\n' "-A $in_parent -j DROP"
  printf ':%s - [0:0]\n' "$out_parent"
  printf '%s\n' "-A $out_parent -o lo -j RETURN"
  printf '%s\n' "-A $out_parent -j $out_allow"
  printf '%s\n' "-A $out_parent -j DROP"
  printf 'COMMIT\n'
}

verify_static_family() {
  local bin=$1
  chain_exists "$bin" "$in_parent" || return 1
  chain_exists "$bin" "$out_parent" || return 1
  chain_exists "$bin" "$in_allow" || return 1
  chain_exists "$bin" "$out_allow" || return 1
  rule_exists "$bin" "$in_parent" -i lo -j RETURN || return 1
  rule_exists "$bin" "$in_parent" -j "$in_allow" || return 1
  rule_exists "$bin" "$in_parent" -j DROP || return 1
  rule_exists "$bin" "$out_parent" -o lo -j RETURN || return 1
  rule_exists "$bin" "$out_parent" -j "$out_allow" || return 1
  rule_exists "$bin" "$out_parent" -j DROP || return 1
  last_rule_is_drop "$bin" "$in_parent" || return 1
  last_rule_is_drop "$bin" "$out_parent" || return 1
}

wait_for_chain() {
  local bin=$1 chain=$2 attempt=0
  while ((attempt < 15)); do
    if chain_exists "$bin" "$chain"; then
      return 0
    fi
    sleep 0.2
    attempt=$((attempt + 1))
  done
  return 1
}

owned_rule_specs() {
  local bin=$1 parent=$2 target=$3 listing line
  if ! listing=$("$bin" -w 10 -S "$parent" 2>/dev/null); then
    return 1
  fi
  while IFS= read -r line; do
    [[ $line == "-A $parent "* ]] || continue
    [[ $line == *" -j $target" ]] || continue
    printf '%s\n' "${line#"-A $parent "}"
  done <<<"$listing"
}

delete_owned_jumps() {
  local bin=$1 parent=$2 target=$3 restore listing spec
  local -a specs=()
  if ! listing=$(owned_rule_specs "$bin" "$parent" "$target"); then
    return 1
  fi
  while IFS= read -r spec; do
    [[ -n $spec ]] || continue
    specs+=("$spec")
  done <<<"$listing"
  ((${#specs[@]} > 0)) || return 0
  if ! restore=$(restore_for "$bin"); then
    return 1
  fi
  {
    printf '*filter\n'
    for spec in "${specs[@]}"; do
      printf -- '-D %s %s\n' "$parent" "$spec"
    done
    printf 'COMMIT\n'
  } | "$restore" -w 10 -n 2>/dev/null
}

attach_jumps() {
  local bin=$1 parent=$2 target=$3 restore listing spec proto dir ports
  local -a current=() desired=() missing=() stale=()
  local -A present=() wanted=()
  wait_for_chain "$bin" "$parent" || return 1
  if ! listing=$(owned_rule_specs "$bin" "$parent" "$target"); then
    return 1
  fi
  while IFS= read -r spec; do
    [[ -n $spec ]] || continue
    current+=("$spec")
    present["$spec"]=1
  done <<<"$listing"
  while read -r proto dir ports; do
    spec="-p $proto -m multiport --$dir $ports -j $target"
    desired+=("$spec")
    wanted["$spec"]=1
  done < <(jump_specs)
  for spec in "${desired[@]}"; do
    [[ -n ${present["$spec"]+x} ]] || missing+=("$spec")
  done
  for spec in "${current[@]}"; do
    [[ -n ${wanted["$spec"]+x} ]] || stale+=("$spec")
  done
  ((${#missing[@]} > 0 || ${#stale[@]} > 0)) || return 0
  if ! restore=$(restore_for "$bin"); then
    return 1
  fi
  {
    printf '*filter\n'
    for spec in "${missing[@]}"; do
      printf -- '-I %s 1 %s\n' "$parent" "$spec"
    done
    for spec in "${stale[@]}"; do
      printf -- '-D %s %s\n' "$parent" "$spec"
    done
    printf 'COMMIT\n'
  } | "$restore" -w 10 -n 2>/dev/null
}

chain_absent() {
  local bin=$1 chain=$2 listing line
  if ! listing=$("$bin" -w 10 -S 2>/dev/null); then
    return 1
  fi
  while IFS= read -r line; do
    [[ $line != "-N $chain" && $line != "-P $chain "* ]] || return 1
  done <<<"$listing"
  return 0
}

detach_jumps() {
  local bin=$1 parent=$2 target=$3
  if delete_owned_jumps "$bin" "$parent" "$target"; then
    return 0
  fi
  if chain_absent "$bin" "$parent"; then
    return 0
  fi
  return 1
}

setup_static_family() {
  local bin=$1 chain
  for chain in "${owned_chains[@]}"; do
    ensure_chain "$bin" "$chain" || return 1
  done
  static_body | "$(restore_for "$bin")" -w 10 -n 2>/dev/null || return 1
  verify_static_family "$bin" || return 1
  attach_jumps "$bin" nixos-fw "$in_parent" || return 1
  attach_jumps "$bin" OUTPUT "$out_parent" || return 1
}

setup_static_all() {
  local bin rc=0
  for bin in iptables ip6tables; do
    if ! setup_static_family "$bin"; then
      warn "cannot install the $bin static policy"
      rc=1
    fi
  done
  return "$rc"
}

detach_static_all() {
  local bin rc=0
  for bin in iptables ip6tables; do
    detach_jumps "$bin" nixos-fw "$in_parent" || rc=1
    detach_jumps "$bin" OUTPUT "$out_parent" || rc=1
  done
  return "$rc"
}

ensure_static() {
  local bin
  for bin in iptables ip6tables; do
    if verify_static_family "$bin"; then
      attach_jumps "$bin" nixos-fw "$in_parent" || return 1
      attach_jumps "$bin" OUTPUT "$out_parent" || return 1
      continue
    fi
    setup_static_family "$bin" || return 1
  done
}

apply_family() {
  local restore=$1 iface rule
  local -a rules=()
  for iface in "${trusted_ifaces[@]}"; do
    printf -v rule -- '-A %s -i %s -j ACCEPT' "$in_allow" "$iface"
    rules+=("$rule")
    printf -v rule -- '-A %s -o %s -j ACCEPT' "$out_allow" "$iface"
    rules+=("$rule")
  done
  {
    printf '*filter\n'
    printf ':%s - [0:0]\n' "$in_allow"
    printf ':%s - [0:0]\n' "$out_allow"
    if ((${#rules[@]} > 0)); then
      printf '%s\n' "${rules[@]}"
    fi
    printf 'COMMIT\n'
  } | "$restore" -w 10 -n 2>/dev/null
}

clear_family() {
  local restore=$1
  printf '*filter\n:%s - [0:0]\n:%s - [0:0]\nCOMMIT\n' "$in_allow" "$out_allow" |
    "$restore" -w 10 -n 2>/dev/null
}

clear_all() {
  local rc=0
  clear_family iptables-restore || rc=1
  clear_family ip6tables-restore || rc=1
  return "$rc"
}

fail_closed() {
  if ! clear_all; then
    warn "failed to clear scoped grants"
  fi
  warn "$1"
  exit 1
}

remove_chain() {
  local bin=$1 chain=$2
  chain_exists "$bin" "$chain" || return 0
  "$bin" -w 5 -F "$chain" 2>/dev/null || return 1
  "$bin" -w 5 -X "$chain" 2>/dev/null || return 1
}

cleanup_all() {
  local bin chain rc=0
  for bin in iptables ip6tables; do
    detach_jumps "$bin" nixos-fw "$in_parent" || rc=1
    detach_jumps "$bin" OUTPUT "$out_parent" || rc=1
  done
  for bin in iptables ip6tables; do
    for chain in "${owned_chains[@]}"; do
      remove_chain "$bin" "$chain" || rc=1
    done
  done
  return "$rc"
}

case ${1:-} in
apply)
  (($# == 3)) || usage
  acquire_lock
  if ! ensure_static; then
    fail_closed "static policy structure is unusable"
  fi
  if ! parse_file "$2" ipv4; then
    fail_closed "IPv4 home prefixes are unusable"
  fi
  if ! parse_file "$3" ipv6; then
    fail_closed "IPv6 home prefixes are unusable"
  fi
  if ! classify; then
    fail_closed "link state is unusable"
  fi
  if ! apply_family iptables-restore; then
    fail_closed "IPv4 policy restore failed"
  fi
  if ! apply_family ip6tables-restore; then
    fail_closed "IPv6 policy restore failed"
  fi
  ;;
clear)
  acquire_lock
  if ! clear_all; then
    warn "failed to clear scoped grants"
    exit 1
  fi
  ;;
cleanup)
  acquire_lock
  if ! state=$(systemctl show --property=ActiveState --value home-network.service 2>/dev/null); then
    warn "cannot verify service state; keeping the scoped policy"
    exit 1
  fi
  if [[ $state != inactive ]]; then
    warn "home-network.service is not inactive; keeping the scoped policy"
    exit 0
  fi
  if ! cleanup_all; then
    warn "scoped policy cleanup was incomplete"
    exit 1
  fi
  ;;
setup-static)
  acquire_lock
  if ! setup_static_all; then
    exit 1
  fi
  ;;
detach-static)
  acquire_lock
  if ! detach_static_all; then
    exit 1
  fi
  ;;
*)
  usage
  ;;
esac
