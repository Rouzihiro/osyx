<h1 align="center">osyx</h1>

<p align="center">
  <a href="https://github.com/rccyx/osyx/actions"><img src="https://img.shields.io/github/actions/workflow/status/rccyx/osyx/ci.yml?style=for-the-badge&color=black&labelColor=111111&logo=githubactions&logoColor=white" alt="CI Status"/></a>
  <a href="https://www.debian.org/releases/trixie/"><img src="https://img.shields.io/badge/Base-Debian_Trixie-black?style=for-the-badge&color=black&labelColor=111111&logo=debian&logoColor=white" alt="Base: Debian Trixie"/></a>
  <a href="https://github.com/rccyx/osyx"><img src="https://img.shields.io/github/repo-size/rccyx/osyx?style=for-the-badge&color=black&labelColor=111111&logo=github&logoColor=white" alt="Size"/></a>
  <a href="https://github.com/rccyx/osyx/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-Apache-black?style=for-the-badge&color=black&labelColor=111111&logo=apache&logoColor=white" alt="License"/></a>
</p>

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/26f28ab8-fcd0-4335-a273-2d9f9f4e509d" />

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/ad2f6135-1ff5-40a1-8e47-57c745b5c7ed" />

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/39dfa21b-c6df-4be8-9971-d2043d3352b7" />


### Demos

<a href="https://youtu.be/6Hd7L2aBmFk">
  <img src="https://github.com/user-attachments/assets/dd6360de-0b83-46d4-a005-7fd6a6d57fae" alt="osyx demo">
</a>

<a href="https://www.youtube.com/watch?v=agGcxm24N84">
  <img src="https://github.com/user-attachments/assets/f9606dcd-571d-460a-a33c-3bb0a6166602" alt="osyx demo">
</a>

<a href="https://youtu.be/hfwcOR_xJJA">
  <img src="https://github.com/user-attachments/assets/9d7e6c58-34aa-4c89-bf49-758bb13a6913" alt="osyx demo">
</a>


## TL;DR

This project, is a highly engineered stack of tooling, configurations, scripts, and custom software that transforms a completely blank, TTY only Debian into the slick, keyboard driven workspace you saw in the demos.

Debian is treated mostly as a stable [substrate](/.github/workflows/on-workflow-call-bootstrap.yml) and package source (starts off without even having `sudo`).

> [!IMPORTANT]
> Some configurations, scripts, programs, etc, are kept private until they're stable enough to release. The rest is here as a mirror and reference material, copy what you want.

## Explainers

If you want to dig through:

- [Starting](./docs/starting.md) (Want the eye candy? How to go by this)
- [Workflow](./docs/workflow.md) (If you reach for a mouse, you've already lost)
- [Stack](./docs/stack.md) (If it ain't broke don't fix it)
- [Philosophy](./docs/philosophy.md) (Overall premise and why I'm doing this)

## Engines

These are standalone tools written from scratch, that can be airdropped into any distro. Open sourced gradually:

### [Asryx](https://github.com/rccyx/asryx) (released: 25/05/26)

The transcription program from the demo.

Native Linux ASR binary. Written in C++ and embedded via whiser.cpp's C API, daemonless, offline, no bloat, no GUI, no config overhead.

<p align="center">
  <a href="https://github.com/rccyx/asryx">
    <img src="./assets/asryx.gif" alt="Asryx Demo" width="100%">
  </a>
</p>

### [Lookas](https://github.com/rccyx/lookas) (released: 02/04/26)

A terminal audio visualizer built around human auditory perception. Moves beyond raw FFT twitchiness using Mel-scaling and spring damper physics.

```sh
cargo install lookas && lookas
```

<p align="center">
  <a href="https://github.com/rccyx/lookas">
    <img src="./assets/lookas.gif" alt="Lookas Demo" width="100%">
  </a>
</p>

### Thyx (Next)

A QML based SDDM login screen with video backgrounds, fingerprint auth, and a composable design system. Terraform like state management for installation/uninstallation. Contains absolutely zero bloat, and fully configurable.

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/05a48590-e792-425d-8af4-da9072b38b9b" />

### Powyx (Unreleased)

The glassmorphic power menu from the demo.

Even though this is a GUI, it solves a real latency problem: if a terminal is not already open, `Alt + P` is faster than spawning a shell (~2.4s load time via `Alt + K`) just to type `sdn`.

<p align="center">
  <a href="https://github.com/rccyx/powyx">
    <img src="https://github.com/user-attachments/assets/0c99e97e-e639-4a30-8afd-b373b759661a" alt="Powyx" width="100%">
  </a>
</p>

### Jarvis (Unreleased)

A headless CLI control center built to reduce the GUI footprint to just the browser and the editor. The central nervous system of the OS. Much of it is hardcoded to my setup and will be rolled out here gradually.

## And more...

There's more to come.

> [!TIP]
> This is a long term thing. So you might follow through.

## License

Apache-2.0 © @rccyx
