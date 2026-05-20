#!/usr/bin/env zsh
# enable-clipboard.zsh - Wayland/Hyprland clipboard: clipvault as single source of truth.
# - no systemd
# - idempotent
# - patches hyprland.conf automatically (removes cliphist + old clipboard binds, injects clipvault block)

emulate -L zsh
setopt err_return no_unset pipefail

: "${BIN_DIR:=$HOME/.local/bin}"
: "${STATE_DIR:=$HOME/.local/state/clipvault-setup}"
: "${CACHE_DIR:=$HOME/.cache/clipvault}"

: "${CLIP_CAP:=200}"
: "${CLEAR_DAYS:=3}"

# This is the manager tick for the watchdog loop (not clipboard capture speed).
# Capture is event-driven via wl-paste --watch.
: "${POLL_MS:=1500}"

# Run pruning and periodic clear checks at sane intervals.
: "${PRUNE_EVERY_S:=10}"
: "${CLEAR_CHECK_EVERY_S:=30}"

# Optional: if your session sometimes wedges after suspend, set this to e.g. 120
: "${RESTART_WLPASTE_EVERY_S:=0}"

WATCH="$BIN_DIR/clipvault-watchers"
KICK="$BIN_DIR/clipvault-kick"
PICK_FZF="$BIN_DIR/clipvault-fzf"
PICK_WOFI="$BIN_DIR/clipvault-wofi"
PRUNE_CAP="$BIN_DIR/clipvault-prune-cap"
PERIODIC_CLEAR_STAMP="$STATE_DIR/last_clear.ts"

SNIP_HYPR="$STATE_DIR/snippet.hyprland.conf"
SNIP_SHELL="$STATE_DIR/snippet.shell.sh"

blue(){ print -P "%F{4}[*]%f $*"; }
ok(){   print -P "%F{2}[ok]%f $*"; }
warn(){ print -P "%F{3}[warn]%f $*"; }
err(){  print -P "%F{1}[err]%f $*"; exit 1; }
have(){ command -v "$1" >/dev/null 2>&1; }
need_user(){ [[ $EUID -ne 0 ]] || err "run as your user, not root"; }
mkdirp(){ [[ -d "$1" ]] || mkdir -p "$1"; }
make_exec(){ chmod +x "$1" || err "chmod +x $1 failed"; }

assert_env(){
  if [[ -z "${WAYLAND_DISPLAY:-}" || -z "${XDG_RUNTIME_DIR:-}" ]]; then
    warn "not in a wayland session shell (ok). hyprland exec-once will start watchers when you log in."
  fi
  have wl-paste || err "wl-clipboard missing (need wl-paste/wl-copy)"
  have wl-copy  || err "wl-clipboard missing (need wl-paste/wl-copy)"
}

ensure_clipvault(){
  if have clipvault; then
    ok "clipvault present"
    return 0
  fi
  if ! have cargo; then
    err "clipvault missing and cargo not found. install cargo or provide clipvault in PATH"
  fi
  blue "installing clipvault with cargo"
  cargo install clipvault --locked || err "cargo install clipvault failed"
  ok "clipvault installed"
}

detect_hypr_conf(){
  local cand
  local -a cands
  cands=()

  if [[ -n "${HYPRLAND_CONF:-}" ]]; then
    cands+=("$HYPRLAND_CONF")
  fi

  cands+=(
    "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprland.conf"
    "$HOME/.config/hypr/hyprland.conf"
    "$HOME/personal/projects/osyx/.config/hypr/hyprland.conf"
    "$HOME/personal/projects/osyx/.config/hyprland/hyprland.conf"
  )

  for cand in $cands; do
    if [[ -f "$cand" ]]; then
      print -r -- "$cand"
      return 0
    fi
  done

  print -r -- ""
  return 0
}

write_prune_cap(){
  mkdirp "$BIN_DIR"
  cat > "$PRUNE_CAP" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

CAP="${CLIP_CAP:-200}"

count="$(clipvault list | wc -l | tr -d ' ')"
if [ "${count:-0}" -le "$CAP" ]; then
  exit 0
fi

to_delete=$(( count - CAP ))
i=0
while [ "$i" -lt "$to_delete" ]; do
  clipvault delete --index -1 >/dev/null 2>&1 || true
  i=$(( i + 1 ))
done
SH
  make_exec "$PRUNE_CAP"
  ok "prune-by-cap helper -> $PRUNE_CAP"
}

