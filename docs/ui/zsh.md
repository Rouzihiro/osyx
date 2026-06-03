# Zsh

The shell is split into a small loader and four modules.

```text
config/.zshrc        -> ~/.zshrc
config/zsh/          -> ~/zsh/
├── _env.zsh
├── core.zsh
├── tools.zsh
└── _aliases.zsh
```

`~/.zshrc` only controls load order.

`_env.zsh` comes first because it sets `PATH`, locale, Oh My Zsh, plugins, toolchains, editor, Nix, Conda, NVM, PNPM, Go, Rust, Bun, and GPG state.

Oh My Zsh loads after that because it needs `$ZSH` and `plugins`.

`core.zsh` owns shell behavior: completion, options, history, word movement, and `time` output.

`tools.zsh` loads Starship, zoxide, thefuck, and FZF defaults.

`_aliases.zsh` loads last because it's personal command muscle memory.

Underscore files are personal. Read them before copying.

> [!TIP]
> Remove a tool integration/sourcing if the command doesn't exist on your machine.

## Porting

Copy the files:

```sh
mkdir -p ~/zsh
cp config/zsh ~
cp config/.zshrc ~/.zshrc
```

Edit the personal files first:

```sh
nvim ~/zsh/_env.zsh
nvim ~/zsh/_aliases.zsh
```

Then reload:

```sh
source ~/.zshrc
```
