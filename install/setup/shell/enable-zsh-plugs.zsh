#/bin/zsh
set -e
ZSH_DIR="$HOME/.oh-my-zsh"

if [ ! -d "$ZSH_DIR" ]; then
  CACHE_DIR="$HOME/.cache/osyx-install"
  mkdir -p "$CACHE_DIR"
  curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o "$CACHE_DIR/ohmyzsh-install.sh"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes bash "$CACHE_DIR/ohmyzsh-install.sh"
fi

ZSH_CUSTOM="$ZSH_DIR/custom"
mkdir -p "$ZSH_CUSTOM/plugins"

[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] || \
  git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions \
  "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] || \
  git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting \
  "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

[ -d "$ZSH_CUSTOM/plugins/zsh-completions" ] || \
  git clone --depth 1 https://github.com/zsh-users/zsh-completions \
  "$ZSH_CUSTOM/plugins/zsh-completions"

mkdir -p "$HOME/.cache"

exec zsh
