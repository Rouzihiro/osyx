# Zsh

The shell is split into a small loader and four modules.

```text
.zshrc
zsh/
├── _env.zsh
├── core.zsh
├── tools.zsh
└── _aliases.zsh
```

`~/.zshrc` only controls load order.

## Load order

`_env.zsh` comes first because it sets `PATH`, locale, Oh My Zsh, plugins, toolchains, editor, Nix, Conda, NVM, PNPM, Go, Rust, Bun, and GPG state.

Oh My Zsh loads after that because it needs `$ZSH` and `plugins`.

`core.zsh` owns shell behavior: completion, options, history, word movement, and `time` output.

`tools.zsh` loads Starship, zoxide, thefuck, and FZF defaults.

`_aliases.zsh` loads last because it's personal command muscle memory.

## File roles

| File           | Role                                                 |
| -------------- | ---------------------------------------------------- |
| `.zshrc`       | loader only                                          |
| `core.zsh`     | completion, shell options, history                   |
| `tools.zsh`    | Starship, zoxide, thefuck, FZF                       |
| `_env.zsh`     | personal environment, paths, toolchains, GPG, editor |
| `_aliases.zsh` | personal aliases                                     |

Underscore files are personal. Read them before copying.

## Common layer

These are the portable files:

```text
core.zsh
tools.zsh
```

`core.zsh` enables completion, dotfile completion, interactive comments, `autocd`, natural numeric sorting, safer history behavior, and a cleaner `time` format.

`tools.zsh` wires the interactive tools:

```text
starship
zoxide
thefuck
fzf
fd
bat
viu
pdftotext
exiftool
```

Remove a tool integration if the command doesn't exist on your machine.

## Personal layer

These are machine-specific:

```text
_env.zsh
_aliases.zsh
```

`_env.zsh` contains local paths and toolchains. Check it before sourcing, especially:

```text
Nix
Conda
NVM
PNPM
Go
Rust
Bun
MATLAB
GPG_TTY
Oh My Zsh plugins
```

`_aliases.zsh` contains personal shorthand like:

```sh
alias v="nvim"
alias j="just"
alias tt="tmux"
alias reload=". ~/.zshrc"
alias sdn="shutdown -h now"
alias l="lsd -a"
```

Copy only the aliases you actually want.

## Porting

Copy the files:

```sh
mkdir -p ~/zsh
cp zsh/core.zsh zsh/tools.zsh zsh/_env.zsh zsh/_aliases.zsh ~/zsh/
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

## Debugging

Syntax check:

```sh
zsh -n ~/.zshrc
zsh -n ~/zsh/_env.zsh
zsh -n ~/zsh/core.zsh
zsh -n ~/zsh/tools.zsh
zsh -n ~/zsh/_aliases.zsh
```

Check missing tools:

```sh
command -v starship zoxide thefuck fzf fd bat lsd eza
```

Reset completion cache:

```sh
rm -f ~/.cache/zcompdump*
autoload -Uz compinit
compinit -d "$HOME/.cache/zcompdump"
```

## Rule

Keep `.zshrc` boring.

Keep common behavior in `core.zsh` and `tools.zsh`.

Keep machine state in `_env.zsh`.

Keep personal shortcuts in `_aliases.zsh`.