write_watchers(){
  mkdirp "$BIN_DIR" "$STATE_DIR"
  cat > "$WATCH" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

export CLIP_CAP="${CLIP_CAP:-200}"
export CLEAR_DAYS="${CLEAR_DAYS:-3}"
export POLL_MS="${POLL_MS:-1500}"
export PRUNE_EVERY_S="${PRUNE_EVERY_S:-10}"
export CLEAR_CHECK_EVERY_S="${CLEAR_CHECK_EVERY_S:-30}"
export RESTART_WLPASTE_EVERY_S="${RESTART_WLPASTE_EVERY_S:-0}"

PRUNE_CAP="${PRUNE_CAP:-$HOME/.local/bin/clipvault-prune-cap}"
STAMP="${PERIODIC_CLEAR_STAMP:-$HOME/.local/state/clipvault-setup/last_clear.ts}"

need(){ command -v "$1" >/dev/null 2>&1 || { echo "$1 missing" >&2; exit 1; }; }
need wl-paste
need clipvault

mkdir -p "$(dirname "$STAMP")" 2>/dev/null || true

lock="${XDG_RUNTIME_DIR:-/tmp}/clipvault-watchers.lock"
exec 9>"$lock" || exit 1
if command -v flock >/dev/null 2>&1; then
  flock -n 9 || exit 0
fi

is_text_running(){
  pgrep -fa "wl-paste .*--type text .*clipvault store" >/dev/null 2>&1
}
is_image_running(){
  pgrep -fa "wl-paste .*--type image .*clipvault store" >/dev/null 2>&1
}

kill_all_wlpaste(){
  pkill -f "wl-paste .*clipvault store" >/dev/null 2>&1 || true
}

start_text(){
  setsid -f sh -c "wl-paste --type text --watch clipvault store --ignore-pattern '^<meta http-equiv=' >/dev/null 2>&1" >/dev/null 2>&1 || true
}
start_image(){
  setsid -f sh -c "wl-paste --type image --watch clipvault store >/dev/null 2>&1" >/dev/null 2>&1 || true
}

start_if_missing(){
  is_text_running || start_text
  is_image_running || start_image
}

periodic_clear_if_due(){
  if [ "${CLEAR_DAYS:-0}" -le 0 ]; then
    return 0
  fi
  now="$(date +%s)"
  ts="$(cat "$STAMP" 2>/dev/null || echo 0)"
  ts="${ts:-0}"
  need=$(( CLEAR_DAYS * 86400 ))
  age=$(( now - ts ))
  if [ "$age" -ge "$need" ]; then
    clipvault clear >/dev/null 2>&1 || true
    echo "$now" > "$STAMP" 2>/dev/null || true
  fi
}

maybe_force_restart(){
  every="${RESTART_WLPASTE_EVERY_S:-0}"
  if [ "$every" -le 0 ]; then
    return 0
  fi
  now="$(date +%s)"
  if [ -z "${LAST_FORCE_RESTART:-}" ]; then
    LAST_FORCE_RESTART="$now"
    return 0
  fi
  if [ $(( now - LAST_FORCE_RESTART )) -ge "$every" ]; then
    LAST_FORCE_RESTART="$now"
    kill_all_wlpaste
    start_if_missing
  fi
}

start_if_missing

last_prune=0
last_clear_check=0

while :; do
  start_if_missing
  maybe_force_restart

  now="$(date +%s)"

  if [ "${PRUNE_EVERY_S:-0}" -gt 0 ] && [ $(( now - last_prune )) -ge "${PRUNE_EVERY_S}" ]; then
    last_prune="$now"
    [ -x "$PRUNE_CAP" ] && "$PRUNE_CAP" || :
  fi

  if [ "${CLEAR_CHECK_EVERY_S:-0}" -gt 0 ] && [ $(( now - last_clear_check )) -ge "${CLEAR_CHECK_EVERY_S}" ]; then
    last_clear_check="$now"
    periodic_clear_if_due
  fi

  tick_ms="${POLL_MS:-1500}"
  perl -e "select(undef,undef,undef,(${tick_ms}/1000))" 2>/dev/null || sleep 1
done
SH
  make_exec "$WATCH"
  ok "watchers -> $WATCH"
}

