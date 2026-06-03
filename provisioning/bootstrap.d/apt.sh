#!/usr/bin/env bash
# apt + dpkg helpers

APT_UPDATED=0
apt_update_once(){
  if [[ "$APT_UPDATED" -eq 0 ]]; then
    as_root apt-get update -yq || true
    APT_UPDATED=1
  fi
}

apt_pkg_exists(){
  apt-cache show "$1" >/dev/null 2>&1
}

apt_install_pkgs(){
  local -a pkgs=("$@")
  [[ "${#pkgs[@]}" -gt 0 ]] || return 0
  apt_update_once
  as_root apt-get install -y --no-install-recommends "${pkgs[@]}"
}

apt_install_best_effort(){
  local p
  apt_update_once
  for p in "$@"; do
    if apt_pkg_exists "$p"; then
      as_root apt-get install -y --no-install-recommends "$p" >/dev/null 2>&1 || warn "apt failed: $p"
    else
      warn "apt missing package: $p"
    fi
  done
}

dpkg_installed(){
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"
}
