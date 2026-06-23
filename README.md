<h1 align="center">osyx</h1>

<p align="center">
  <a href="https://github.com/rccyx/osyx/actions"><img src="https://img.shields.io/github/actions/workflow/status/rccyx/osyx/ci.yml?style=for-the-badge&color=black&labelColor=111111&logo=githubactions&logoColor=white" alt="CI Status"/></a>
  <a href="https://www.debian.org/releases/trixie/"><img src="https://img.shields.io/badge/Base-Debian_Trixie-black?style=for-the-badge&color=black&labelColor=111111&logo=debian&logoColor=white" alt="Base: Debian Trixie"/></a>
  <a href="https://github.com/rccyx/osyx"><img src="https://img.shields.io/github/repo-size/rccyx/osyx?style=for-the-badge&color=black&labelColor=111111&logo=github&logoColor=white" alt="Size"/></a>
  <a href="https://github.com/rccyx/osyx/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-Apache-black?style=for-the-badge&color=black&labelColor=111111&logo=apache&logoColor=white" alt="License"/></a>
</p>

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/fbd42023-8349-4f86-8bca-e136d4684a56" />

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/56449dd3-0939-4a28-93df-03fe38159e04" />

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/bc9208f7-a41e-4657-8449-ad73ab258a01" />

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/e145667b-d2b6-435c-9800-f23ca4165767" />

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/c329bac7-7332-488d-be42-bb4867c9d02a" />

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/007b5bcc-0800-4bb2-9510-a3ef2956645c" />



### Demo

<div align="center">
  <video src="https://github.com/user-attachments/assets/2dfe5dcd-08f7-4e5f-8802-9f6263ede7f9" width="100%" controls>
    Your browser does not support the video tag.
  </video>
</div>

## TL;DR

This project, is a highly engineered stack of tooling, configurations, scripts, and custom software that transforms a completely blank, TTY only Debian (starts off without even having `sudo`) into the slick, keyboard driven workspace.

Not just a collection of dots (although pure dots are found [here](./config/)).

## Docs

If you want to dig through:

- [Starting](./docs/starting.md) (Want the eye candy? Instant theme switching, hypr, etc)
- [Workflow](./docs/workflow.md) (If you reach for a mouse, you've already lost)
- [Stack](./docs/stack.md) (If it ain't broke don't fix it)
- [Philosophy](./docs/philosophy.md) (Overall premise and why I'm doing this)

## Custom Tools

These are standalone tools written from scratch, that can be airdropped into any distro. Open sourced gradually (when stable):

### [lookas](https://github.com/rccyx/lookas)

A terminal audio visualizer built around human auditory perception. Moves beyond raw FFT twitchiness using Mel-scaling and spring damper physics.

```sh
cargo install lookas && lookas
```

<p align="center">
  <a href="https://github.com/rccyx/lookas">
    <img src="./assets/lookas.gif" alt="Demo" width="100%">
  </a>
</p>

### [asryx](https://github.com/rccyx/asryx)

Pure C++ voice to text binary for Linux, done the UNIX way. No dependencies beyond the standard C++ and Linux toolchain.

<p align="center">
  <a href="https://github.com/rccyx/asryx">
    <img src="./assets/asryx.gif" alt="Demo" width="100%">
  </a>
</p>

### [thyx](https://github.com/rccyx/thyx)

A QML based SDDM login screen with video backgrounds, fingerprint auth, and a composable design system. Terraform like state management for installation/uninstallation. Contains absolutely zero bloat, and fully configurable.

<div align="center">
  <video title="demo" src="https://github.com/user-attachments/assets/4e52f9d0-ac04-4167-adfc-d14506e9c59c" width="100%" controls>
    Your browser does not support the video tag.
  </video>
</div>

### Power menu (Next)

The glassmorphic power menu from the demo.

### Jarvis (Unreleased)

A headless CLI control center built to reduce the GUI footprint to just the browser and the editor. The central nervous system of the OS. Much of it is hardcoded to my setup and will be rolled out here gradually.

## And more...

There's more to come.

> [!TIP]
> This is a long term thing. So you might follow through.

## License

Apache-2.0 © @rccyx
