# Workflow

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

But the prime real estate ran out a long time ago, so the CLI handles the rest:

In the demo you've seen the screen recorder with desktop audio, and a VPN wireguard connection, while [transcribing](https://github.com/rccyx/asryx) a thought on the go. No GUI needed.

Most tasks are handled through the CLI (I call it [Jarvis](https://en.wikipedia.org/wiki/J.A.R.V.I.S.)), with fuzzy finder autocompletion, as there's only so much one can remember.

This includes everything from simple brightness adjustments, encryption, 2FA codes, network management, etc, to cloud cost analysis, email reminders, syncing packages (RS, TS, Go,Py, APT, etc), git ops & pull request management (reviews, submits, etc), theming, even ISO flashing or video editing and audio settings, and much more.

It covers basically anything that doesn't really require a full blown GUI to use.

But, speaking of

**GUIs:**

Apps behave like native apps, for example: `app sc` launches SoundCloud, with Hypr: `Super + F` for fullscreen, and `Super + Q` to quit. It’s significantly faster than fumbling with browser tabs and saves seconds of friction every time.

All programs launch in their correct workspaces on boot: hit the power button, wait for boot, tap the fingerprint sensor, everything spawns up instantly, no action needed, `Super + 3`, three terminals already open, tmux'ed sessions on the right one, the [visualizer](https://github.com/rccyx/lookas) on the bottom right, a misc terminal on top right.

Workspaces are always in the same position, they never change: `Super + 1` That's worskspace one, always notes, `Super + 9` reserved for background music with `app yt`. To move laterally `Alt + Ctrl + Arrows`
