# Hyprland

Repo: `.config/hypr/hyprland.conf`  
Machine: `~/.config/hypr/hyprland.conf`

Each one of these files has self explaining docs.

The layout is:

```text
.config/hypr
├── appearance.conf
├── _clipboard.conf
├── env.conf
├── hyprland.conf
├── hyprlock.conf
├── input.conf
├── _keybinds.conf
├── keybinds.conf
├── monitors.conf
├── README.md
├── rules.conf
├── _startup.conf
├── startup.conf
├── theme.conf
├── _variables.conf
├── variables.conf
└── workspaces.conf
```

`hyprland.conf` is only the entry point. It owns load order.

Load order matters though. Environment comes first. Shared variables load before files that reference `$mod`, `$term`, `$menu`, and `$screenshot_dir`. Public behavior loads before private behavior, so the private layer can extend the base without mutating it.
