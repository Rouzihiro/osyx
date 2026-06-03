# ───────────────────────────────
# Tools — shell integrations
# Starship prompt, zoxide, thefuck, FZF defaults.
# ───────────────────────────────

# thefuck
eval "$(thefuck --alias)"

# zoxide (smart cd)
eval "$(zoxide init zsh)"

# Starship prompt
eval "$(starship init zsh)"
export STARSHIP_CONFIG="$HOME/.config/starship.toml"

# ─── FZF defaults ───
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_DEFAULT_OPTS=$'
  --height 40%
  --layout=reverse
  --preview-window=:wrap
  --preview "
    mime=$(file --mime-type -Lb {})
    if [[ $mime == text/* ]]; then
      bat --style=plain --color=always {}
    elif [[ $mime == image/* ]]; then
      viu -w 40 -h 20 {}
    elif [[ $mime == application/pdf ]]; then
      pdftotext {} - | head -50
    elif [[ $mime == audio/* ]]; then
      exiftool {}
    else
      echo {} is $mime
    fi
  "
'
