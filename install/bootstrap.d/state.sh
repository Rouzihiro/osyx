#!/usr/bin/env bash
# state file persistence

save_state_kv(){
  local k="$1" v="$2"
  mkdir -p "$(dirname "$STATE_FILE")"
  [[ -f "$STATE_FILE" ]] || : >"$STATE_FILE"
  local k_esc
  k_esc="$(printf '%s' "$k" | sed -e 's/[][\\.^$*+?(){}|]/\\&/g')"
  if grep -qE "^${k_esc}=" "$STATE_FILE"; then
    sed -ri "s|^${k_esc}=.*|${k}=${v}|" "$STATE_FILE"
  else
    printf "%s=%s\n" "$k" "$v" >>"$STATE_FILE"
  fi
}

load_state(){
  [[ -f "$STATE_FILE" ]] || return 0
  local line k v
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -n "$line" ]] || continue
    case "$line" in \#*) continue ;; esac
    IFS='=' read -r k v <<<"$line"
    [[ -n "${k:-}" ]] || continue
    if [[ "$k" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
      printf -v "$k" '%s' "${v-}"
      export "$k"
    fi
  done <"$STATE_FILE"
}