write_kick(){
  mkdirp "$BIN_DIR"
  cat > "$KICK" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
WATCH="${WATCH:-$BIN_DIR/clipvault-watchers}"

pkill -f 'clipvault-watchers' >/dev/null 2>&1 || true
pkill -f 'wl-paste .*clipvault store' >/dev/null 2>&1 || true

nohup env \
  CLIP_CAP="${CLIP_CAP:-200}" \
  CLEAR_DAYS="${CLEAR_DAYS:-3}" \
  POLL_MS="${POLL_MS:-1500}" \
  PRUNE_EVERY_S="${PRUNE_EVERY_S:-10}" \
  CLEAR_CHECK_EVERY_S="${CLEAR_CHECK_EVERY_S:-30}" \
  RESTART_WLPASTE_EVERY_S="${RESTART_WLPASTE_EVERY_S:-0}" \
  PRUNE_CAP="${PRUNE_CAP:-$HOME/.local/bin/clipvault-prune-cap}" \
  PERIODIC_CLEAR_STAMP="${PERIODIC_CLEAR_STAMP:-$HOME/.local/state/clipvault-setup/last_clear.ts}" \
  "$WATCH" >/tmp/clipvault-watchers.log 2>&1 &

exit 0
SH
  make_exec "$KICK"
  ok "kick helper -> $KICK"
}

write_fzf_picker(){
  have fzf || { warn "fzf not found. skipping fzf picker"; return 0; }
  cat > "$PICK_FZF" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
need(){ command -v "$1" >/dev/null 2>&1 || { echo "$1 missing" >&2; exit 1; }; }
need clipvault; need wl-copy; need fzf

sel="$(clipvault list | fzf --no-sort -d $'\t' --with-nth 2 --prompt='clip> ' || true)"
[ -n "${sel:-}" ] || exit 0

clipvault get <<< "$sel" | wl-copy
SH
  make_exec "$PICK_FZF"
  ok "fzf picker -> $PICK_FZF"
}

write_wofi_picker(){
  have wofi || { warn "wofi not found. skipping wofi picker"; return 0; }
  cat > "$PICK_WOFI" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
need(){ command -v "$1" >/dev/null 2>&1 || { echo "$1 missing" >&2; exit 1; }; }
need clipvault; need wl-copy; need wofi

lock="${XDG_RUNTIME_DIR:-/tmp}/clipvault-wofi.lock"

pick(){
  clipvault list | wofi \
    --dmenu \
    --prompt 'clip> ' \
    --cache-file /dev/null \
    --sort-order default \
    --pre-display-cmd "echo '%s' | cut -f 2" \
    || true
}

if command -v flock >/dev/null 2>&1; then
  exec 9>"$lock"
  flock -n 9 || exit 0
  sel="$(pick)"
  exec 9>&-
else
  sel="$(pick)"
fi

[ -n "${sel:-}" ] || exit 0
clipvault get <<< "$sel" | wl-copy
SH
  make_exec "$PICK_WOFI"
  ok "wofi picker -> $PICK_WOFI"
}

write_snippets(){
  mkdirp "$STATE_DIR"

  cat > "$SNIP_HYPR" <<EOF
# >>> clipvault managed (enable-clipboard.zsh)
# Clipboard: clipvault as single source of truth.
# Event-driven capture via wl-paste --watch, with a lightweight manager.
exec-once = env CLIP_CAP=${CLIP_CAP} CLEAR_DAYS=${CLEAR_DAYS} POLL_MS=${POLL_MS} PRUNE_EVERY_S=${PRUNE_EVERY_S} CLEAR_CHECK_EVERY_S=${CLEAR_CHECK_EVERY_S} RESTART_WLPASTE_EVERY_S=${RESTART_WLPASTE_EVERY_S} PRUNE_CAP=${PRUNE_CAP} PERIODIC_CLEAR_STAMP=${PERIODIC_CLEAR_STAMP} ${WATCH}

# Clipboard menu + kick (use kick after suspend/resume if something wedges)
bind = \$mod, x, exec, ${PICK_WOFI}
bind = \$mod SHIFT, x, exec, env CLIP_CAP=${CLIP_CAP} CLEAR_DAYS=${CLEAR_DAYS} POLL_MS=${POLL_MS} PRUNE_EVERY_S=${PRUNE_EVERY_S} CLEAR_CHECK_EVERY_S=${CLEAR_CHECK_EVERY_S} RESTART_WLPASTE_EVERY_S=${RESTART_WLPASTE_EVERY_S} PRUNE_CAP=${PRUNE_CAP} PERIODIC_CLEAR_STAMP=${PERIODIC_CLEAR_STAMP} ${KICK}
# <<< clipvault managed (enable-clipboard.zsh)
EOF

  cat > "$SNIP_SHELL" <<EOF
nohup env CLIP_CAP=${CLIP_CAP} CLEAR_DAYS=${CLEAR_DAYS} POLL_MS=${POLL_MS} PRUNE_EVERY_S=${PRUNE_EVERY_S} CLEAR_CHECK_EVERY_S=${CLEAR_CHECK_EVERY_S} RESTART_WLPASTE_EVERY_S=${RESTART_WLPASTE_EVERY_S} PRUNE_CAP=${PRUNE_CAP} PERIODIC_CLEAR_STAMP=${PERIODIC_CLEAR_STAMP} ${WATCH} >/tmp/clipvault-watchers.log 2>&1 &
EOF

  ok "snippets written:"
  ok "  $SNIP_HYPR"
  ok "  $SNIP_SHELL"
}

