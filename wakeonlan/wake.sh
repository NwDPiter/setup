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

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Verificar se é root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "Este script deve ser executado como root"
        echo "Execute: sudo ./wake.sh"
        exit 1
    fi
}

# Detectar interfaces de rede Ethernet
detect_interfaces() {
    if ! command -v nmcli &> /dev/null; then
        print_error "nmcli não está instalado ou não está disponível"
        return 1
    fi

    nmcli -t -f DEVICE,TYPE device status \
        | awk -F: '$2 == "ethernet" {print $1}'
}

# ==========================================
# 1. Instalar ethtool
# ==========================================

install_ethtool() {
    print_header "1. Instalando ethtool"
    
    if command -v ethtool &> /dev/null; then
        print_success "ethtool já está instalado"
    else
        print_info "Atualizando repositórios e instalando ethtool..."
        apt update && apt install -y ethtool
        print_success "ethtool instalado com sucesso"
    fi
}

# ==========================================
# 2. Validar configuração WoL
# ==========================================

select_interface() {
    local interfaces=$(detect_interfaces)

    if [ -z "$interfaces" ]; then
        print_error "Nenhuma interface de rede encontrada"
        exit 1
    fi
    
    echo -e "${BLUE}Interfaces Ethernet detectadas pelo NetworkManager:${NC}"
    echo "$interfaces" | nl
    
    echo ""
    read -p "Selecione o número da interface a configurar: " interface_choice < /dev/tty
    
    INTERFACE=$(echo "$interfaces" | sed -n "${interface_choice}p")
    
    if [ -z "$INTERFACE" ]; then
        print_error "Interface inválida"
        exit 1
    fi
    
    print_info "Interface selecionada: $INTERFACE"
}

validate_wol() {
    print_header "2. Validando configuração de Wake-on-LAN"

    echo ""
    print_info "Verificando status WoL da interface $INTERFACE:"
    echo ""
    
    WOL_STATUS=$(ethtool "$INTERFACE" | grep "Wake-on")
    echo "$WOL_STATUS"
    echo ""
    
    if echo "$WOL_STATUS" | grep -q "Wake-on: g"; then
        print_success "WoL já está ativado (g)"
        return 0
    elif echo "$WOL_STATUS" | grep -q "Wake-on: d"; then
        print_warning "WoL está desativado (d)"
        return 1
    else
        print_warning "Status do WoL desconhecido"
        echo "$WOL_STATUS"
        return 1
    fi
}

# ==========================================
# 3. Ativar WoL
# ==========================================

enable_wol() {
    print_header "3. Ativando Wake-on-LAN"
    
    print_info "Ativando WoL para $INTERFACE..."
    ethtool -s "$INTERFACE" wol g
    
    echo ""
    print_info "Nova configuração:"
    ethtool "$INTERFACE" | grep "Wake-on"
    echo ""
    
    if ethtool "$INTERFACE" | grep -q "Wake-on: g"; then
        print_success "WoL ativado com sucesso"
        return 0
    else
        print_error "Falha ao ativar WoL"
        return 1
    fi
}

# ==========================================
# 4. Configurar rede com NetworkManager
# ==========================================

configure_nmcli() {
    local wake_on_lan_mode="$1"

    print_header "4. Configurando Wake-on-LAN com NetworkManager"

    if ! command -v nmcli &> /dev/null; then
        print_error "nmcli não está instalado ou não está disponível"
        return 1
    fi

    local device_type
    local connection_name
    device_type=$(nmcli -g GENERAL.TYPE device show "$INTERFACE" 2>/dev/null || true)
    connection_name=$(nmcli -g GENERAL.CONNECTION device show "$INTERFACE" 2>/dev/null || true)

    if [ "$device_type" != "ethernet" ]; then
        print_error "A interface $INTERFACE não é uma interface Ethernet gerenciada pelo NetworkManager"
        return 1
    fi

    if [ -z "$connection_name" ] || [ "$connection_name" = "--" ]; then
        print_error "Nenhuma conexão ativa do NetworkManager foi encontrada para $INTERFACE"
        return 1
    fi

    CONNECTION_NAME="$connection_name"
    print_info "Interface validada: $INTERFACE"
    print_info "Conexão encontrada: $CONNECTION_NAME"
    if [ "$wake_on_lan_mode" = "magic" ]; then
        print_info "Ativando Wake-on-LAN por pacote mágico..."
    else
        print_info "Restaurando a configuração padrão de Wake-on-LAN..."
    fi

    nmcli connection modify "$CONNECTION_NAME" 802-3-ethernet.wake-on-lan "$wake_on_lan_mode"
    print_success "Configuração atualizada na conexão $CONNECTION_NAME"
}

