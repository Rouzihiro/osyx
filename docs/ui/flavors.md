# Flavors

This is the theming engine. And it uses a single palette file and a unified command to synchronize the entire environment and update the shell prompt, multiplexer, compositor, borders, notifications, launcher, and wallpaper instantly.

One TOML file defines the colors for Starship (the prompt), Tmux (the multiplexer), Hyprland (border colors only), Mako (notifications), Wofi (launcher and clipboard picker), Neovim, Gitconfig (themed log and diff aliases), Dircolors (file listing colors in terminal), wallpaper, and the matching [Thyx](https://github.com/rccyx/thyx) login preset.

What it does not own: GTK, Obsidian, Spotify, browser chrome. Those stay manual.

If you watched the demos and saw Obsidian matching the palette, I did that manually for the demo, same for picking a Spotify song, for example, Halsey's Badlands album looks perfect for the Malachite theme.

Daily use keeps it neutral. My current Obisidian setup uses a black and white palette that works with everything. The flavors covers the desktop. Apps are on you.

Kitty is intentionally excluded. It has a fixed base config: one background, transparency, font. The cursor stays white.

I thought about adding it to the flavors but the terminal is supposed to be the neutral canvas everything else renders on.

This is how it works

```text
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

And it owns the generated visual state.

```text
flavors/
├── palettes/       source palettes
├── base/           jinja templates
├── backgrounds/    wallpaper files
├── generator/      python renderer
├── theme/          zsh runtime
├── generate.py     generator entry point
├── themes.zsh      shell entry point
└── thyx-map.conf   desktop theme to login theme mapping
```

The source files are the palettes and templates. The generated files are outputs.

Palettes live in:

```text
flavors/palettes/
```

A palette is split by target surface:

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

Each section is named after the surface it drives. `starship.os_bg` becomes `starship_os_bg` inside templates. `mako.border` becomes `mako_border`. `dircolors.dir` becomes `dircolors_dir`.

Color values are written as plain six-character hex without `#`.

The generator also creates helper variants for every color:

| Suffix  | Format                  | Example       |
| ------- | ----------------------- | ------------- |
| (none)  | raw hex                 | `018a83`      |
| `_rgb`  | comma-separated decimal | `1, 138, 131` |
| `_ansi` | semicolon-separated     | `1;138;131`   |

That gives each template the format it needs. CSS can use RGB. Dircolors can use ANSI. TOML and Lua can use raw hex.

## Template layer

Templates live in:

```text
flavors/base/
```

Current jinja templates:

```text
dircolors.j2
gitconfig.j2
hypr.conf.j2
mako.conf.j2
nvim.lua.j2
starship.toml.j2
tmux.conf.j2
wofi.css.j2
```

Each template is normal config with palette variables inserted through Jinja.

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

## Output layer

The generator writes real config files back into the repo shaped home tree (which is ~).

```text
flavors/base/mako.conf.j2       -> .config/mako/config
flavors/base/starship.toml.j2   -> .config/starship.toml
flavors/base/dircolors.j2       -> .dircolors
flavors/base/hypr.conf.j2       -> .config/hypr/theme.conf
flavors/base/tmux.conf.j2       -> tmux/theme.conf
flavors/base/wofi.css.j2        -> .config/wofi/style.css
flavors/base/nvim.lua.j2        -> .config/nvim/lua/theme.lua
flavors/base/gitconfig.j2       -> .gitconfig.d/theme
```

Generated files are runtime artifacts. Edit the palette or template, then regenerate.

## azdazdnajnzd

`themes.zsh` is the runtime orchestrator. Sourced from [`~/.zshrc`](/.zshrc):

```zsh
source "$HOME/flavors/themes.zsh"
```

That one line gives you the `themes` command, the initial dircolors load, and the live reload machinery across all open terminals.

When you run `themes`, it opens an fzf picker and you choose. `themes rotate` skips the picker and advances to the next palette in sequence. After picking, it:

1. Runs `generate.py`, writes all config files
2. Stores the selection in `~/.cache/theme.current`
3. Reloads Tmux via `tmux source-file`
4. Reloads Hyprland via `hyprctl reload`
5. Reloads Mako via `makoctl reload`
6. Signals all running Neovim instances via RPC socket with `:OsyxFlip`
7. Sets wallpaper via `swww`
8. Updates the Thyx login preset
9. Sends `SIGUSR1` to every running Zsh session

Everything runs in a background subshell. The command returns immediately.

The hard part was making every open terminal update its colors automatically for starship. The old way was typing `reload` which sources `.zshrc`. That only updates the one terminal you're in. Every other open terminal stays on the old palette.

The current setup installs a `TRAPUSR1` signal handler in every shell that sources `themes.zsh`. When a theme switches, `themes.zsh` sends `SIGUSR1` to every running Zsh process owned by the user. Each one fires the handler immediately, even at an idle prompt, re-evaluates `dircolors`, and resets the prompt. Shells that were mid-command and missed the signal get caught by a `precmd` fallback that checks a timestamp file on the next prompt draw. Every open terminal updates. No manual action.

The Hyprland keybind to rotate palettes:

```ini
bind = ALT, R, exec, zsh -ic 'themes rotate'
```

Neovim is the only one you can delay or skip. Two paths:

- **Use the osyx Neovim config as-is.** It's self-contained, bootstraps vim-plug on first launch, hot-reloads via `:OsyxFlip` when themes switch. Just copy it over: `cp -r osyx/.config/nvim ~/.config/nvim`
- **Use your own config.** Modify `generate.py` to point the Neovim output at wherever your config expects it, then wire your own reload hook. The palette variables are all there: `nvim_bg`, `nvim_fg`, `nvim_accent`, `nvim_colorscheme`, `nvim_border`. Map them however your setup allows.

Read [Neovim](./nvim.md) before doing anything with it.

Install fonts. Read the fonts [documentation](./fonts.md).

Copy the tool configs:

```sh
cp osyx/.tmux.conf ~/.tmux.conf
mkdir -p ~/tmux
cp -r osyx/.config/mako ~/.config/mako
cp -r osyx/.config/wofi ~/.config/wofi
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

Generate and reload:

```sh
python3 ~/flavors/generate.py malachite
source ~/.zshrc
```

## Usage

git clone https://github.com/rccyx/osyx.git
cp -r osyx/flavors ~/flavors

So basically first of all here what I need you to do is let me explain you the flavor So you have to use the Tmuck setup and you also have to use the Starship setup And you also have to backup your setup if you have something that is not backed up for example you have a Tmuck setup You want to like back up your own you want to back up your Starship you want to also back up your Maco You want to back up your shit that we just talked about right here in the previous section Which is the output layer okay before you make any change? After we make every change you can try out In the current repository from the riparoo you can run this function python - flavors - whatever to see how the generated files look like if you like them Which will you will you will do you can just go ahead and simply copy the flavors engine over at home which you see from like literally copy like this and After you copy it basically you just do the same fucking command from home and that's it they're gonna be auto-generated Right there now a couple things you have to understand first I need you to understand that you do not need like Look at the Starship specifically that's gonna override your ocean Starship is gonna become mine now the second thing which is so important now You have noticed that everything goes up together the flavors only changes the colors of stuff But the base is still the base we still use the same fonts Which go ahead and read the fonts documentation understand how to set it up and also when it comes to hyperland You have to use the hyperland setups if you want to make it look like mine you have to use my hyperland setup as you notice I have something Certain bold borders to do have certain things to do and so on and so forth these all work now the flavors simply changes the colors of the borders But the borders themselves are from the hyperland configurations themselves, right? And these files are supposed to be for example right there now if you want to keep your hyperland configuration and you have your own theme setup Whatever you simply have to source the outer-generated files for borders is so I have to do simply source it That's all I have to do if you have a different layer Maybe you have like a different layouts or keybinds or whatever you don't want to use mine. All right Simply source my themes. Okay now directory colors. This is so important is gonna override yours There's no way you're gonna do some other directory colors. You gotta override yours Starship the same Mac. Oh is the same the coffee is gonna be over it complete Wolfie is the same stuff Wolfie style that CSS gonna be over it Team up that theme. Okay. Think about T mux to make T mux look like this took me a long long long fucking time to make it look like this by the way T mux is so fucking pain in the ass to make it look nice, but I did I'm using normal T mux nothing more So if you look at home the Reaper root in this kind of case because the repotch represents home You have to you can check out the T mux folder dot T mux file Sorry, you can see you just simply have to use that one and I have also documented Intensely in this documentation to understand how it's being used and that file sources the auto-generated T mux file from the T mux folder at home so t mux slash theme.com So yeah, this is basically how it works

Move the flavors to home
From the repo root:

```sh
python3 flavors/generate.py malachite
```

Multiple flavors can be generated in one run:

```sh
python3 flavors/generate.py blush malachite sakura
```

The command reads:

```text
flavors/palettes/malachite.toml
```

Then writes every configured output.

The generator requires Python 3.11 for `tomllib` and `python3-jinja2` for template rendering.

So run `pip install tomllib python3-jinja2`

## Shell runtime

The live theme runtime is loaded through:

```text
flavors/themes.zsh
```

It sources the runtime modules in order:

```text
theme/config.zsh
theme/reload.zsh
theme/select.zsh
theme/apply.zsh
```

`themes.zsh` exposes one command:

```sh
themes
```

By default, `themes` opens an `fzf` picker with every palette in `flavors/palettes`.

```sh
themes
```

Rotation mode picks the next palette after the current one:

```sh
themes rotate
```

That is what `ALT + R` calls in the OSyx workflow.

## Runtime paths

The runtime defaults are defined in `theme/config.zsh`.

```text
palettes      $HOME/flavors/palettes
backgrounds   $HOME/flavors/backgrounds
generator     $HOME/flavors/generate.py
thyx map      $HOME/flavors/thyx-map.conf
state file    $HOME/.cache/theme.current
reload file   $HOME/.cache/zsh-reload-trigger
log file      $HOME/.cache/osyx.log
```

The current flavor name is stored in:

```text
~/.cache/theme.current
```

That file lets `themes rotate` know what comes next.

## What happens when a flavor is applied

Applying a flavor performs the full runtime switch.

```text
choose flavor
  ↓
generate config files
  ↓
write current theme state
  ↓
reload Hyprland
  ↓
reload Mako
  ↓
reload Tmux
  ↓
reload Neovim
  ↓
reload Dircolors in shells
  ↓
apply wallpaper
  ↓
update Thyx login preset
```

Hyprland reloads through:

```sh
hyprctl reload
```

Mako reloads through:

```sh
makoctl reload
```

If `makoctl` is unavailable, the runtime restarts `mako`.

Tmux reloads by sourcing the main tmux config:

```sh
tmux source-file "$HOME/.tmux.conf"
```

Neovim reloads through active server sockets by sending:

```vim
<Cmd>OsyxFlip<CR>
```

Dircolors reloads in the current shell through:

```sh
eval "$(dircolors "$HOME/.dircolors")"
```

Other shells reload through a timestamp file checked during `precmd`.

## Wallpaper matching

A wallpaper can be attached to a flavor by matching its filename to the palette name.

```text
flavors/palettes/malachite.toml
flavors/backgrounds/malachite.jpg
```

Supported wallpaper extensions:

```text
jpg
png
webp
```

The runtime checks for a matching file and applies it through the available wallpaper command.

## Thyx matching

Thyx is the SDDM login surface. Flavors can keep the login screen visually aligned with the desktop through:

```text
flavors/thyx-map.conf
```

Example:

```ini
blush=blush
sakura=sakura
malachite=malachite
```

When a flavor is applied, the runtime checks the map and updates the Thyx metadata to point at the matching preset.

Anything unmapped falls back to `ash`.

## Adding a new flavor

Create a palette:

```text
flavors/palettes/amber.toml
```

Use an existing palette as the starting shape. Keep the same sections unless the templates have been changed.

Add a matching wallpaper when needed:

```text
flavors/backgrounds/amber.jpg
```

Add a Thyx preset mapping when the login screen has a matching preset:

```ini
amber=amber
```

Generate it:

```sh
python3 flavors/generate.py amber
```

Apply it:

```sh
themes
```

Or rotate into it:

```sh
themes rotate
```

## Adding a themed surface

A new surface needs three changes.

Add a template:

```text
flavors/base/example.conf.j2
```

Add an output target in `flavors/generator/config.py`:

```python
OUTPUTS = {
    "example.conf.j2": ".config/example/config",
}
```

Add a palette section:

```toml
[example]
bg = "00140e"
fg = "8ed7cf"
accent = "018a83"
```

The template receives those values as:

```text
example_bg
example_fg
example_accent
example_bg_rgb
example_bg_ansi
```

If the surface needs live reload, add that reload step to `theme/apply.zsh`.

## Failure behavior

Flavors is built to skip missing optional surfaces.

If Tmux is not running, Tmux reload is skipped.

If Hyprland is unavailable, Hyprland reload is skipped.

If Neovim has no active socket, Neovim reload is skipped.

If Thyx is not installed, the login preset update is skipped.

Failures are logged to:

```text
~/.cache/osyx.log
```

That keeps theme rotation usable while individual surfaces are absent.

````

Replace the README Flavors block with this:

```md
### Flavors (coming soon)

Flavors is the OSyx palette engine.

A flavor is a named visual state for the whole workspace. One TOML palette generates the colors for Starship, Tmux, Hyprland borders, Mako, Wofi, Dircolors, Neovim, Git output, wallpaper selection, and the matching Thyx login preset.

```text
palette TOML
  ↓
Jinja templates
  ↓
generated config files
  ↓
live reload
````

`ALT + R` rotates the active flavor. The desktop changes in one motion because the theme layer owns generated config state rather than hand-edited colors scattered across every tool.

The current public palettes are `blush`, `malachite`, and `sakura`. The release lands once the docs, rollback behavior, and standalone install path are clean.
