eval "$(dircolors "$HOME/.dircolors" 2>/dev/null || true)"

_OSYX_RELOAD_FILE="$HOME/.cache/zsh-reload-trigger"

# ─── constants ────────────────────────────────────────────────────────────────
_OSYX_PALETTES_DIR="$HOME/flavors/palettes"
_OSYX_BACKGROUNDS_DIR="$HOME/flavors/backgrounds"
_OSYX_GENERATE_SCRIPT="$HOME/flavors/generate.py"
_OSYX_THYX_MAP="$HOME/flavors/thyx-map.conf"
_OSYX_STATE_FILE="$HOME/.cache/theme.current"
_OSYX_THYX_META="/usr/share/sddm/themes/thyx/metadata.desktop"
_OSYX_THYX_DIR="/usr/share/sddm/themes/thyx"

# fires immediately even when idle at the prompt
TRAPUSR1() {
  [[ -o zle ]] && zle -I
  eval "$(dircolors "$HOME/.dircolors" 2>/dev/null || true)"
  clear
  [[ -o zle ]] && zle reset-prompt 2>/dev/null || true
}

# catches shells that were busy when SIGUSR1 fired
_osyx_autoreload() {
  [[ -f "$_OSYX_RELOAD_FILE" ]] || return 0
  local stamp
  stamp=$(<"$_OSYX_RELOAD_FILE")
  [[ "$stamp" == "${_OSYX_LAST_RELOAD:-}" ]] && return 0
  _OSYX_LAST_RELOAD="$stamp"
  eval "$(dircolors "$HOME/.dircolors" 2>/dev/null || true)"
  clear
  [[ -o zle ]] && zle reset-prompt 2>/dev/null || true
}

# guard against duplicate registration on re-source
if [[ -z "${precmd_functions[(re)_osyx_autoreload]}" ]]; then
  precmd_functions+=(_osyx_autoreload)
fi

# ─── broadcast ────────────────────────────────────────────────────────────────
# stamps a timestamp and kicks every running zsh owned by this user
_osyx_reload_all() {
  mkdir -p "${_OSYX_RELOAD_FILE:h}"
  print -r -- "$(date +%s%N)" >| "$_OSYX_RELOAD_FILE"

  local pid tty
  while read -r pid; do
    tty=$(ps -p "$pid" -o tty= 2>/dev/null | tr -d ' ')
    [[ -z "$tty" || "$tty" == "?" ]] && continue
    kill -USR1 "$pid" 2>/dev/null || true
  done < <(pgrep -u "$USER" zsh 2>/dev/null)
}

