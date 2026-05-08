#!/usr/bin/env bash
# installers, locale/tz, hyprbuild hooks, --with resolution

ensure_bat_alias(){
  if have bat; then return 0; fi
  if have batcat && [[ ! -e /usr/local/bin/bat ]]; then
    as_root mkdir -p /usr/local/bin
    as_root ln -sf "$(command -v batcat)" /usr/local/bin/bat || true
  fi
}

ensure_fd_alias(){
  if have fd; then return 0; fi
  if have fdfind && [[ ! -e /usr/local/bin/fd ]]; then
    as_root mkdir -p /usr/local/bin
    as_root ln -sf "$(command -v fdfind)" /usr/local/bin/fd || true
  fi
}

install_ohmyzsh(){
  apt_install_best_effort zsh git curl ca-certificates

  local omz="$HOME/.oh-my-zsh"
  if [[ -d "$omz" ]]; then
    ok "oh-my-zsh already installed"
  else
    info "installing oh-my-zsh"
    local tmp="$CACHE_DIR/ohmyzsh-install.sh"
    mkdir -p "$CACHE_DIR"
    curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o "$tmp"
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes bash "$tmp" || die "oh-my-zsh install failed"
  fi

  local custom="$omz/custom"
  mkdir -p "$custom/plugins"

  local a="$custom/plugins/zsh-autosuggestions"
  if [[ -d "$a/.git" ]]; then
    ok "zsh-autosuggestions already present"
  else
    info "installing zsh-autosuggestions"
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$a" >/dev/null 2>&1 || die "clone failed: zsh-autosuggestions"
  fi

  local s="$custom/plugins/zsh-syntax-highlighting"
  if [[ -d "$s/.git" ]]; then
    ok "zsh-syntax-highlighting already present"
  else
    info "installing zsh-syntax-highlighting"
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting "$s" >/dev/null 2>&1 || die "clone failed: zsh-syntax-highlighting"
  fi

  ok "oh-my-zsh + plugins installed"
  warn "enable plugins in your .zshrc when you want: zsh-autosuggestions zsh-syntax-highlighting"
}

run_local_script(){
  local rel="$1"
  local p="$REPO_ROOT/$rel"
  [[ -f "$p" ]] || die "missing script: $rel"
  chmod +x "$p" >/dev/null 2>&1 || true
  local first
  first="$(head -n1 "$p" 2>/dev/null || true)"
  if [[ "$first" == *zsh* ]]; then
    apt_install_best_effort zsh
    info "run zsh: $rel"
    zsh "$p"
  else
    info "run bash: $rel"
    bash "$p"
  fi
}

resolve_with_item(){
  local name="$1"
  local p=""
  if [[ -f "$REPO_ROOT/install/arbitrary/$name" ]]; then p="install/arbitrary/$name"; fi
  if [[ -z "$p" && -f "$REPO_ROOT/install/proprietary/$name" ]]; then p="install/proprietary/$name"; fi
  if [[ -z "$p" && -f "$REPO_ROOT/install/misc/$name" ]]; then p="install/misc/$name"; fi
  [[ -n "$p" ]] || return 1
  printf "%s" "$p"
}

apply_with_list(){
  local list="$1"
  [[ -n "$list" ]] || return 0
  local -a items=()
  IFS=',' read -r -a items <<<"$list"
  local it rel
  for it in "${items[@]}"; do
    [[ -n "$it" ]] || continue
    case "$it" in
      ohmyzsh|omz)
        install_ohmyzsh
        continue
        ;;
    esac
    rel="$(resolve_with_item "$it")" || die "unknown --with item: $it"
    run_local_script "$rel"
  done
}

ensure_locale_tz(){
  local loc="$1" tz="$2"
  apt_install_best_effort locales tzdata
  if [[ -n "$loc" ]]; then
    local gen="/etc/locale.gen"
    local lang="${loc%.*}"
    if ! grep -qE "^[[:space:]]*${loc}[[:space:]]+UTF-8" "$gen" 2>/dev/null; then
      as_root bash -lc "printf '%s UTF-8\n' '$lang' >> '$gen' || true"
      as_root bash -lc "printf '%s UTF-8\n' '$loc' >> '$gen' || true"
    fi
    as_root locale-gen >/dev/null 2>&1 || true
    as_root update-locale "LANG=$loc" >/dev/null 2>&1 || true
  fi

  if [[ -n "$tz" ]]; then
    if is_systemd && have timedatectl; then
      as_root timedatectl set-timezone "$tz" >/dev/null 2>&1 || true
    else
      if [[ -e "/usr/share/zoneinfo/$tz" ]]; then
        as_root ln -sf "/usr/share/zoneinfo/$tz" /etc/localtime || true
        printf "%s\n" "$tz" | as_root tee /etc/timezone >/dev/null 2>&1 || true
      fi
    fi
  fi
}

run_hyprbuild_plan(){
  local p="$REPO_ROOT/$HYPRBUILD_REL"
  [[ -f "$p" ]] || { warn "missing $HYPRBUILD_REL"; return 0; }
  chmod +x "$p" >/dev/null 2>&1 || true
  bash "$p" plan --profile="$PROFILE" --prefix="$PREFIX" || true
}

run_hyprbuild_apply(){
  local p="$REPO_ROOT/$HYPRBUILD_REL"
  [[ -f "$p" ]] || die "missing $HYPRBUILD_REL"
  chmod +x "$p" >/dev/null 2>&1 || true
  bash "$p" apply --profile="$PROFILE" --prefix="$PREFIX" --yes
}
