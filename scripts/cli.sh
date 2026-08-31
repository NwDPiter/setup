#!/usr/bin/env bash

set -euo pipefail

log() { echo -e "\n\033[1;32m[+] $1\033[0m"; }

mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

if ! command -v mise &> /dev/null; then
    log "Instalando Mise..."
    curl https://mise.jdx.dev/mise-latest-linux-x64 > ~/.local/bin/mise
    chmod +x ~/.local/bin/mise
fi

log "Instalando Zoxide, Bat, FZF, Ripgrep e Neovim via Mise..."
eval "$(~/.local/bin/mise activate zsh)"
mise use -g zoxide@latest fzf@latest ripgrep@latest

log "Ferramentas de CLI instaladas!"