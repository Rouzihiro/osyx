#!/usr/bin/env bash
# core utilities (logging, colors, paths, basic helpers)

C_RESET="$(tput sgr0 2>/dev/null || true)"
C_BOLD="$(tput bold 2>/dev/null || true)"
C_DIM="$(tput dim 2>/dev/null || true)"
C_RED="$(tput setaf 1 2>/dev/null || true)"
C_GRN="$(tput setaf 2 2>/dev/null || true)"
C_YLW="$(tput setaf 3 2>/dev/null || true)"
C_BLU="$(tput setaf 4 2>/dev/null || true)"

log(){ printf "%s\n" "$*"; }
info(){ printf "%s%s%s %s\n" "$C_BLU" "[info]" "$C_RESET" "$*"; }
ok(){ printf "%s%s%s %s\n" "$C_GRN" "[ok]" "$C_RESET" "$*"; }
warn(){ printf "%s%s%s %s\n" "$C_YLW" "[warn]" "$C_RESET" "$*"; }
err(){ printf "%s%s%s %s\n" "$C_RED" "[err]" "$C_RESET" "$*" >&2; }
die(){ err "$*"; exit 1; }

trap 'err "failed at line $LINENO: $BASH_COMMAND"' ERR

have(){ command -v "$1" >/dev/null 2>&1; }
is_debian(){ [[ -f /etc/debian_version ]]; }
is_systemd(){ [[ -d /run/systemd/system ]]; }

mk_dirs(){
  mkdir -p "$STATE_DIR" "$CACHE_DIR" "$LOG_DIR"
}

now_stamp(){ date +"%Y%m%d-%H%M%S"; }

start_logging(){
  mk_dirs
  local runlog="$LOG_DIR/$(now_stamp)-${CMD:-noop}.log"
  if { : >> "$runlog"; } 2>/dev/null; then
    exec > >(tee -a "$runlog") 2>&1
  else
    runlog="disabled ($runlog not writable)"
  fi
  log "${C_BOLD}bootstrap${C_RESET} v$VERSION"
  log "repo:   $REPO_ROOT"
  log "cmd:    ${CMD:-}"
  log "user:   ${USER:-$(id -un 2>/dev/null || echo unknown)}"
  log "uid:    $(id -u)"
  log "os:     $(. /etc/os-release 2>/dev/null && echo "${PRETTY_NAME:-unknown}" || echo unknown)"
  log "code:   $(detect_codename 2>/dev/null || true)"
  log "profile:$PROFILE"
  log "prefix: $PREFIX"
  log "locale: $LOCALE"
  log "tz:     $TZ"
  log "with:   ${WITH:-}"
  log "hypr:   $([[ "${NO_HYPR:-0}" -eq 1 ]] && echo "skip" || echo "install")"
  log "log:    $runlog"
  log ""
}
