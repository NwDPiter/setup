#!/usr/bin/env bash

set -euo pipefail

BASE_URL="https://pdrops.net"

# Função auxiliar para ler a resposta direto do teclado do usuário (TTY)
# Isso impede que o bash tente ler o input do pipe do curl
read_tty() {
    local prompt_msg="$1"
    local target_var="$2"
    echo -ne "$prompt_msg"
    read -r "$target_var" < /dev/tty
}

# ==========================================
# 1. Menu de Seleção de Modo
# ==========================================
clear
echo -e "\n\033[1;36m=== pdrops.net Workstation Setup & Management ===\033[0m\n"
echo "1) Instalar Componentes (Apenas user atual)"
echo "2) Remover / Desinstalar Componentes"
echo "3) Sair"

read_tty "\n\033[1;33mEscolha a ação desejada (1-3): \033[0m" MODE_CHOICE

MODE_FLAG=""
case "$MODE_CHOICE" in
    1) MODE_FLAG="" ;;
    2) MODE_FLAG="--remove" ;;
    3) echo "Saindo..."; exit 0 ;;
    *) echo "Opção inválida."; exit 1 ;;
esac

# ==========================================
# 2. Menu de Seleção de Perfis
# ==========================================
while true; do
    clear
    echo -e "\n\033[1;36m=== Seleção de Perfil ===\033[0m\n"
    echo "1) Combos Customizados (Sub-menu)"
    echo "2) Perfil Completo (Terminal + CLI + Docker + K8s)"
    echo "3) Apenas Terminal & Shell (Zsh, Starship, Dotfiles)"
    echo "4) Apenas Utilitários CLI (FZF, Zoxide, Bat, Ripgrep, Nvim, Byobu)"
    echo "5) Apenas Stack Containers (Docker, Compose, Lazydocker, Incus)"
    echo "6) Apenas Stack Kubernetes (kubectl, Helm, K9s, jq, yq)"
    echo "7) Sair"

    read_tty "\n\033[1;33mEscolha o perfil de ambiente desejado (1-7): \033[0m" PROFILE_CHOICE

    case "$PROFILE_CHOICE" in
        1)
            # Sub-menu de Combos
            while true; do
                clear
                echo -e "\n\033[1;36m=== Combos Customizados ===\033[0m\n"
                echo "1) Combo Workstation (Terminal/Shell + Utilitários CLI)"
                echo "2) Combo DevOps Infra (Containers + Kubernetes)"
                echo "3) Voltar ao Menu Principal"

                read_tty "\n\033[1;33mEscolha o combo desejado (1-3): \033[0m" COMBO_CHOICE

                case "$COMBO_CHOICE" in
                    1)
                        clear
                        bash <(curl -fsSL "$BASE_URL/scripts/zsh.sh") $MODE_FLAG < /dev/tty
                        bash <(curl -fsSL "$BASE_URL/scripts/cli.sh") $MODE_FLAG < /dev/tty
                        exit 0
                        ;;
                    2)
                        clear
                        bash <(curl -fsSL "$BASE_URL/scripts/docker.sh") $MODE_FLAG < /dev/tty
                        bash <(curl -fsSL "$BASE_URL/scripts/k8s.sh") $MODE_FLAG < /dev/tty
                        exit 0
                        ;;
                    3)
                        break # Volta para o laço do Menu Principal
                        ;;
                    *)
                        echo "Opção inválida."
                        sleep 1
                        ;;
                esac
            done
            ;;
        2)
            clear
            bash <(curl -fsSL "$BASE_URL/scripts/zsh.sh") $MODE_FLAG < /dev/tty
            bash <(curl -fsSL "$BASE_URL/scripts/cli.sh") $MODE_FLAG < /dev/tty
            bash <(curl -fsSL "$BASE_URL/scripts/docker.sh") $MODE_FLAG < /dev/tty
            bash <(curl -fsSL "$BASE_URL/scripts/k8s.sh") $MODE_FLAG < /dev/tty
            exit 0
            ;;
        3) clear; bash <(curl -fsSL "$BASE_URL/scripts/zsh.sh") $MODE_FLAG < /dev/tty; exit 0 ;;
        4) clear; bash <(curl -fsSL "$BASE_URL/scripts/cli.sh") $MODE_FLAG < /dev/tty; exit 0 ;;
        5) clear; bash <(curl -fsSL "$BASE_URL/scripts/docker.sh") $MODE_FLAG < /dev/tty; exit 0 ;;
        6) clear; bash <(curl -fsSL "$BASE_URL/scripts/k8s.sh") $MODE_FLAG < /dev/tty; exit 0 ;;
        7) clear; echo "Saindo..."; exit 0 ;;
        *) echo "Opção inválida."; sleep 1 ;;
    esac
done