#!/usr/bin/env bash

set -euo pipefail

log() { echo -e "\n\033[1;32m[+] $1\033[0m"; }
warn() { echo -e "\n\033[1;33m[-] $1\033[0m"; }

ACTION="${1:-install}"

if [ "$ACTION" = "--remove" ]; then
    warn "Iniciando a remoção da Stack de Containers..."

    # 1. Remover Lazydocker
    if command -v lazydocker &> /dev/null; then
        log "Removendo Lazydocker..."
        sudo rm -f /usr/local/bin/lazydocker
        rm -rf "$HOME/.config/lazydocker"
    fi

    # 2. Remover Incus
    if dpkg -l | grep -q "^ii  incus"; then
        log "Removendo Incus..."
        sudo apt-get purge -y incus incus-client
        sudo apt-get autoremove -y
    fi

    # 3. Remover Docker e Compose
    if command -v docker &> /dev/null; then
        log "Removendo Docker Engine e utilitários..."
        sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras || true
        sudo rm -rf /var/lib/docker /var/lib/containerd
        sudo gpasswd -d "$USER" docker 2>/dev/null || true
    fi

    warn "Stack de Containers removida com sucesso!"
    exit 0
fi

# ==================== MODO DE INSTALAÇÃO ====================

log "Iniciando instalação da Stack de Containers..."

# 1. Docker Engine
if ! command -v docker &> /dev/null; then
    log "Instalando Docker Engine..."
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker "$USER"
fi

# 2. Incus
if ! command -v incus &> /dev/null; then
    log "Instalando Incus..."
    sudo apt-get update -qq && sudo apt-get install -y -qq incus incus-client
fi

# 3. Lazydocker
if ! command -v lazydocker &> /dev/null; then
    log "Instalando Lazydocker..."
    LAZYDOCKER_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazydocker/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -sLo lazydocker.tar.gz "https://github.com/jesseduffield/lazydocker/releases/latest/download/lazydocker_${LAZYDOCKER_VERSION}_Linux_x86_64.tar.gz"
    tar -xf lazydocker.tar.gz lazydocker
    sudo install -m 0755 lazydocker /usr/local/bin/
    rm -f lazydocker.tar.gz lazydocker
fi

log "Stack de Containers instalada!"