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

log "Instalando Zoxide, FZF, Ripgrep e Neovim via Mise..."
eval "$(~/.local/bin/mise activate zsh)"
mise use -g zoxide@latest fzf@latest ripgrep@latest
sudo apt install batcat bat neovim byobu -y

log "Ferramentas de CLI instaladas!"



-----
#!/usr/bin/env bash

set -euo pipefail

log() { echo -e "\n\033[1;32m[+] $1\033[0m"; }
warn() { echo -e "\n\033[1;33m[-] $1\033[0m"; }

ACTION="${1:-install}"

if [ "$ACTION" = "--remove" ]; then
    warn "Iniciando a remoção dos utilitários CLI..."

    # 1. Remover pacotes instalados via APT
    log "Removendo pacotes APT (FZF, Bat, Neovim, Zoxide, Ripgrep, Byobu)..."
    sudo apt remove --purge -y fzf bat batcat neovim zoxide ripgrep byobu || true
    sudo apt autoremove -y

    # 2. Remover o link simbólico do bat
    if [ -L /usr/local/bin/bat ]; then
        log "Removendo link simbólico do bat..."
        sudo rm -f /usr/local/bin/bat
    fi

    # 3. Limpeza do Mise legado (caso ainda exista na máquina)
    if [ -f "$HOME/.local/bin/mise" ]; then
        log "Removendo resquícios do Mise em ~/.local/bin..."
        rm -f "$HOME/.local/bin/mise"
        rm -rf "$HOME/.local/share/mise" "$HOME/.config/mise"
    fi

    warn "Utilitários CLI removidos com sucesso!"
    exit 0
fi

# ==================== MODO DE INSTALAÇÃO ====================

log "Atualizando repositórios e instalando utilitários CLI..."

mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

if ! command -v mise &> /dev/null; then
    log "Instalando Mise..."
    curl https://mise.jdx.dev/mise-latest-linux-x64 > ~/.local/bin/mise
    chmod +x ~/.local/bin/mise
fi

sudo apt update
sudo apt install -y batcat bat neovim byobu
mise use fzf@latest zoxide@latest ripgrep@latest

# Corrige o nome do executável do bat no Debian/Ubuntu/Pop!_OS
if command -v batcat &> /dev/null && [ ! -f /usr/local/bin/bat ]; then
    log "Criando link simbólico /usr/local/bin/bat -> /usr/bin/batcat..."
    sudo ln -sfn /usr/bin/batcat /usr/local/bin/bat
fi

log "Ferramentas de CLI instaladas!"