#!/usr/bin/env bash

set -euo pipefail

log() { echo -e "\n\033[1;32m[+] $1\033[0m"; }
warn() { echo -e "\n\033[1;33m[-] $1\033[0m"; }

ACTION="${1:-install}"

if [ "$ACTION" = "--remove" ]; then
    warn "Iniciando a remoção das configurações de Terminal, Shell e Dotfiles..."

    # 1. Reverter o shell padrão para Bash se estiver no Zsh
    if [ "$SHELL" = "$(which zsh 2>/dev/null)" ]; then
        log "Restaurando o Bash como shell padrão..."
        sudo chsh -s "$(which bash)" "$USER"
    fi

    # 2. Remover plugins manuais do Zsh
    if [ -d "$HOME/.zsh-plugins" ]; then
        log "Removendo plugins do Zsh (~/.zsh-plugins)..."
        rm -rf "$HOME/.zsh-plugins"
    fi

    # 3. Remover arquivos de configuração (dotfiles)
    log "Removendo configurações (.zshrc e starship.toml)..."
    rm -f "$HOME/.zshrc" "$HOME/.config/starship.toml"

    # 4. Desinstalar Starship
    if command -v starship &> /dev/null; then
        log "Removendo o binário do Starship..."
        sudo rm -f /usr/local/bin/starship
    fi

    # 5. Remover Zsh via APT (mantendo git e curl que são utilitários gerais do sistema)
    if dpkg -l | grep -q "^ii  zsh"; then
        log "Removendo pacote Zsh via APT..."
        sudo apt-get purge -y -qq zsh || true
        sudo apt-get autoremove -y -qq
    fi

    warn "Ambiente de terminal e shell removido com sucesso!"
    exit 0
fi

# ==================== MODO DE INSTALAÇÃO ====================

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