# Bootstrapping

`install/` is the machine-build layer.

It starts from a minimal Debian base and brings the machine up to a workable state: privileges, networking, apt packages, locale, timezone, shell, runtimes, Wayland-adjacent tools, audio basics, clipboard tools, screenshots, apps, and hardware glue.

This is not the full desktop installer.

Running the bootstrap will not install the finished setup. It doesn't install Hyprland itself. That belongs to a separate (private) build layer, which pins and builds the compositor stack and handles the lower-level Hyprland path.

Some of the wiring is still private until it is stable enough to release safely.

Although, if you want the full setup, you will need to figure out Hypland on your own until I open source the builder.

Aside from that, the configuration is essentially the same. The bootstrap is for getting a raw Debian up and running, after which you need to install Hypr and use the setup provided here. You should get quite close to the final version.

It merely prepares Debian for the next layer. It doesn't complete the environment.

## Layout

```text
install/
├── bootstrap       entrypoint
├── bootstrap.d/    bootstrap modules
├── runtimes/       language runtimes
├── apps/           optional desktop apps
└── setup/          audio, display, shell, system, and build glue
```

## Commands

```sh
./install/bootstrap <command> [options]
```

| Command  | Purpose                                       |
| -------- | --------------------------------------------- |
| `fresh`  | root-only first pass for a raw Debian install |
| `plan`   | read-only package plan                        |
| `apply`  | install and configure the selected profile    |
| `doctor` | print diagnostics                             |
| `status` | print saved bootstrap state                   |
| `clean`  | remove logs, or logs/cache/state with `--all` |

Profiles:

| Profile   | Meaning                                                   |
| --------- | --------------------------------------------------------- |
| `min`     | command-line base                                         |
| `desktop` | command-line base plus Wayland, audio, portals, clipboard |

Options:

```bash
--profile=desktop
--prefix=/usr/local
--locale=en_GB.UTF-8
--tz=Europe/London
--yes
```

`apply` requires `--yes`.

## Raw Debian path

A fresh Debian install can be extremely bare. No desktop, no display manager, no workflow, sometimes not even `sudo`.

Start as root:

```sh
su -
cd /path/to/repo
./install/bootstrap fresh --user=<your-user> --yes
```

If `sudo` already works:

```sh
sudo ./install/bootstrap fresh --user="$(id -un)" --yes
```

`fresh` installs the survival layer: `sudo`, networking, certificates, curl/wget, git, locales, timezone data, dbus, SSH client, firmware packages when available, basic editors, man pages, fonts, and XDG user directories.

It also enables NetworkManager, adds the target user to `sudo`, applies locale/timezone, and prepares the machine for the normal user stage.

After that, relogin or reboot if groups, networking, or sudo behave weirdly.

## Normal user path

Run the rest as the normal user.

Check the plan first:

```sh
./install/bootstrap plan --profile=desktop
```

Apply it:

```sh
./install/bootstrap apply --profile=desktop --yes
```

For a smaller CLI base:

```sh
./install/bootstrap plan --profile=min
./install/bootstrap apply --profile=min --yes
```

## What `apply` does

`apply` installs the selected package profile, configures locale/timezone, enables basic services, fixes Debian command naming quirks, writes bootstrap state, installs runtimes, and enables the shell plugin layer.

The desktop profile adds the Wayland-facing base:

```text
network-manager
seatd
polkitd
xwayland
xdg-desktop-portal
xdg-desktop-portal-wlr
pipewire
wireplumber
pipewire-pulse
wl-clipboard
grim
slurp
brightnessctl
playerctl
fonts-noto-color-emoji
```

The command-line stack includes:

```text
zsh
tmux
kitty
wofi
mako
lsd
fzf
ripgrep
fd-find
bat
starship
pipx
neovim
tree
htop
btop
openssh-client
python3-jinja2
```

On Debian, `bat` may exist as `batcat`, and `fd` may exist as `fdfind`. The bootstrap links the expected names when needed.

## Bootstrap modules

```text
bootstrap.d/
├── core.sh       logging, paths, detection, errors
├── state.sh      state file read/write
├── privilege.sh  sudo, su fallback, groups, user detection
├── apt.sh        apt and dpkg helpers
└── tooling.sh    commands, profiles, package lists, dispatch
```

## Runtimes

```text
runtimes/
├── rust
├── node
├── pnpm
├── go
└── uv
```

Runtime scripts install the developer language layer after apt packages are in place.

| Script | Installs                                  |
| ------ | ----------------------------------------- |
| `rust` | Rustup and stable Rust                    |
| `node` | Node.js 22 system-wide and through NVM    |
| `pnpm` | Corepack, pinned PNPM, TypeScript tooling |
| `go`   | pinned Go tarball under `/usr/local/go`   |
| `uv`   | Astral `uv`                               |

These scripts may write shell path blocks into `.profile` or `.zshrc`.

## Apps

```text
apps/
├── brave
├── cava
├── chrome
├── code
├── obsidian
├── opera
└── spotify
```

These are optional app installers.

| Script     | Purpose                                                           |
| ---------- | ----------------------------------------------------------------- |
| `brave`    | Brave install script                                              |
| `chrome`   | downloads Chrome `.deb`, installs it, links `google-chrome`       |
| `code`     | adds Microsoft apt repo and installs VS Code                      |
| `obsidian` | installs Obsidian through Nix profile                             |
| `opera`    | adds Opera apt repo and installs Opera                            |
| `spotify`  | reinstalls Spotify, fixes sandbox/userns behavior, writes wrapper |
| `cava`     | installs CAVA, writes config, adds floating terminal toggle       |

## Setup scripts

```text
setup/
├── audio/
├── build/
├── display/
├── shell/
└── system/
```

These are targeted enablement scripts.

### `setup/audio`

```text
enable-audio-stack.zsh
enable-analog-output-speakers.zsh
set-vocaster-default.zsh
```

PipeWire setup, capture-source repair, speaker/headphone switching, and Vocaster default-device handling.

Some of this is hardware-specific.

### `setup/build`

```text
install-hyprland-qtutils.zsh
install-rust-analyzer.zsh
install-waydroid.zsh
```

Build helpers and heavier optional tooling. Waydroid is invasive enough that it should be read before execution.

### `setup/display`

```text
enable-clipboard.zsh
enable-mac-like-screenshots.zsh
enable-wayland-screenshare.zsh
fonts.sh
setup-cursor-theme.zsh
```

Clipboard, screenshots, Wayland screenshare, fonts, and cursor behavior.

### `setup/shell`

```text
enable-corepack.zsh
enable-zsh-plugs.zsh
```

Corepack and shell plugin setup.

### `setup/system`

```text
enable-battery-notifications.zsh
enable-bluetooth.zsh
enable-heat-notifications.zsh
iwlwifi-jfb0.zsh
setup-time-and-ntp.zsh
```

Bluetooth, battery notifications, thermal notifications, Wi-Fi quirks, and time/NTP setup.

## Diagnostics

```sh
./install/bootstrap doctor
```

Prints kernel, groups, sudo availability, Zsh status, seatd status, NetworkManager status, and state path.

```sh
./install/bootstrap status
```

Prints saved bootstrap state.

```sh
./install/bootstrap clean
```

Removes logs.

```sh
./install/bootstrap clean --all
```

Removes logs, cache, and state.
