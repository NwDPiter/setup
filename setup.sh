#!/usr/bin/env bash

set -euo pipefail

exec < /dev/tty

BASE_URL="https://pdrops.net"

# 1. Menu de Seleção de Modo (Instalar / Remover)
clear
echo -e "\n\033[1;36m=== pdrops.net Workstation Setup & Management ===\033[0m\n"

PS3_MODE=$'\n\033[1;33mEscolha a ação desejada (1-3): \033[0m'
mode_options=(
    "Instalar Componentes (Apenas user atual)"
    "Remover / Desinstalar Componentes"
    "Sair"
)

MODE_FLAG=""

PS3="$PS3_MODE"
select mode_opt in "${mode_options[@]}"; do
    case $REPLY in
        1)
            MODE_FLAG=""
            break
            ;;
        2)
            MODE_FLAG="--remove"
            break
            ;;
        3)
            echo "Saindo..."
            exit 0
            ;;
        *)
            echo "Opção inválida."
            ;;
    esac
done

# 2. Menu de Seleção de Perfis
PS3_PROFILE=$'\n\033[1;33mEscolha o perfil de ambiente desejado (1-7): \033[0m'
profile_options=(
    "Combos Customizados (Sub-menu)"
    "Perfil Completo (Terminal + CLI + Docker + K8s)"
    "Apenas Terminal & Shell (Zsh, Starship, Dotfiles)"
    "Apenas Utilitários CLI (FZF, Zoxide, Bat, Ripgrep, Nvim, Byobu, Mise)"
    "Apenas Stack Containers (Docker, Compose, Lazydocker, Incus)"
    "Apenas Stack Kubernetes (kubectl, Helm, K9s, jq, yq)"
    "Sair"
)

PS3="$PS3_PROFILE"

while true; do
    clear
    echo -e "\n\033[1;36m=== Seleção de Perfil ===\033[0m\n"
    
    select opt in "${profile_options[@]}"; do
        case $REPLY in
            1)
                # Sub-menu de Combos
                PS3_COMBO=$'\n\033[1;33mEscolha o combo desejado (1-3): \033[0m'
                combo_options=(
                    "Combo Workstation (Terminal/Shell + Utilitários CLI)"
                    "Combo DevOps Infra (Containers + Kubernetes)"
                    "Voltar ao Menu Principal"
                )
                
                while true; do
                    clear
                    echo -e "\n\033[1;36m=== Combos Customizados ===\033[0m\n"
                    PS3="$PS3_COMBO"
                    
                    select combo in "${combo_options[@]}"; do
                        case $REPLY in
                            1)
                                clear
                                bash <(curl -fsSL "$BASE_URL/scripts/zsh.sh") $MODE_FLAG
                                bash <(curl -fsSL "$BASE_URL/scripts/cli.sh") $MODE_FLAG
                                exit 0
                                ;;
                            2)
                                clear
                                bash <(curl -fsSL "$BASE_URL/scripts/docker.sh") $MODE_FLAG
                                bash <(curl -fsSL "$BASE_URL/scripts/k8s.sh") $MODE_FLAG
                                exit 0
                                ;;
                            3)
                                # Restaura o prompt e volta para o loop pai que limpará a tela
                                PS3="$PS3_PROFILE"
                                clear
                                echo -e "\n\033[1;36m=== Seleção de Perfil ===\033[0m\n"
                                REPLY=""
                                break 2
                                ;;
                            *)
                                echo "Opção inválida."
                                ;;
                        esac
                    done
                done
                ;;
            2)
                clear
                bash <(curl -fsSL "$BASE_URL/scripts/zsh.sh") $MODE_FLAG
                bash <(curl -fsSL "$BASE_URL/scripts/cli.sh") $MODE_FLAG
                bash <(curl -fsSL "$BASE_URL/scripts/docker.sh") $MODE_FLAG
                bash <(curl -fsSL "$BASE_URL/scripts/k8s.sh") $MODE_FLAG
                exit 0
                ;;
            3) clear; bash <(curl -fsSL "$BASE_URL/scripts/zsh.sh") $MODE_FLAG; exit 0 ;;
            4) clear; bash <(curl -fsSL "$BASE_URL/scripts/cli.sh") $MODE_FLAG; exit 0 ;;
            5) clear; bash <(curl -fsSL "$BASE_URL/scripts/docker.sh") $MODE_FLAG; exit 0 ;;
            6) clear; bash <(curl -fsSL "$BASE_URL/scripts/k8s.sh") $MODE_FLAG; exit 0 ;;
            7) clear; echo "Saindo..."; exit 0 ;;
            *) echo "Opção inválida." ;;
        esac
    done
done