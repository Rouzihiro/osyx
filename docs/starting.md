# Starting

So you're probably wondering:

```text
Can I use this?
What do I copy?
How do I make my setup look like that?
```

Yes, you can use pieces of it today.

The full public one-command install is not available yet, so the right way to approach this repo is component extraction. Take the parts that are portable, understand the parts that are personal, and treat generated files as output.

## What you're looking at

There is no desktop environment. You boot in, Hyprland starts, and Hyprland is empty. No panels, no app launchers, no system tray. Just a tiling window manager. The desktop is whatever you launch into it.

What makes it look the way it does in the demos is entirely these programs working together.

1. [Fonts](./fonts.md)
2. [Flavors](./flavors.md)
3. [Zsh](./zsh.md)
4. [Starship](./starship.md)
5. [Tmux](./tmux.md)
6. [Dircolors](./dircolors.md)
7. [Hyprland](./hypr.md)
8. [Mako](./mako.md)
9. [Wofi](./wofi.md)
10. [Neovim](./nvim.md)

> [!NOTE]
> A top bar is basically redundant here. Starship already tells time. Event driven notifications surface critical system vitals (thermals, battery, etc).

## The rule

This repo mirrors my real working setup, but the public repo only exposes the parts that are safe enough to share.

The convention is:

```text
normal files      portable layer
underscore files  personal layer
generated files   output layer
```

Normal files are meant to be copied or studied directly.

Underscore files are real workflow files, but they may contain my monitor names, my weird keyboard layout, app paths, startup layout, local binaries, generated paths, hardware assumptions, or personal keybinds, etc.

Example from Hyprland:

```text
keybinds.conf      portable
startup.conf       portable
variables.conf     portable

_keybinds.conf     personal
_startup.conf      personal
_variables.conf    personal
_clipboard.conf    generated / machine-local
```

> [!IMPORTANT]
> Generated files are written by scripts. Edit the source that generates them.

## What to copy first

### 1. Fonts

[fonts.md](./ui/fonts.md)

Fonts come first because the screenshots depend on exact font routing.

The font setup installs Inter, Iosevka Fixed SS18, and Meslo, then Fontconfig routes them correctly so browsers, terminals, notifications, launchers, and glyphs render the same way.

### 2. Flavors

[flavors.md](./ui/flavors.md)

Flavors is the palette engine.

One palette changes Starship, Tmux, Hyprland borders, Mako, Wofi, Dircolors, Neovim, Git output, and the wallpaper.

Currently WIP, but will (very soon) be released.

And the way it works is this:

```text
flavors/
├── backgrounds/
├── base/
├── palettes/
├── generate.py
└── themes.zsh
```

The model:

```text
palette TOML
  ↓
generate.py
  ↓
Jinja templates
  ↓
generated config files
  ↓
live reload
```

Palettes live here:

```text
flavors/palettes/
```

Templates live here:

```text
flavors/base/
```

Wallpapers live here:

```text
flavors/backgrounds/
```

Till this is released though, I've created a temporary `malachite/` folder at root here so you can copy Starship, Tmux, Dircolors, Mako, Wofi, Hypr, till the flavors are out.

### 3. Zsh

[zsh.md](./ui/zsh.md)

Zsh is the shell loader.

It wires the environment, tool integrations, Starship, Flavors, and personal shell state.

### 4. Starship

[starship.md](./ui/starship.md)

Starship is the prompt layer.

It carries the state that a top bar usually wastes space showing: time, directory, Git state, runtime state, and command result.

### 5. Tmux

[tmux.md](./ui/tmux.md)

Tmux is the persistent terminal workspace.

The status bars on the bottom of the terminal are tmux windows.

### 6. Dircolors

[dircolors.md](./ui/dircolors.md)

Dircolors controls file colors through `LS_COLORS`.

It keeps terminal listings visually aligned with the active palette.

### 7. Hyprland

Read [hypr.md](./ui/hypr.md)

### 8. Mako and Wofi

[mako.md](./ui/mako.md)
[wofi.md](./ui/wofi.md)

Mako is notifications.

Wofi is launcher and picker surface.

### 9. Neovim

[neovim.md](./ui/neovim.md)

Neovim is optional.

## Repo map

The repo is shaped like a home directory:

```text
.config/      user-space configs
zsh/          shell modules
flavors/      palette engine
install/      bootstrap and setup scripts
assets/       screenshots and gifs
.github/      CI and repo checks
docs/         documentation
```

## `.config`

`.config/` maps to `~/.config/`:

Some surfaces:

```text
.config/hypr/        Hyprland compositor config
.config/kitty/       terminal config
.config/nvim/        Neovim config
.config/fontconfig/  font routing
.config/wofi/        launcher behavior
.config/mako/        notification config
.config/lsd/         file listing config
.config/swappy/      screenshot annotation
.config/waypaper/    wallpaper restore
```