apply_nmcli() {
    print_header "5. Aplicando configurações"

    print_info "Executando: nmcli device reapply $INTERFACE"
    if nmcli device reapply "$INTERFACE"; then
        print_success "Configurações aplicadas com sucesso"
    else
        print_error "Erro ao reaplicar as configurações em $INTERFACE"
        return 1
    fi
}

# ==========================================
# 6. Instruções Finais
# ==========================================

show_final_instructions() {
    print_header "6. Próximos Passos"
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  IMPORTANTE - Configurar BIOS${NC}"
    echo ""
    echo "Antes de testar o Wake-on-LAN, você DEVE configurar as seguintes opções na BIOS:"
    echo ""
    echo -e "${GREEN}1. Reiniciar por PME (Power Management Event): HABILITADO${NC}"
    echo "   └─ Permite que a placa de rede acorde a máquina"
    echo ""
    echo -e "${GREEN}2. Função EUP (Energy Efficient Processor): DESABILITADO${NC}"
    echo "   └─ Permite que a placa mantenha energia mínima para escutar os pacotes"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    print_header "Testando Wake-on-LAN"
    echo ""
    echo "Para testar WoL, use outro PC na mesma rede:"
    echo ""
    echo -e "${BLUE}wakeonlan -i <REDE_DO_PC> -p 7 ou 8 <MAC_DO_PC>${NC}"
    echo ""
    echo "Explicação dos parâmetros:"
    echo ""
    print_info "Descobrir MAC da interface:"
    echo "  $ ip a"
    echo "  └─ Procure por 'link/ether' na interface $INTERFACE"
    echo ""
    print_info "Descobrir a rede do PC:"
    echo "  $ ip -br a"
    echo "  └─ Use a informação de IP/NETMASK para calcular a rede"
    echo ""
    print_info "Exemplo de uso:"
    echo "  $ wakeonlan -i 192.168.1.255 -p 7 AA:BB:CC:DD:EE:FF"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    print_header "Informações do seu PC"
    echo ""
    echo "Interface configurada: $INTERFACE"
    echo ""
    print_info "MAC Address:"
    ip -br a | grep "$INTERFACE" || ip a show "$INTERFACE" | grep "link/ether"
    echo ""
    print_info "Endereço IP:"
    ip -br a | grep "$INTERFACE" || ip a show "$INTERFACE" | grep "inet "
    echo ""
    print_info "Rede (broadcast):"
    echo "  Use: ip -br a (ou calcule com base no NETMASK)"
    echo ""
}

# ==========================================
# Função Principal
# ==========================================

main() {
    clear
    print_header "Wake-on-LAN (WoL) - Configuração Universal para Linux"
    
    check_root
    
    install_ethtool

    select_interface

    echo ""
    echo "1) Ativar Wake-on-LAN por pacote mágico"
    echo "2) Desfazer configuração do Wake-on-LAN"
    echo ""
    read -p "Escolha uma opção: " wol_action < /dev/tty

    case "$wol_action" in
        1)
            if validate_wol; then
                print_success "WoL já está ativado"
            else
                enable_wol
            fi
            configure_nmcli "magic"
            apply_nmcli
            show_final_instructions
            print_success "Configuração concluída!"
            ;;
        2)
            configure_nmcli "default"
            apply_nmcli
            print_success "Configuração do Wake-on-LAN desfeita"
            ;;
        *)
            print_error "Opção inválida"
            return 1
            ;;
    esac

    echo ""
}

# ==========================================
# Executar
# ==========================================

main "$@"
