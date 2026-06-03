# Flavors

This is the theming engine. One TOML file controls the visual state of the entire desktop: prompt, multiplexer, compositor borders, notifications, launcher, clipboard picker, editor, git output, file colors, wallpaper, and the login screen.

Everything updates at once, across every open terminal, without touching a single thing manually.

## What it owns

Starship, Tmux, Hyprland border colors, Mako, Wofi, Neovim, Dircolors, Gitconfig log and diff aliases, wallpaper selection, and the Thyx login preset.

What it doesn't own: GTK, Obsidian, Spotify, browser chrome. Those stay manual. If you watched the demos and saw Obsidian matching the palette, I did that manually for the demo. Same for picking a Spotify, for example, Halsey's Badlands album looks perfect for the Malachite theme. Daily use keeps it neutral. My current Obsidian setup uses a black and white palette that works with everything. Flavors covers the desktop. Apps are on you.

Kitty is intentionally excluded. It has a fixed base config: one background, transparency, font, white cursor. I thought about adding it to Flavors but the terminal is supposed to be the neutral canvas everything else renders on. Adding it would break that.

## How it works

```
palette TOML
  ↓
python generator
  ↓
jinja templates
  ↓
generated config files
  ↓
live reload
```

The source files are the palettes and templates. Everything else is a generated output. You edit the palette or the template, run the generator, and the whole environment updates.

```
packages/flavors/
├── palettes/       source palettes
├── base/           jinja templates
├── backgrounds/    wallpaper files
├── generator/      python renderer
├── theme/          zsh runtime
├── generate.py     generator entry point
├── themes.zsh      shell entry point
└── thyx-map.conf   desktop theme to login theme mapping
```

## Palettes

Palettes live in `packages/flavors/palettes/`. Each palette is a TOML file split by target surface:

```toml
[starship]
os_bg = "018a83"
dir_bg = "01736c"
success = "01736c"

[tmux]
pane_border = "001e16"
pane_active_border = "00aaa4"

[hyprland]
active_border = "018a83"
inactive_border = "002a24"

[mako]
bg = "001811"
text = "bdf5ef"
border = "00aaa4"

[wofi]
bg = "00140e"
border = "018a83"

[nvim]
colorscheme = "gruvbox"
bg = "00140e"
fg = "8ed7cf"

[dircolors]
dir = "00aaa4"
archive = "018a83"
orphan = "ff4d6d"
```

Each section is named after the surface it drives. `starship.os_bg` becomes `starship_os_bg` inside templates. `mako.border` becomes `mako_border`. Color values are plain six-character hex without `#`.

The generator also creates helper variants for every color automatically:

| Suffix  | Format                  | Example       |
| ------- | ----------------------- | ------------- |
| (none)  | raw hex                 | `018a83`      |
| `_rgb`  | comma-separated decimal | `1, 138, 131` |
| `_ansi` | semicolon-separated     | `1;138;131`   |

CSS gets RGB. Dircolors gets ANSI. TOML and Lua get raw hex. Every template gets exactly what it needs.

## Templates

Templates live in `packages/flavors/base/`. Each one is a normal config file with palette variables inserted through Jinja.

```
dircolors.j2
gitconfig.j2
hypr.conf.j2
mako.conf.j2
nvim.lua.j2
starship.toml.j2
tmux.conf.j2
wofi.css.j2
```

Example from Hyprland:

```ini
$active_border   = rgba({{ hyprland_active_border }}ff)
$inactive_border = rgba({{ hyprland_inactive_border }}ff)
```

Example from Mako:

```ini
background-color=#{{ mako_bg }}cc
text-color=#{{ mako_text }}
border-color=#{{ mako_border }}
progress-color=#{{ mako_progress }}
```

Example from Wofi:

```css
border: 2px solid rgba({{ wofi_border_rgb }}, 0.4);
color: #{{ wofi_border }};
```

## Generated outputs

The generator writes real config files into `config/`, which is the repo's home-directory mirror.

```
packages/flavors/base/mako.conf.j2       → config/.config/mako/config
packages/flavors/base/starship.toml.j2   → config/.config/starship.toml
packages/flavors/base/dircolors.j2       → config/.dircolors
packages/flavors/base/hypr.conf.j2       → config/.config/hypr/theme.conf
packages/flavors/base/tmux.conf.j2       → config/tmux/current.conf
packages/flavors/base/wofi.css.j2        → config/.config/wofi/style.css
packages/flavors/base/nvim.lua.j2        → config/.config/nvim/lua/theme.lua
packages/flavors/base/gitconfig.j2       → config/.gitconfig.d/theme
```

