<h1 align="center">osyx</h1>

<p align="center">
  <a href="https://github.com/rccyx/osyx/actions"><img src="https://img.shields.io/github/actions/workflow/status/rccyx/osyx/ci.yml?style=for-the-badge&color=black&labelColor=111111&logo=githubactions&logoColor=white" alt="CI Status"/></a>
  <a href="https://www.debian.org/releases/trixie/"><img src="https://img.shields.io/badge/Base-Debian_Trixie-black?style=for-the-badge&color=black&labelColor=111111&logo=debian&logoColor=white" alt="Base: Debian Trixie"/></a>
  <a href="https://github.com/rccyx/osyx"><img src="https://img.shields.io/github/repo-size/rccyx/osyx?style=for-the-badge&color=black&labelColor=111111&logo=github&logoColor=white" alt="Size"/></a>
<a href="https://github.com/rccyx/osyx/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-Apache-black?style=for-the-badge&color=black&labelColor=111111&logo=apache&logoColor=white" alt="License"/></a>
  <br>
</p>


<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/26f28ab8-fcd0-4335-a273-2d9f9f4e509d" />

### Login 

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/05a48590-e792-425d-8af4-da9072b38b9b" />

### Desktop

  <a href="https://youtu.be/6Hd7L2aBmFk">
    <img src="https://github.com/user-attachments/assets/dd6360de-0b83-46d4-a005-7fd6a6d57fae" alt="osyx demo">
  </a>

## Stack

These have basically been unchanged for years, updated to latest last year, but took a very, very long time to refine:

- **Distro:** Debian.
- **Display:** Wayland.
- **Compositor:** Hyprland.
- **Terminal:** Kitty.
- **Multiplexer:** Tmux.
- **Shell:** Zsh + Starship.
- **Wallpaper:** Work of artists such as [Dominik Mayer](https://x.com/DominikMayerArt), [Susan Wilkinson](https://www.instagram.com/susan.wilkinson.photography/) and more. Backend is `swww`
- **Notifications:** Mako.
- **Fonts:** Inter (sans), Iosevka (mono).
- **Lockscreen:** Hyprlock.
- **Clipboard:** Wofi for the UI, custom backend.
- **Login:** Parts of the engines...explained below.
- **And more...**

> [!NOTE]
> The top bar has been totally annihilated to remove unnecessary clutter. Starship already tells time. Event driven notifications surface critical system vitals (thermals, battery, etc).

### Workflow

The workflow is split between global keybinds and the CLI, no start menus, dropdowns or clickable icons needed:

- **Chrome:** Alt + G
- **Obsidian:** Alt + O
- **Files (Nautilus):** Alt + F
- **Audio Transcription:** Alt + W
- **Power Menu:** Alt + P
- **Lock:** Alt + L
- **Themes:** Alt + R
- **Clipboard Menu:** Ctrl + X

And so on, till the keys run out.

But they ran out a long time ago, so the CLI handles the rest:

In the demo you've seen the screen recorder with desktop audio, and a VPN wireguard connection, while [transcribing](#engines) a thought on the go. No GUI needed.

Most tasks are handled through the CLI (which I call Jarvis). This includes everything from simple brightness adjustments, encryption, 2FA codes, network management, etc, to AWS cost analysis, email reminders, syncing packages (RS, TS, Go,Py, APT, etc), git ops & pull request management (reviews, submits, etc), [theming](#engines), even ISO flashing or video editing and audio settings, and much more.

It covers basically anything that doesn't really require a full blown GUI.

But, speaking of

**GUIs:**

Apps behave like native apps, for example: `app sc` launches SoundCloud, with Hypr: `Super + F` for fullscreen, and `Super + Q` to quit. It’s significantly faster than fumbling with browser tabs and saves seconds of friction every time.

All programs launch in their correct workspaces on boot: hit the power button, wait for boot, login with fingerprint, everything spawns up instantly, `Super + 3`, three terminals already open, tmux'ed sessions on the right one, the [visualizer](#lookas) on the bottom right, a misc one on top right.

Workspaces are awlays in the same position, they never change: `Super + 1` That's worskspace one, always notes, `Super + 9` reserved for background music with `app yt`. To move laterally `Alt + Ctrl + Arrows`

## Engines

My own tooling layer built on top of the stack, handling login, audio, voice, theming, control, and more. 

Open sourcing gradually as standalone tools, airdrop-compatible with any distro.

First drop:

### [Lookas](https://github.com/rccyx/lookas)

A terminal audio visualizer based on human auditory perception. Moving beyond raw FFT with Mel-scaling and spring-damper dynamics. You can run `cargo install lookas && lookas` right now.

<p align="center">
  <a href="https://github.com/rccyx/lookas">
    <img src="./assets/lookas.gif" alt="Lookas Demo" width="100%">
  </a>
</p>


### Flavors Engine: (Coming Soon)

The demo shows the blush theme.

A single palette drives the global state. One command propagates color changes across the system. ALT + R rotates between all themes. I'm working on it now, whenever a flavor is ready for public release, I'll drop it.

### Thyx (Coming Soon)

Login.

The login screen you just saw.

SDDM based, ships with presets, while fully configurable, features video backgrounds, fingerprint auth, and a composable design system that matches the main desktop setup. Terraform like state management for installation/uninstallation, CI-tested on Debian, Fedora, and Arch, contains zero bloat.

Will drop when I'm done open sourcing the falvoring engines and the initial palettes so everything syncs.

### Powyx : Power Menu (Unreleased)

The glassmorphic power menu you saw in the demo.

### Jarvis : Control (Unreleased)

A headless CLI control center made to reduce the GUI footprint to just the browser and the editor. This is the central nervous system of the OS. Much of it is hardcoded to my setup and will be rolled out slowly here. When it gets big enough it gets its own repo. For example:

### Asryx : Voice (Unreleased)

Offline voice-to-text via a single stateful toggle. It supports long-form recording and transcription with zero API latency.

### Hyprtryx : Compositor Build (Unreleased)

An idempotent script to build Hyprland from source on Debian Trixie using pinned tags: Hyprland only and nothing else. The build is CI-validated on every push. In fact, everything here is CI validated into oblivion.

### And more...

## State

Some configurations are currently stale or remain in private repositories. Most of the setup is hardcoded to my workflow and interlinked, so I'll be releasing components gradually. 

Meanwhile, yank whatever you need, the Hyprland setup, Zsh, anything.

## License

Apache-2.0 © [@rccyx](https://rccyx.com)
