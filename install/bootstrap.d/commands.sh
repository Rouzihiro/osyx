#!/usr/bin/env bash
# command implementations + argument parsing + dispatch

VITALS=(
  ca-certificates gnupg curl wget
  git
  locales tzdata
  dbus dbus-user-session
  xdg-user-dirs
  sudo
  zsh
)

BASE_TOOLS=(
  neovim tmux
  ripgrep fd-find
  fzf
  bat
  tree
  htop btop
  unzip xz-utils
  openssh-client
  man-db less
)

DESKTOP_BASE=(
  network-manager
  seatd
  polkitd
  xwayland
  xdg-desktop-portal xdg-desktop-portal-gtk
  pipewire wireplumber pipewire-pulse
  pavucontrol
  wl-clipboard
  grim slurp
  waybar
  wofi
  dunst
  kitty
  brightnessctl
  playerctl
  fonts-noto-color-emoji
  firefox-esr
)

PROFILE="$PROFILE_DEFAULT"
PREFIX="$PREFIX_DEFAULT"
LOCALE="$LOCALE_DEFAULT"
TZ="$TZ_DEFAULT"
YES=0
WITH=""
NO_HYPR=0

usage(){
  local self
  self="$(basename "${BASH_SOURCE[0]:-$0}")"

  cat <<EOF
${C_BOLD}${self}${C_RESET} v$VERSION

synopsis:
  ${self} <command> [options]

commands:
  fresh     root-only first stage for a new debian install (baseline packages + networking + locale/tz)
  plan      read-only: compute what would change (missing apt deps + optional hyprbuild plan output)
  apply     install + configure (apt deps, locale/tz, services/groups, extras, optional hyprland build)
  doctor    print diagnostics (kernel/groups/tools/paths)
  status    print saved state (if any)
  clean     remove logs (default) or remove logs+cache+state with --all
  help      show this help

command usage:
  ${self} fresh [--user=<name>] [--locale=$LOCALE_DEFAULT] [--tz=$TZ_DEFAULT] [--yes]
  ${self} plan  [--profile=min|desktop] [--prefix=$PREFIX_DEFAULT] [--locale=$LOCALE_DEFAULT] [--tz=$TZ_DEFAULT] [--with=a,b,c] [--no-hypr] [--yes]
  ${self} apply [--profile=min|desktop] [--prefix=$PREFIX_DEFAULT] [--locale=$LOCALE_DEFAULT] [--tz=$TZ_DEFAULT] [--with=a,b,c] [--no-hypr] --yes
  ${self} doctor
  ${self} status
  ${self} clean [--all]

options:
  --profile=min|desktop   package set (default: $PROFILE_DEFAULT)
  --prefix=/usr/local     install prefix forwarded to hyprbuild (default: $PREFIX_DEFAULT)
  --locale=LOCALE         locale to generate + set LANG (default: $LOCALE_DEFAULT)
  --tz=AREA/City          timezone (default: $TZ_DEFAULT)
  --with=a,b,c            run extra installers after base packages (comma list)
  --no-hypr               skip hyprbuild apply/plan
  --yes                   non-interactive confirmation for destructive actions
  -h, --help              show this help

important behavior (read this before you get mad):
  apply is destructive and requires --yes. without --yes it exits with code 2 and prints the exact rerun command.
  plan accepts --yes for symmetry but it does nothing (plan is always read-only).
  if you run plan/apply as root, the script auto re-execs as the detected main user. to force it, set MAIN_USER=<name>.
  some changes require relogin or reboot (group membership, default shell). the script will tell you when.

--with extras:
  built-ins:
    ohmyzsh (alias: omz)

  repo scripts:
    provide the bare name and it resolves in this order:
      install/arbitrary/<name>
      install/proprietary/<name>
      install/misc/<name>

  examples:
    --with=omz
    --with=node,pnpm,rust,chrome,brave

hyprland:
  default (no --no-hypr) behavior:
    plan  runs: $HYPRBUILD_REL plan  --profile=<profile> --prefix=<prefix>
    apply runs: $HYPRBUILD_REL apply --profile=<profile> --prefix=<prefix> --yes

state, cache, logs:
  state dir:  $STATE_DIR_DEFAULT
  cache dir:  $CACHE_DIR_DEFAULT
  logs dir:   $LOG_DIR_DEFAULT
  state file: $STATE_FILE_DEFAULT
  overrides:
    XDG_STATE_HOME, XDG_CACHE_HOME

exit codes:
  0 ok
  2 confirmation required (apply without --yes)
  1 other error

examples:
  sudo ./install/bootstrap fresh --user=$(id -un) --yes
  ./install/bootstrap plan --profile=desktop
  ./install/bootstrap plan --profile=desktop --with=omz,node,pnpm --no-hypr
  ./install/bootstrap apply --profile=desktop --yes
  ./install/bootstrap apply --profile=desktop --yes --with=omz,node,pnpm,rust
  ./install/bootstrap apply --profile=min --no-hypr --yes
  ./install/bootstrap doctor
  ./install/bootstrap status
  ./install/bootstrap clean
  ./install/bootstrap clean --all
EOF
}

