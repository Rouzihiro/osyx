from __future__ import annotations

from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parents[1]
ROOT_DIR = SCRIPT_DIR.parent
FLAVORS_DIR = ROOT_DIR / "flavors"
BASE_DIR = FLAVORS_DIR / "base"
PALETTES_DIR = FLAVORS_DIR / "palettes"

OUTPUTS = {
    "mako.conf.j2": ".config/mako/config",
    "starship.toml.j2": ".config/starship.toml",
    "dircolors.j2": ".dircolors",
    "hypr.conf.j2": ".config/hypr/theme.conf",
    "tmux.conf.j2": ".tmux.conf",
    "wofi.css.j2": ".config/wofi/style.css",
    "nvim.lua.j2": ".config/nvim/lua/theme.lua",
    "gitconfig.j2": ".gitconfig.d/theme",
}
