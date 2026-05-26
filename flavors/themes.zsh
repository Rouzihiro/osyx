eval "$(dircolors "$HOME/.dircolors" 2>/dev/null || true)"

_OSYX_RELOAD_FILE="$HOME/.cache/zsh-reload-trigger"

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
  local root="$HOME"
  local state_file="$root/.cache/theme.current"
  local thyx_dir="/usr/share/sddm/themes/thyx"
  local thyx_meta="$thyx_dir/metadata.desktop"
  local palettes_dir="$root/flavors/palettes"

  local -a theme_list=()
  if [[ -d "$palettes_dir" ]]; then
    for f in "$palettes_dir"/*.toml(N); do
      local basename="${f##*/}"
      theme_list+=("${basename%%.toml}")
    done
  fi

  # fallback list if no palettes dir exists
  if (( ${#theme_list[@]} == 0 )); then
    theme_list=(
      umber nimbus cobalt gilded canopy indigo malachite garnet blush sakura flush ash
    )
  fi

  _themes_detect_current() {
    local cur=""
    if [[ -f "$state_file" ]]; then
      cur="$(<"$state_file")"
      [[ -n "$cur" ]] && { print -r -- "$cur"; return 0; }
    fi
    return 1
  }

  _themes_next_in_list() {
    local cur="$1"
    local i=1 n=${#theme_list[@]}
    local found=0

    for (( i = 1; i <= n; i++ )); do
      if [[ "${theme_list[i]}" == "$cur" ]]; then
        found=1
        break
      fi
    done

    # unknown theme — just start from the top
    if (( ! found )); then
      print -r -- "${theme_list[1]}"
      return 0
    fi

    local next=$(( i % n + 1 ))
    print -r -- "${theme_list[next]}"
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
    local generate_script="$root/flavors/generate.py"
    if [[ -f "$generate_script" ]]; then
      python3 "$generate_script" "$choice" >/dev/null 2>&1
    fi

    mkdir -p "${state_file:h}" 2>/dev/null || mkdir -p "$root/.cache"
    print -r -- "$choice" >| "$state_file" 2>/dev/null || true

    if command -v tmux >/dev/null 2>&1 && tmux list-sessions >/dev/null 2>&1; then
      tmux source-file "$root/.tmux.conf" >/dev/null 2>&1 || true
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

    # nvim 0.10+ exposes a socket per instance — send OsyxFlip to bust the cached theme
    if command -v nvim >/dev/null 2>&1; then
      local sock
      for sock in \
        /run/user/$(id -u)/nvim.*.0 \
        /tmp/nvim.${USER}/**/nvim.*.0(N); do
        [[ -S "$sock" ]] || continue
        nvim --server "$sock" --remote-send '<Cmd>OsyxFlip<CR>' >/dev/null 2>&1 || true
      done
    fi

    local wallpaper_file=""
    for ext in jpg png webp; do
      if [[ -f "$root/flavors/backgrounds/$choice.$ext" ]]; then
        wallpaper_file="$root/flavors/backgrounds/$choice.$ext"
        break
      fi
    done

    if [[ -n "$wallpaper_file" ]] && command -v wallpaper >/dev/null 2>&1; then
      wallpaper set "$wallpaper_file" >/dev/null 2>&1 || true
    elif [[ -n "$wallpaper_file" ]] && command -v waypaper >/dev/null 2>&1; then
      waypaper --wallpaper "$wallpaper_file" >/dev/null 2>&1 || true
    fi

    # map theme names to thyx presets (not always 1:1)
    local thyx_preset=""
    case "$choice" in
      umber)      thyx_preset="umber"     ;;
      catppuccin) thyx_preset="sakura"    ;;
      canopy)     thyx_preset="malachite" ;;
      malachite)  thyx_preset="malachite" ;;
      indigo)     thyx_preset="cobalt"    ;;
      cobalt)     thyx_preset="cobalt"    ;;
      nimbus)     thyx_preset="cobalt"    ;;
      garnet)     thyx_preset="rose"      ;;
      flush)      thyx_preset="rose"      ;;
      blush)      thyx_preset="blush"     ;;
      sakura)     thyx_preset="sakura"    ;;
      gilded)     thyx_preset="gilded"    ;;
      ash)        thyx_preset="ash"       ;;
    esac

    if [[ -n "$thyx_preset" && -d "$thyx_dir" && -f "$thyx_meta" ]]; then
      local line="ConfigFile=themes/$thyx_preset.conf"
      if [[ -w "$thyx_meta" ]]; then
        if grep -q '^ConfigFile=' "$thyx_meta" 2>/dev/null; then
          sed -i "s|^ConfigFile=.*$|$line|" "$thyx_meta"
        else
          printf '\n%s\n' "$line" >> "$thyx_meta"
        fi
      elif command -v sudo >/dev/null 2>&1; then
        if sudo test -w "$thyx_meta" 2>/dev/null; then
          if sudo grep -q '^ConfigFile=' "$thyx_meta" 2>/dev/null; then
            sudo sed -i "s|^ConfigFile=.*$|$line|" "$thyx_meta"
          else
            printf '%s\n' "$line" | sudo tee -a "$thyx_meta" >/dev/null
          fi
        fi
      fi
    fi

    _osyx_reload_all >/dev/null 2>&1
  ) &!
}