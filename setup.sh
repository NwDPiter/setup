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
echo "1) Instalar Componentes"
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


    echo "1) Terminal & CLI (Sub-menu)"
    echo "2) Zabbix & Grafana (Sub-menu)"
    echo "3) Stack de Orquestração & Containers (sub-menu)"
    #echo "5) Apenas Utilitários CLI (FZF, Zoxide, Bat, Ripgrep, Nvim, Byobu)"
    echo "5) Sair"

    read_tty "\n\033[1;33mEscolha o perfil de ambiente desejado (1-5): \033[0m" PROFILE_CHOICE

    case "$PROFILE_CHOICE" in
        1)
            # Terminal& Shell + Utilitários CLI
            while true; do
                clear
                echo -e "\n\033[1;36m=== Terminal & CLI ===\033[0m\n"
                echo "1) Apenas Terminal & Shell (Zsh, Starship, Dotfiles)"
                echo "2) Apenas Utilitários CLI (FZF, Zoxide, Bat, Ripgrep, Nvim, Byobu)"
                echo "3) Ambos -> (Terminal & Shell + Utilitários CLI)"
                echo "4) Voltar ao Menu Principal"

                read_tty "\n\033[1;33mEscolha o combo desejado (1-4): \033[0m" COMBO_CHOICE

                case "$COMBO_CHOICE" in
                    1)
                        clear
                        bash <(curl -fsSL "$BASE_URL/scripts/zsh.sh") $MODE_FLAG < /dev/tty
                        exit 0
                        ;;
                    2)
                        clear
                        bash <(curl -fsSL "$BASE_URL/scripts/cli.sh") $MODE_FLAG < /dev/tty
                        exit 0
                        ;;
                    3)
                        clear
                        bash <(curl -fsSL "$BASE_URL/scripts/zsh.sh") $MODE_FLAG < /dev/tty
                        bash <(curl -fsSL "$BASE_URL/scripts/cli.sh") $MODE_FLAG < /dev/tty
                        exit 0
                        ;;
                    *)
                        echo "Opção inválida."
                        sleep 1
                        ;;
                esac
            done
            ;;
            
        2)
            while true; do
                clear
                echo -e "\n\033[1;36m=== Zabbix & Grafana? ===\033[0m\n"
                echo "1) Zabbix Agent 2 (Sub-menu)"
                #echo "2) Instalar Grafana Agent"
                echo "2) Voltar ao Menu Principal"

                read_tty "\n\033[1;33mEscolha a ação desejada (1-3): \033[0m" ZABBIX_CHOICE

                case "$ZABBIX_CHOICE" in
                    1)
                        clear
                        bash <(curl -fsSL "$BASE_URL/zabbix/agent2.sh") < /dev/tty
                        exit 0
                        ;;
                    2)
                        break # Volta para o laço do Menu Principal
                        ;;
                    *)
                        echo "Opção inválida."
                        sleep 1
                        ;;
                esac
            done
            ;;
        3) 
            while true; do
                clear
                echo -e "\n\033[1;36m=== Stack de Orquestração & Containers ===\033[0m\n"
                echo "1) Ambos -> (Docker + Kubernetes)"
                echo "2) Instalar -> (Docker, Compose, Lazydocker, Incus)"
                echo "3) Instalar -> (Kubernetes, Helm, K9s, jq, yq)"
                echo "4) Voltar ao Menu Principal"

                read_tty "\n\033[1;33mEscolha a ação desejada (1-4): \033[0m" STACK_CHOICE

                case "$STACK_CHOICE" in
                    1)
                        clear
                        bash <(curl -fsSL "$BASE_URL/scripts/docker.sh") $MODE_FLAG < /dev/tty
                        bash <(curl -fsSL "$BASE_URL/scripts/k8s.sh") $MODE_FLAG < /dev/tty
                        exit 0
                        ;;
                    2)
                        clear
                        bash <(curl -fsSL "$BASE_URL/scripts/docker.sh") $MODE_FLAG < /dev/tty
                        exit 0
                        ;;
                    3)
                        clear
                        bash <(curl -fsSL "$BASE_URL/scripts/k8s.sh") $MODE_FLAG < /dev/tty
                        exit 0
                        ;;
                    4)
                        break # Volta para o laço do Menu Principal
                        ;;
                    *)
                        echo "Opção inválida."
                        sleep 1
                        ;;
                esac
            done
            ;;



        4) clear; bash <(curl -fsSL "$BASE_URL/scripts/cli.sh") $MODE_FLAG < /dev/tty; exit 0 ;;
        5) clear; echo "Saindo..."; exit 0 ;;
        *) echo "Opção inválida."; sleep 1 ;;
    esac
done