parse_args(){
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --profile=*) PROFILE="${1#*=}" ;;
      --prefix=*) PREFIX="${1#*=}" ;;
      --locale=*) LOCALE="${1#*=}" ;;
      --tz=*) TZ="${1#*=}" ;;
      --yes) YES=1 ;;
      --with=*) WITH="${1#*=}" ;;
      --no-hypr) NO_HYPR=1 ;;
      -h|--help) usage; exit 0 ;;
      *) die "unknown arg: $1" ;;
    esac
    shift
  done

  if [[ "$PROFILE" != "min" && "$PROFILE" != "desktop" ]]; then
    die "invalid --profile (min|desktop): $PROFILE"
  fi
}

doctor(){
  start_logging
  log "${C_BOLD}doctor${C_RESET}"
  log "kernel: $(uname -r)"
  log "groups: $(id -nG)"
  log "sudo:   $(have sudo && echo yes || echo no)"
  log "zsh:    $(have zsh && echo yes || echo no)"
  log "omz:    $([[ -d "$HOME/.oh-my-zsh" ]] && echo yes || echo no)"
  log "seatd:  $(dpkg_installed seatd && echo installed || echo no)"
  log "nm:     $(dpkg_installed network-manager && echo installed || echo no)"
  log "hyprbuild: $([[ -f "$REPO_ROOT/$HYPRBUILD_REL" ]] && echo yes || echo no)"
  log "state:  $STATE_FILE"
}

status(){
  start_logging
  load_state
  log "${C_BOLD}status${C_RESET}"
  if [[ -f "$STATE_FILE" ]]; then
    sed -n 's/^/  /p' "$STATE_FILE"
  else
    log "  (no state yet)"
  fi
}

clean(){
  start_logging
  local all="${1:-}"
  if [[ "$all" == "--all" ]]; then
    info "removing cache and state"
    rm -rf "$CACHE_DIR" "$STATE_DIR"
    ok "cleaned"
    return 0
  fi
  info "removing logs only"
  rm -rf "$LOG_DIR"
  ok "cleaned logs"
}

