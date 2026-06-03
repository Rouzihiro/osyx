#!/usr/bin/env bash
set -euo pipefail

mkdir -p ~/.local/bin
mkdir -p ~/Pictures/Screenshots

# =============================================================================
# 1. Mac-style Region Capture (F10)
# =============================================================================
cat > ~/.local/bin/shot-mac <<'EOF'
#!/bin/sh

dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
out="$dir/$(date +'%Y-%m-%d_%H-%M-%S').png"

pause_filters() {
  pids=""
  for name in hyprshade gammastep wlsunset redshift; do
    if pgrep -x "$name" >/dev/null 2>&1; then
      pids="$pids $(pgrep -x "$name")"
    fi
  done

  hyprctl keyword decoration:screen_shader "" >/dev/null 2>&1 || true
  [ -n "$pids" ] && kill -STOP $pids 2>/dev/null || true
  usleep 80000 2>/dev/null || sleep 0.08
  export _FILTER_PIDS="${pids# }"
}

resume_filters() {
  [ -n "${_FILTER_PIDS:-}" ] && kill -CONT ${_FILTER_PIDS} 2>/dev/null || true
}

cleanup() { resume_filters; }
trap cleanup EXIT

geom="$(slurp -b '#00000066' -s '#00ffffff' -c '#ffffffff' -w 2)"

pause_filters
usleep 80000 2>/dev/null || sleep 0.08

grim -t png -g "$geom" - \
  | tee "$out" \
  | wl-copy

notify-send "📸 Region Saved + copied" "$out"

if swappy --help 2>/dev/null | grep -q -- '-o'; then
  swappy -f "$out" -o "$out" || true
else
  swappy -f "$out" || true
fi
EOF
chmod +x ~/.local/bin/shot-mac

# =============================================================================
# 2. Instant Full-Screen Capture (F9)
# =============================================================================
cat > ~/.local/bin/shot-full <<'EOF'
#!/bin/sh

dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
out="$dir/$(date +'%Y-%m-%d_%H-%M-%S').png"

pause_filters() {
  pids=""
  for name in hyprshade gammastep wlsunset redshift; do
    if pgrep -x "$name" >/dev/null 2>&1; then
      pids="$pids $(pgrep -x "$name")"
    fi
  done

  hyprctl keyword decoration:screen_shader "" >/dev/null 2>&1 || true
  [ -n "$pids" ] && kill -STOP $pids 2>/dev/null || true
  usleep 80000 2>/dev/null || sleep 0.08
  export _FILTER_PIDS="${pids# }"
}

resume_filters() {
  [ -n "${_FILTER_PIDS:-}" ] && kill -CONT ${_FILTER_PIDS} 2>/dev/null || true
}

cleanup() { resume_filters; }
trap cleanup EXIT

pause_filters
usleep 80000 2>/dev/null || sleep 0.08

# No slurp region selection, just instant full screen capture
grim -t png - \
  | tee "$out" \
  | wl-copy

notify-send "📸 Fullscreen Saved + copied" "$out"
EOF
chmod +x ~/.local/bin/shot-full

# =============================================================================
# 3. Prune script
# =============================================================================
cat > ~/.local/bin/shot-prune-month <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

DIR="${SCREENSHOT_DIR:-$HOME/Pictures/Screenshots}"
DRY_RUN="${DRY_RUN:-0}"

mkdir -p "$DIR"

del() {
  if [ "$DRY_RUN" = "1" ]; then
    find "$DIR" -maxdepth 1 -type f \
      \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
      "$@"
  else
    find "$DIR" -maxdepth 1 -type f \
      \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
      "$@" -print -delete
  fi
}

if date -d "1 month ago" >/dev/null 2>&1 && find --version >/dev/null 2>&1; then
  cutoff="$(date -d "1 month ago" +%F)"
  del ! -newermt "$cutoff"
else
  del -mtime +30
fi
EOF
chmod +x ~/.local/bin/shot-prune-month
