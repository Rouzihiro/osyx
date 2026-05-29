# Gitconfig

This is only for themed Git output, mainly log style aliases that match the active palette.

The root Git config at [`~/.gitconfig`](/.gitconfig) includes it like this:

```ini
[include]
    path = .gitconfig.d/theme
```

The config is modular:

```text
.gitconfig.d/
├── config
├── aliases
├── theme
└── _user
```

Aside from theme, the other files are normal Git behavior, aliases, and personal identity.

For adoption, the only UI requirement is this:

```sh
git config --global include.path ~/.gitconfig.d/theme
```