plan(){
  start_logging
  if ! is_debian; then warn "not debian, plan may be wrong"; fi

  local -a want=()
  want+=("${VITALS[@]}")
  want+=("${BASE_TOOLS[@]}")
  if [[ "$PROFILE" == "desktop" ]]; then want+=("${DESKTOP_BASE[@]}"); fi

  local -a missing=()
  local p
  for p in "${want[@]}"; do
    dpkg_installed "$p" || missing+=("$p")
  done

  log "${C_BOLD}Plan${C_RESET}"
  if [[ "${#missing[@]}" -gt 0 ]]; then
    log "  + apt install (${#missing[@]}):"
    for p in "${missing[@]}"; do log "    - $p"; done
  else
    log "  = apt deps: already satisfied"
  fi

  if [[ -n "$WITH" ]]; then
    log "  + run installers:"
    local -a items=()
    IFS=',' read -r -a items <<<"$WITH"
    for p in "${items[@]}"; do
      [[ -n "$p" ]] || continue
      log "    - $p"
    done
  fi

  if [[ "$NO_HYPR" -eq 0 ]]; then
    log "  + hyprland:"
    log "    - will run: $HYPRBUILD_REL apply --profile=$PROFILE --prefix=$PREFIX --yes"
    log ""
    log "${C_DIM}hyprbuild plan output:${C_RESET}"
    run_hyprbuild_plan | sed -n 's/^/  /p' || true
  else
    log "  = hyprland: skipped"
  fi

  log ""
  log "to apply: ${C_BOLD}./install/bootstrap apply --profile=$PROFILE --prefix=$PREFIX --yes${C_RESET}"
}

apply(){
  start_logging
  if ! is_debian; then warn "not debian, continuing"; fi

  if [[ "${YES:-0}" -ne 1 ]]; then
    warn "confirmation required"
    log "run: ./install/bootstrap apply --yes --profile=$PROFILE"
    exit 2
  fi

  ensure_sudo_present

  info "installing vitals"
  apt_install_best_effort "${VITALS[@]}"

  info "installing base tools"
  apt_install_best_effort "${BASE_TOOLS[@]}"

  if [[ "$PROFILE" == "desktop" ]]; then
    info "installing desktop base"
    apt_install_best_effort "${DESKTOP_BASE[@]}"
  fi

  ensure_locale_tz "$LOCALE" "$TZ"

  if dpkg_installed network-manager; then
    as_root systemctl enable NetworkManager --now >/dev/null 2>&1 || true
  fi

  if dpkg_installed seatd; then
    as_root systemctl enable seatd --now >/dev/null 2>&1 || true
    ensure_group_membership seat
  fi

  ensure_group_membership sudo
  ensure_group_membership video
  ensure_group_membership input
  ensure_group_membership audio

  if dpkg_installed zsh; then
    if [[ "${SHELL:-}" != "/usr/bin/zsh" && -x /usr/bin/zsh ]]; then
      chsh -s /usr/bin/zsh "$USER" >/dev/null 2>&1 || true
      ok "zsh set as default shell (may require relogin)"
    fi
  fi

  ensure_fd_alias
  ensure_bat_alias

  if dpkg_installed xdg-user-dirs; then
    xdg-user-dirs-update >/dev/null 2>&1 || true
  fi

  save_state_kv "OSYX_BOOTSTRAP_PROFILE" "$PROFILE"
  save_state_kv "OSYX_BOOTSTRAP_PREFIX" "$PREFIX"
  save_state_kv "OSYX_BOOTSTRAP_LOCALE" "$LOCALE"
  save_state_kv "OSYX_BOOTSTRAP_TZ" "$TZ"
  save_state_kv "OSYX_BOOTSTRAP_APPLIED_AT" "$(date -Is 2>/dev/null || date)"

  if [[ -n "$WITH" ]]; then
    info "running extras: $WITH"
    apply_with_list "$WITH"
  fi

  if [[ "$NO_HYPR" -eq 0 ]]; then
    info "installing hyprland"
    run_hyprbuild_apply
    save_state_kv "OSYX_BOOTSTRAP_HYPR" "installed"
  else
    save_state_kv "OSYX_BOOTSTRAP_HYPR" "skipped"
  fi

  ok "done"
  if [[ "${OSYX_BOOTSTRAP_NEEDS_RELOGIN:-0}" == "1" ]]; then
    warn "relogin or reboot is required (groups/shell)"
  fi
  if [[ "$NO_HYPR" -eq 0 ]]; then
    log "next: reboot, then from tty run: Hyprland"
  fi
}

