# Gitconfig

This is only for themed Git output, mainly log style aliases that match the active palette.

The repo copy is [`config/.gitconfig`](/config/.gitconfig). Installed as `~/.gitconfig`, it includes the themed output like this:

```ini
[include]
    path = .gitconfig.d/theme
```

The config is modular:

```text
config/.gitconfig.d/
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
