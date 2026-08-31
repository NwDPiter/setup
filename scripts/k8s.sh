#!/usr/bin/env bash

set -euo pipefail

log() { echo -e "\n\033[1;32m[+] $1\033[0m"; }
warn() { echo -e "\n\033[1;33m[-] $1\033[0m"; }

# Detecta se a flag --remove foi passada
ACTION="${1:-install}"

if [ "$ACTION" = "--remove" ]; then
    warn "Iniciando a remoção da Stack de Kubernetes..."

    # 1. Remover kubectl
    if command -v kubectl &> /dev/null; then
        log "Removendo kubectl..."
        sudo rm -f /usr/local/bin/kubectl
    fi

    # 2. Remover Helm
    if command -v helm &> /dev/null; then
        log "Removendo Helm..."
        sudo rm -f /usr/local/bin/helm
    fi

    # 3. Remover K9s
    if command -v k9s &> /dev/null; then
        log "Removendo K9s..."
        sudo rm -f /usr/local/bin/k9s
        rm -rf "$HOME/.config/k9s" "$HOME/.local/state/k9s"
    fi

    # 4. Remover yq
    if [ -f /usr/local/bin/yq ]; then
        log "Removendo yq..."
        sudo rm -f /usr/local/bin/yq
    fi

    # 5. Remover jq
    if dpkg -l | grep -q "^ii  jq"; then
        log "Removendo jq via APT..."
        sudo apt remove -y jq
    fi

    warn "Stack de Kubernetes removida com sucesso!"
    exit 0
fi

# ==================== MODO DE INSTALAÇÃO ====================

log "Iniciando instalação da Stack de Kubernetes..."

# 1. Kubectl
if ! command -v kubectl &> /dev/null; then
    log "Instalando kubectl..."
    KUBE_VER=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    curl -LO "https://dl.k8s.io/release/${KUBE_VER}/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
fi

# 2. Helm
if ! command -v helm &> /dev/null; then
    log "Instalando Helm..."
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# 3. K9s
if ! command -v k9s &> /dev/null; then
    log "Instalando K9s..."
    K9S_VER=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    curl -sL "https://github.com/derailed/k9s/releases/download/${K9S_VER}/k9s_Linux_amd64.tar.gz" | tar xz -C /tmp
    sudo mv /tmp/k9s /usr/local/bin/k9s
fi

# 4. jq e yq
log "Instalando jq e yq..."
sudo apt update && sudo apt install -y jq

if ! command -v yq &> /dev/null; then
    YQ_VER=$(curl -s https://api.github.com/repos/mikefarah/yq/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    sudo wget -q "https://github.com/mikefarah/yq/releases/download/${YQ_VER}/yq_linux_amd64" -O /usr/local/bin/yq
    sudo chmod +x /usr/local/bin/yq
fi

log "Stack de Kubernetes instalada!"