fresh_root_stage(){
  local user="$1"
  [[ "${EUID:-$(id -u)}" -eq 0 ]] || die "fresh must run as root (use: sudo ./install/bootstrap fresh --user=... )"
  export DEBIAN_FRONTEND=noninteractive

  info "fresh stage: base system packages"
  apt-get update -y

  apt-get install -y --no-install-recommends \
    sudo adduser passwd login \
    util-linux coreutils findutils procps \
    ca-certificates gnupg curl wget \
    locales tzdata \
    git \
    dbus dbus-user-session \
    network-manager openssh-client \
    rfkill pciutils usbutils lsb-release \
    man-db less vim nano \
    fontconfig fonts-dejavu fonts-liberation \
    xdg-user-dirs || true

  apt-get install -y firmware-linux firmware-linux-nonfree firmware-misc-nonfree || true

  systemctl enable NetworkManager --now >/dev/null 2>&1 || true
  if [[ -n "$user" ]]; then
    usermod -aG sudo "$user" >/dev/null 2>&1 || true
    su - "$user" -c "xdg-user-dirs-update" >/dev/null 2>&1 || true
  fi

  ok "fresh stage done"
  warn "reboot recommended if networking or groups were weird"
}

fresh(){
  local user=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --user=*) user="${1#*=}" ;;
      --locale=*) LOCALE="${1#*=}" ;;
      --tz=*) TZ="${1#*=}" ;;
      --yes) YES=1 ;;
      -h|--help) usage; exit 0 ;;
      *) die "unknown arg: $1" ;;
    esac
    shift
  done

  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    die "fresh must run as root (use sudo)"
  fi

  if [[ -z "$user" ]]; then
    user="$(pick_main_user || true)"
  fi

  start_logging
  fresh_root_stage "$user"
  ensure_locale_tz "$LOCALE" "$TZ"

  ok "fresh complete"
  if [[ -n "$user" ]]; then
    warn "now log in as: $user"
    log "then run: ./install/bootstrap apply --profile=$PROFILE_DEFAULT --yes"
  else
    warn "could not determine user automatically"
    log "run apply as your normal user after you log in"
  fi
}

main(){
  case "${CMD:-}" in
    fresh)
      fresh "$@"
      ;;
    plan)
      parse_args "$@"
      if [[ "${EUID:-$(id -u)}" -eq 0 && -z "${OSYX_BOOTSTRAP_REENTERED:-}" ]]; then
        local u
        u="$(pick_main_user || true)"
        [[ -n "$u" ]] || die "run plan as normal user (or set MAIN_USER)"
        reexec_as_user "$u" "plan" "--profile=$PROFILE" "--prefix=$PREFIX" "--locale=$LOCALE" "--tz=$TZ" "${WITH:+--with=$WITH}" $([[ "$NO_HYPR" -eq 1 ]] && echo "--no-hypr") || true
      fi
      plan
      ;;
    apply)
      parse_args "$@"
      if [[ "${EUID:-$(id -u)}" -eq 0 && -z "${OSYX_BOOTSTRAP_REENTERED:-}" ]]; then
        local u
        u="$(pick_main_user || true)"
        [[ -n "$u" ]] || die "run apply as normal user (or set MAIN_USER)"
        local -a a=("apply" "--profile=$PROFILE" "--prefix=$PREFIX" "--locale=$LOCALE" "--tz=$TZ")
        [[ "$YES" -eq 1 ]] && a+=("--yes")
        [[ -n "$WITH" ]] && a+=("--with=$WITH")
        [[ "$NO_HYPR" -eq 1 ]] && a+=("--no-hypr")
        reexec_as_user "$u" "${a[@]}"
      fi
      apply
      ;;
    doctor) doctor ;;
    status) status ;;
    clean) clean "$@" ;;
    ""|help|-h|--help) usage ;;
    *) die "unknown command: $CMD" ;;
  esac
}
