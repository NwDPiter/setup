#!/bin/bash

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[1;36m'
NC='\033[0m' # No Color

# ==========================================
# Funções Auxiliares
# ==========================================

print_header() {
    echo -e "\n${CYAN}=== $1 ===${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Validar se é um MAC válido
validate_mac() {
    local mac="$1"
    if [[ $mac =~ ^([0-9A-Fa-f]{2}:){5}([0-9A-Fa-f]{2})$ ]]; then
        return 0
    else
        return 1
    fi
}

# Validar se é um IP/CIDR válido
validate_broadcast() {
    local ip="$1"
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 0
    else
        return 1
    fi
}

# ==========================================
# Menu Principal
# ==========================================

show_menu() {
    print_header "Wake-on-LAN Test Tool"
    
    echo "1) Testar WoL (enviar Magic Packet)"
    echo "2) Verificar informações de rede do PC local"
    echo "3) Verificar status WoL do PC local"
    echo "0) Sair"
    echo ""
}

# ==========================================
# Opção 1: Testar WoL
# ==========================================

test_wol() {
    print_header "Testando Wake-on-LAN"
    
    # Verificar se wakeonlan está instalado
    if ! command -v wakeonlan &> /dev/null; then
        print_error "wakeonlan não está instalado"
        print_info "Instale com: sudo apt install wakeonlan -y"
        return 1
    fi
    
    # Pedir informações
    echo ""
    read -p "Digite o MAC do PC (ex: AA:BB:CC:DD:EE:FF): " MAC_ADDRESS
    
    # Validar MAC
    if ! validate_mac "$MAC_ADDRESS"; then
        print_error "MAC inválido. Use formato: AA:BB:CC:DD:EE:FF"
        return 1
    fi
    
    read -p "Digite o endereço de broadcast (ex: 192.168.1.255): " BROADCAST
    
    # Validar broadcast
    if ! validate_broadcast "$BROADCAST"; then
        print_error "Endereço de broadcast inválido"
        return 1
    fi
    
    read -p "Digite a porta (padrão 7, ou 8): " PORT
    PORT=${PORT:-7}
    
    if ! [[ $PORT =~ ^[0-9]+$ ]] || [ $PORT -lt 1 ] || [ $PORT -gt 65535 ]; then
        print_error "Porta inválida"
        return 1
    fi
    
    echo ""
    print_info "Enviando Magic Packet..."
    echo "  MAC: $MAC_ADDRESS"
    echo "  Broadcast: $BROADCAST"
    echo "  Porta: $PORT"
    echo ""
    
    if wakeonlan -i "$BROADCAST" -p "$PORT" "$MAC_ADDRESS"; then
        print_success "Magic Packet enviado com sucesso!"
        echo ""
        print_info "O PC deve acordar em alguns segundos..."
    else
        print_error "Erro ao enviar Magic Packet"
        return 1
    fi
}

# ==========================================
# Opção 2: Informações de Rede
# ==========================================

show_network_info() {
    print_header "Informações de Rede do PC Local"
    
    echo ""
    print_info "Interfaces de rede:"
    echo ""
    
    ip -br a | grep -v "^lo"
    
    echo ""
    echo -e "${YELLOW}Para mais detalhes, execute:${NC}"
    echo "  ip a show <interface>"
    echo ""
    echo -e "${BLUE}Exemplo para calcular broadcast:${NC}"
    echo "  Se o IP/NETMASK for 192.168.1.100/24, o broadcast é 192.168.1.255"
    echo "  Se o IP/NETMASK for 192.168.0.50/25, o broadcast é 192.168.0.127"
    echo ""
}

# ==========================================
# Opção 3: Status WoL
# ==========================================

show_wol_status() {
    print_header "Status Wake-on-LAN"
    
    if ! command -v ethtool &> /dev/null; then
        print_error "ethtool não está instalado"
        print_info "Instale com: sudo apt install ethtool -y"
        return 1
    fi
    
    echo ""
    local interfaces=$(ip -br link show | grep -E "ether" | awk '{print $1}' | grep -v "^lo$")
    
    if [ -z "$interfaces" ]; then
        print_error "Nenhuma interface de rede encontrada"
        return 1
    fi
    
    for interface in $interfaces; do
        echo -e "${BLUE}Interface: $interface${NC}"
        
        # Mostrar MAC
        MAC=$(ip -br a show "$interface" | awk '{print $3}')
        echo "  MAC: $MAC"
        
        # Mostrar WoL status
        echo "  WoL Status:"
        sudo ethtool "$interface" 2>/dev/null | grep "Wake-on" | sed 's/^/    /'
        
        echo ""
    done
}

# ==========================================
# Loop Principal
# ==========================================

main() {
    while true; do
        clear
        show_menu
        
        read -p "Escolha uma opção (0-3): " choice
        
        case "$choice" in
            1)
                test_wol
                read -p "Pressione ENTER para continuar..."
                ;;
            2)
                show_network_info
                read -p "Pressione ENTER para continuar..."
                ;;
            3)
                show_wol_status
                read -p "Pressione ENTER para continuar..."
                ;;
            0)
                echo "Saindo..."
                exit 0
                ;;
            *)
                print_error "Opção inválida"
                sleep 1
                ;;
        esac
    done
}

# ==========================================
# Executar
# ==========================================

main "$@"