patch_hyprland_conf(){
  local conf="$1"
  [[ -n "$conf" ]] || { warn "hyprland.conf not found; leaving only snippet at $SNIP_HYPR"; return 0; }
  [[ -f "$conf" ]] || { warn "hyprland.conf not found; leaving only snippet at $SNIP_HYPR"; return 0; }

  mkdirp "$STATE_DIR"

  perl -0777 -i -pe 's/\n?# >>> clipvault managed \(.*?\).*?# <<< clipvault managed \(.*?\)\n?/\n/s' "$conf" 2>/dev/null || true

  perl -i -ne '
    next if /^\s*exec-once\s*=\s*.*(cliphist-watchers|clipvault-watchers)\b/;
    next if /^\s*bind\s*=.*\b(clip-wofi|cliphist|clipvault-wofi)\b/;
    print;
  ' "$conf" 2>/dev/null || err "failed to edit $conf"

  cat >> "$conf" <<EOF

# >>> clipvault managed (enable-clipboard.zsh)
# Clipboard: clipvault as single source of truth.
exec-once = env CLIP_CAP=${CLIP_CAP} CLEAR_DAYS=${CLEAR_DAYS} POLL_MS=${POLL_MS} PRUNE_EVERY_S=${PRUNE_EVERY_S} CLEAR_CHECK_EVERY_S=${CLEAR_CHECK_EVERY_S} RESTART_WLPASTE_EVERY_S=${RESTART_WLPASTE_EVERY_S} PRUNE_CAP=${PRUNE_CAP} PERIODIC_CLEAR_STAMP=${PERIODIC_CLEAR_STAMP} ${WATCH}

bind = \$mod, x, exec, ${PICK_WOFI}
bind = \$mod SHIFT, x, exec, env CLIP_CAP=${CLIP_CAP} CLEAR_DAYS=${CLEAR_DAYS} POLL_MS=${POLL_MS} PRUNE_EVERY_S=${PRUNE_EVERY_S} CLEAR_CHECK_EVERY_S=${CLEAR_CHECK_EVERY_S} RESTART_WLPASTE_EVERY_S=${RESTART_WLPASTE_EVERY_S} PRUNE_CAP=${PRUNE_CAP} PERIODIC_CLEAR_STAMP=${PERIODIC_CLEAR_STAMP} ${KICK}
# <<< clipvault managed (enable-clipboard.zsh)
EOF

  ok "hyprland patched -> $conf"

  if have hyprctl && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    hyprctl reload >/dev/null 2>&1 || true
    ok "hyprctl reload"
  fi
}

periodic_clear(){
  mkdirp "$STATE_DIR"
  local now ts age
  now="$(date +%s)"
  if [[ -s "$PERIODIC_CLEAR_STAMP" ]]; then
    ts="$(<"$PERIODIC_CLEAR_STAMP")"
  else
    ts=0
  fi
  local need=$(( CLEAR_DAYS * 86400 ))
  age=$(( now - ts ))
  if (( CLEAR_DAYS > 0 && age >= need )); then
    blue "periodic clear: wiping clipvault DB (>${CLEAR_DAYS} days since last wipe)"
    clipvault clear >/dev/null 2>&1 || true
    print -- "$now" > "$PERIODIC_CLEAR_STAMP"
    ok "cleared clipvault DB"
  else
    ok "periodic clear not due"
  fi
}