# ─── theme switcher ───────────────────────────────────────────────────────────
themes() {
  # build theme list dynamically from palettes dir
  local -a theme_list=()
  if [[ -d "$_OSYX_PALETTES_DIR" ]]; then
    for f in "$_OSYX_PALETTES_DIR"/*.toml(N); do
      local basename="${f##*/}"
      theme_list+=("${basename%%.toml}")
    done
  fi

  if (( ${#theme_list[@]} == 0 )); then
    echo "no palettes found in $_OSYX_PALETTES_DIR" >&2
    return 1
  fi

  _themes_detect_current() {
    [[ -f "$_OSYX_STATE_FILE" ]] || return 1
    local cur="$(<"$_OSYX_STATE_FILE")"
    [[ -n "$cur" ]] && { print -r -- "$cur"; return 0; }
    return 1
  }

  _themes_next_in_list() {
    local cur="$1"
    local i n=${#theme_list[@]} found=0

    for (( i = 1; i <= n; i++ )); do
      if [[ "${theme_list[i]}" == "$cur" ]]; then
        found=1
        break
      fi
    done

    # unknown theme — start from the top
    if (( ! found )); then
      print -r -- "${theme_list[1]}"
      return 0
    fi

    print -r -- "${theme_list[$(( i % n + 1 ))]}"
  }

  local choice=""

  if [[ "$1" == "rotate" ]]; then
    local cur="$(_themes_detect_current 2>/dev/null || true)"
    choice="$(_themes_next_in_list "$cur")"
  else
    if ! command -v fzf >/dev/null 2>&1; then
      echo "fzf not found." >&2
      return 1
    fi
    choice=$(
      printf '%s\n' "${theme_list[@]}" \
      | fzf --prompt='theme > ' --height=40%
    ) || return 1
  fi

  (
    [[ -f "$_OSYX_GENERATE_SCRIPT" ]] && \
      python3 "$_OSYX_GENERATE_SCRIPT" "$choice" >/dev/null 2>&1

    mkdir -p "${_OSYX_STATE_FILE:h}" 2>/dev/null
    print -r -- "$choice" >| "$_OSYX_STATE_FILE" 2>/dev/null || true

    if command -v tmux >/dev/null 2>&1 && tmux list-sessions >/dev/null 2>&1; then
      tmux source-file "$HOME/.tmux.conf" >/dev/null 2>&1 || true
    fi

    if command -v hyprctl >/dev/null 2>&1; then
      hyprctl reload >/dev/null 2>&1 || true
    fi

    if command -v makoctl >/dev/null 2>&1; then
      makoctl reload >/dev/null 2>&1 || true
    else
      pkill -x mako >/dev/null 2>&1 || true
      (mako >/dev/null 2>&1 & disown) >/dev/null 2>&1 || true
    fi

    # nvim 0.10+ — bust cached theme via socket
    if command -v nvim >/dev/null 2>&1; then
      local sock
      for sock in \
        /run/user/$(id -u)/nvim.*.0 \
        /tmp/nvim.${USER}/**/nvim.*.0(N); do
        [[ -S "$sock" ]] || continue
        nvim --server "$sock" --remote-send '<Cmd>OsyxFlip<CR>' >/dev/null 2>&1 || true
      done
    fi

    # wallpaper — try jpg, png, webp in order
    local wallpaper_file=""
    for ext in jpg png webp; do
      if [[ -f "$_OSYX_BACKGROUNDS_DIR/$choice.$ext" ]]; then
        wallpaper_file="$_OSYX_BACKGROUNDS_DIR/$choice.$ext"
        break
      fi
    done

    if [[ -n "$wallpaper_file" ]]; then
      if command -v wallpaper >/dev/null 2>&1; then
        wallpaper set "$wallpaper_file" >/dev/null 2>&1 || true
      elif command -v waypaper >/dev/null 2>&1; then
        waypaper --wallpaper "$wallpaper_file" >/dev/null 2>&1 || true
      fi
    fi

    # look up thyx preset, fall back to ash if not mapped
    if [[ -d "$_OSYX_THYX_DIR" && -f "$_OSYX_THYX_META" ]]; then
      local thyx_preset=""
      if [[ -f "$_OSYX_THYX_MAP" ]]; then
        thyx_preset=$(grep -E "^${choice}=" "$_OSYX_THYX_MAP" 2>/dev/null | cut -d= -f2)
      fi
      thyx_preset="${thyx_preset:-ash}"

      local line="ConfigFile=themes/$thyx_preset.conf"
      if [[ -w "$_OSYX_THYX_META" ]]; then
        if grep -q '^ConfigFile=' "$_OSYX_THYX_META" 2>/dev/null; then
          sed -i "s|^ConfigFile=.*$|$line|" "$_OSYX_THYX_META"
        else
          printf '\n%s\n' "$line" >> "$_OSYX_THYX_META"
        fi
      elif command -v sudo >/dev/null 2>&1 && sudo test -w "$_OSYX_THYX_META" 2>/dev/null; then
        if sudo grep -q '^ConfigFile=' "$_OSYX_THYX_META" 2>/dev/null; then
          sudo sed -i "s|^ConfigFile=.*$|$line|" "$_OSYX_THYX_META"
        else
          printf '%s\n' "$line" | sudo tee -a "$_OSYX_THYX_META" >/dev/null
        fi
      fi
    fi

    _osyx_reload_all >/dev/null 2>&1
  ) &!
}