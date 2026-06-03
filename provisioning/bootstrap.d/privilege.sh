#!/usr/bin/env bash
# privilege escalation, users, groups

# this prrevents 'unbound variable' errors in non-login shells (like Docker)
USER="${USER:-$(id -un)}"
export USER

prompt_yes_no(){
  local q="$1" ans
  [[ "${YES:-0}" -eq 1 ]] && return 0
  read -r -p "$q [y/N]: " ans
  [[ "$ans" =~ ^[Yy]([Ee][Ss])?$ ]]
}

_su_root(){
  local cmd=""
  local q
  for q in "$@"; do cmd+=" $(printf "%q" "$q")"; done
  su -pc "${cmd# }" root
}

as_root(){
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    "$@"
    return 0
  fi
  if have sudo; then
    sudo -E "$@"
    return 0
  fi
  have su || die "no sudo and no su"
  _su_root "$@"
}

detect_codename(){
  if have lsb_release; then lsb_release -cs 2>/dev/null || true; return 0; fi
  . /etc/os-release 2>/dev/null || true
  printf "%s" "${VERSION_CODENAME:-}"
}

user_in_group(){
  local g="$1"
  id -nG "$USER" | tr ' ' '\n' | grep -qx "$g"
}

ensure_group_membership(){
  local g="$1"
  if ! user_in_group "$g"; then
    as_root usermod -aG "$g" "$USER" >/dev/null 2>&1 || true
    warn "added $USER to group: $g (relogin needed)"
    save_state_kv "OSYX_BOOTSTRAP_NEEDS_RELOGIN" "1"
  fi
}

ensure_sudo_present(){
  if have sudo; then
    ok "sudo present"
    return 0
  fi

  have su || die "sudo missing and su missing. log in as root and install sudo."
  info "installing sudo via su"
  _su_root apt-get update -yq || true
  _su_root apt-get install -yq --no-install-recommends sudo ca-certificates gnupg curl wget || true

  have sudo || die "sudo install failed"
  info "adding $USER to sudo group"
  _su_root usermod -aG sudo "$USER" || true
  warn "sudo installed, group updated. relogin required if sudo still says no."
  save_state_kv "OSYX_BOOTSTRAP_NEEDS_RELOGIN" "1"
}

pick_main_user(){
  if [[ -n "${MAIN_USER:-}" ]]; then printf "%s" "$MAIN_USER"; return 0; fi
  if [[ -n "${SUDO_USER:-}" ]]; then printf "%s" "$SUDO_USER"; return 0; fi
  local u
  u="$(awk -F: '$3>=1000 && $1!="nobody"{print $1":"$6}' /etc/passwd | grep -E ':/home/' | head -n1 | cut -d: -f1 || true)"
  [[ -n "$u" ]] || return 1
  printf "%s" "$u"
}

reexec_as_user(){
  local target="$1"; shift || true
  local -a args=("$@")
  local q cmd=""
  for q in "${args[@]}"; do cmd+=" $(printf "%q" "$q")"; done
  exec su - "$target" -c "env OSYX_BOOTSTRAP_REENTERED=1 bash $(printf "%q" "$SCRIPT_DIR/bootstrap")${cmd}"
}