start_watchers_now(){
  if pgrep -fa 'clipvault-watchers' >/dev/null 2>&1; then
    ok "watcher manager already running"
    return 0
  fi
  if [[ -z "${WAYLAND_DISPLAY:-}" || -z "${XDG_RUNTIME_DIR:-}" ]]; then
    warn "no wayland env in this shell (fine). it will start via hyprland exec-once next login"
    return 0
  fi

  nohup env \
    CLIP_CAP="$CLIP_CAP" CLEAR_DAYS="$CLEAR_DAYS" POLL_MS="$POLL_MS" PRUNE_EVERY_S="$PRUNE_EVERY_S" CLEAR_CHECK_EVERY_S="$CLEAR_CHECK_EVERY_S" RESTART_WLPASTE_EVERY_S="$RESTART_WLPASTE_EVERY_S" \
    PRUNE_CAP="$PRUNE_CAP" PERIODIC_CLEAR_STAMP="$PERIODIC_CLEAR_STAMP" \
    "$WATCH" >/tmp/clipvault-watchers.log 2>&1 &
  ok "watcher manager started"
}

status(){
  print -P "%F{6}== clipvault sample ==%f"
  clipvault list | head -n 10 2>/dev/null || true
  print -P "%F{6}== newest ==%f"
  clipvault get --index 0 2>/dev/null | head -c 200 || true
  echo
  print -P "%F{6}== processes ==%f"
  pgrep -fa 'clipvault-watchers' || true
  pgrep -fa 'wl-paste .*clipvault store' || true
  print -P "%F{6}== pickers ==%f"
  [ -x "$PICK_FZF" ]  && echo "$PICK_FZF"  || true
  [ -x "$PICK_WOFI" ] && echo "$PICK_WOFI" || true
}

hint(){
  write_snippets >/dev/null 2>&1 || true
  print -- ""
  print -- "hyprland snippet:"
  print -- ""
  cat "$SNIP_HYPR" 2>/dev/null || true
  print -- ""
  print -- "generic shell snippet:"
  print -- ""
  cat "$SNIP_SHELL" 2>/dev/null || true
}

setup(){
  need_user
  assert_env
  ensure_clipvault
  mkdirp "$BIN_DIR" "$STATE_DIR" "$CACHE_DIR"

  write_prune_cap
  write_watchers
  write_kick
  write_fzf_picker
  write_wofi_picker
  write_snippets

  local hypr_conf
  hypr_conf="$(detect_hypr_conf || true)"
  patch_hyprland_conf "$hypr_conf"

  periodic_clear
  start_watchers_now

  ok "setup complete"
}

destroy(){
  need_user
  pkill -f 'clipvault-watchers' 2>/dev/null || true
  pkill -f 'wl-paste .*clipvault store' 2>/dev/null || true

  rm -f "$WATCH" "$KICK" "$PICK_FZF" "$PICK_WOFI" "$PRUNE_CAP"
  rm -f "$SNIP_HYPR" "$SNIP_SHELL"

  ok "removed helper binaries from $BIN_DIR"
  ok "leaving your clipvault DB intact. run reset to wipe"
}

reset(){
  need_user
  pkill -f 'clipvault-watchers' 2>/dev/null || true
  pkill -f 'wl-paste .*clipvault store' 2>/dev/null || true
  clipvault clear >/dev/null 2>&1 || true
  : > "$PERIODIC_CLEAR_STAMP" 2>/dev/null || true
  ok "wiped clipvault DB"
}

usage(){
  cat <<EOF
usage:
  $0 setup      install helpers, patch hyprland.conf, write snippets, start watcher manager (if in wayland)
  $0 destroy    stop watcher manager and remove helpers (keeps DB)
  $0 status     show processes and recent entries
  $0 reset      wipe clipvault DB
  $0 hint       print compositor/login snippets
env (optional):
  HYPRLAND_CONF=...                 force which hyprland.conf to patch
  CLIP_CAP=$CLIP_CAP
  CLEAR_DAYS=$CLEAR_DAYS
  POLL_MS=$POLL_MS                  # manager tick (ms), capture is event-driven
  PRUNE_EVERY_S=$PRUNE_EVERY_S
  CLEAR_CHECK_EVERY_S=$CLEAR_CHECK_EVERY_S
  RESTART_WLPASTE_EVERY_S=$RESTART_WLPASTE_EVERY_S
EOF
}

case "${1:-}" in
  setup)   setup ;;
  destroy) destroy ;;
  status)  status ;;
  reset)   reset ;;
  hint)    hint ;;
  *) usage; exit 1 ;;
esac
