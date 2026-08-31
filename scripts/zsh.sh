#!/usr/bin/env bash

set -euo pipefail

log() { echo -e "\n\033[1;32m[+] $1\033[0m"; }

log "Instalando Zsh, Git e Starship..."
sudo apt-get update -qq && sudo apt-get install -y -qq zsh curl git

if ! command -v starship &> /dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

log "Baixando dotfiles (.zshrc e starship.toml)..."
curl -fsSL https://pdrops.net/config/.zshrc -o ~/.zshrc
mkdir -p ~/.config
#curl -fsSL https://pdrops.net/config/starship.toml -o ~/.config/starship.toml

log "Garantindo plugins manuais do Zsh..."
mkdir -p ~/.zsh-plugins
[ ! -d "$HOME/.zsh-plugins/zsh-autosuggestions" ] && git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh-plugins/zsh-autosuggestions
[ ! -d "$HOME/.zsh-plugins/zsh-syntax-highlighting" ] && git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh-plugins/zsh-syntax-highlighting

if [ "$SHELL" != "$(which zsh)" ]; then
    log "Definindo Zsh como shell padrão..."
    sudo chsh -s "$(which zsh)" "$USER"
fi

log "Terminal e Starship configurados!"