## Runtime

`themes.zsh` is the runtime orchestrator. Source it from `.zshrc`:

```zsh
source "$HOME/flavors/themes.zsh"
```

That one line gives you the `themes` command, the initial dircolors load, and the live reload machinery across all open terminals. It sources the runtime modules in order:

```
theme/config.zsh
theme/reload.zsh
theme/select.zsh
theme/apply.zsh
```

Running `themes` opens an fzf picker. Pick one and everything updates. `themes rotate` skips the picker and advances to the next palette in sequence.

I have a keybind on Hyprland `ALT + R` that calls that function, so themes change instantly with a keybind.

```ini
bind = ALT, R, exec, zsh -ic 'themes rotate'
```

When a flavor is applied, the full sequence runs:

```
choose flavor
  ↓
generate config files
  ↓
write current theme to ~/.cache/theme.current
  ↓
reload Hyprland    → hyprctl reload
  ↓
reload Mako        → makoctl reload
  ↓
reload Tmux        → tmux source-file ~/.tmux.conf
  ↓
reload Neovim      → :OsyxFlip via RPC socket
  ↓
reload Dircolors   → eval "$(dircolors ~/.dircolors)"
  ↓
apply wallpaper    → swww
  ↓
update Thyx login preset
```

Everything runs in a background subshell. The command returns immediately.

## Live terminal reload

The hard part was making every open terminal update its colors automatically.

Now all zsh terminals update at the same time, which adds a little bit of delay.

The old way was typing `reload` to source `.zshrc`. That only updated the one terminal you were in. Every other open terminal stayed on the old palette.

The current setup installs a `TRAPUSR1` signal handler in every shell that sources `themes.zsh`. When a theme switches, `themes.zsh` sends `SIGUSR1` to every running Zsh process owned by the user.

## Runtime paths

Defaults are defined in `theme/config.zsh`:

```
palettes      $HOME/flavors/palettes
backgrounds   $HOME/flavors/backgrounds
generator     $HOME/flavors/generate.py
thyx map      $HOME/flavors/thyx-map.conf
state file    $HOME/.cache/theme.current
reload file   $HOME/.cache/zsh-reload-trigger
log file      $HOME/.cache/osyx.log
```

The current flavor name is stored in `~/.cache/theme.current`. That file lets `themes rotate` know what comes next.

## Installing

**Prerequisites:** Python 3.11 (for `tomllib`) and Jinja2.

```sh
pip install jinja2
```

Clone the repo and copy Flavors to home:

```sh
git clone https://github.com/rccyx/osyx.git
cp -r osyx/packages/flavors ~/flavors
```

Before you do anything, back up whatever configs you have running. Flavors will overwrite the following:

- `~/.config/starship.toml`
- `~/.dircolors`
- `~/.config/mako/config`
- `~/.config/wofi/style.css`
- `~/tmux/current.conf`

Copy the tool configs:

```sh
mkdir -p ~/tmux
cp osyx/config/.tmux.conf ~/.tmux.conf
cp -r osyx/config/.config/mako ~/.config/mako
cp -r osyx/config/.config/wofi ~/.config/wofi
```

Wire the shell in `.zshrc`:

```zsh
source "$HOME/flavors/themes.zsh"
eval "$(starship init zsh)"
export STARSHIP_CONFIG="$HOME/.config/starship.toml"
```

Wire git:

```sh
git config --global include.path ~/.gitconfig.d/theme
```

Wire Hyprland inside `hyprland.conf`:

```ini
source = ~/.config/hypr/theme.conf
```

Generate and apply:

```sh
python3 ~/flavors/generate.py malachite
source ~/.zshrc
```

Install fonts before anything. Read [fonts](./fonts.md).

## Neovim

Two paths:

**Use my Neovim config.** It's self-contained, bootstraps vim-plug on first launch, and hot-reloads via `:OsyxFlip` when themes switch:

```sh
cp -r osyx/config/.config/nvim ~/.config/nvim
```

**Use your own config.** Simply pick a nvim theme that fits, and wire it in the Python generator

Read [nvim.md](./nvim.md) .

## Thyx matching

Thyx is the SDDM login screen. I keep it visually aligned with the desktop through `packages/flavors/thyx-map.conf`:

```ini
blush=blush
sakura=sakura
malachite=malachite
```

When a flavor is applied, the runtime checks this map and updates the Thyx preset. Anything unmapped falls back to `ash`.
