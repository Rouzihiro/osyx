<h1 align="center">osyx</h1>

<p align="center">
  <a href="https://github.com/rccyx/osyx/actions"><img src="https://img.shields.io/github/actions/workflow/status/rccyx/osyx/ci.yml?style=for-the-badge&color=black&labelColor=111111&logo=githubactions&logoColor=white" alt="CI Status"/></a>
  <a href="https://www.debian.org/releases/trixie/"><img src="https://img.shields.io/badge/Base-Debian_Trixie-black?style=for-the-badge&color=black&labelColor=111111&logo=debian&logoColor=white" alt="Base: Debian Trixie"/></a>
  <a href="https://github.com/rccyx/osyx"><img src="https://img.shields.io/github/repo-size/rccyx/osyx?style=for-the-badge&color=black&labelColor=111111&logo=github&logoColor=white" alt="Size"/></a>
<a href="https://github.com/rccyx/osyx/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-Apache-black?style=for-the-badge&color=black&labelColor=111111&logo=apache&logoColor=white" alt="License"/></a>
  <br>
  <br>
  <a href="https://youtu.be/6Hd7L2aBmFk">
    <img src="https://github.com/user-attachments/assets/dd6360de-0b83-46d4-a005-7fd6a6d57fae" alt="osyx demo">
  </a>
</p>

## Philosophy

Workable.

## Stack

These have basically been unchanged for years, althrough, I updated to latest in Q3, 2025:

- **Distro:** Debian.
- **Display:** Wayland.
- **Compositor:** Hyprland.
- **Terminal:** Kitty.
- **Multiplexer:** Tmux.
- **Shell:** Zsh + Starship.
- **Notifications:** Mako.
- **Fonts:** Inter (sans), Iosevka (mono).
- **Lockscreen:** Hyprlock (or Swaylock for less heat).
- **Clipboard:** Scripts + Wofi for the UI.

And the engines...explained below.

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
- **Clipboard Menu:** Ctrl + X

And more...

For example, in the demo you've seen the screen recorder with desktop audio, and a VPN wireguard connection, while [transcribing](#engines) a thought. No GUI needed.

Most tasks are handled through the CLI. This includes everything from simple brightness adjustments, encryption, 2FA codes, standard network management, etc to AWS cost analysis, S3 uploads, Docker, reviewing pull requests, [theming](#engines), syncing packages, ISO flashing, video editing, and much, much more.

It covers basically anything that I don't actually need a full blown GUI for.

But speaking of GUIs:

Apps behave like native apps, for example: `app sc` launches SoundCloud, with Hypr: `Super + F` for fullscreen, and `Super + Q` to quit. It’s significantly faster than fumbling with browser tabs and saves seconds of friction every time.

All programs launch in their correct workspaces on boot, hit the power button, wait for boot, login with fingerprint, everything spawns up instantly, `Super + 3`, three terminals already open, tmux'ed sessions on the right one, the [visualizer](#lookas) on the bottom right, a misc one on top right.

Workspaces are awlays in the same position, they never change: `Super + 1` That's worskspace one, always notes, `Super + 9` reserved for background music with `app yt`. To move laterally `Alt + Ctrl + Arrows`

## Engines

A proprietary layer built on top of the stack, my own tools handling login, audio, voice, theming, control, and more. Open sourcing gradually.

First drop:

### [Lookas](https://github.com/rccyx/lookas)

A terminal audio visualizer based on human auditory perception. Moving beyond raw FFT with Mel-scaling and spring-damper dynamics. You can run `cargo install lookas && lookas` right now.

## License

Apache-2.0 © [@rccyx](https://rccyx.com)
