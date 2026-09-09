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
    local interfaces=$(ip -br link show | awk '{print $1}' | grep -E "^(en|eth)" | head -5)
    echo "$interfaces"
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

validate_wol() {
    print_header "2. Validando configuração de Wake-on-LAN"
    
    local interfaces=$(detect_interfaces)
    
    if [ -z "$interfaces" ]; then
        print_error "Nenhuma interface de rede encontrada"
        exit 1
    fi
    
    echo -e "${BLUE}Interfaces de rede detectadas:${NC}"
    echo "$interfaces" | nl
    
    echo ""
    read -p "Selecione o número da interface a configurar: " interface_choice < /dev/tty
    
    INTERFACE=$(echo "$interfaces" | sed -n "${interface_choice}p")
    
    if [ -z "$INTERFACE" ]; then
        print_error "Interface inválida"
        exit 1
    fi
    
    print_info "Interface selecionada: $INTERFACE"
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
# 4. Configurar rede (netplan ou interfaces)
# ==========================================

detect_network_system() {
    if [ -d "/etc/netplan" ] && [ -f "/usr/sbin/netplan" ]; then
        echo "netplan"
    elif [ -f "/etc/network/interfaces" ]; then
        echo "interfaces"
    else
        echo "unknown"
    fi
}

configure_netplan() {
    print_header "4. Configurando arquivo de rede (netplan)"
    
    local netplan_dir="/etc/netplan"
    local netplan_file="$netplan_dir/01-netcfg.yaml"
    
    if [ ! -d "$netplan_dir" ]; then
        print_warning "Diretório netplan não encontrado. Você pode estar usando outro gerenciador de rede."
        return 1
    fi
    
    # Alterar permissões
    print_info "Ajustando permissões dos arquivos netplan..."
    chmod 600 "$netplan_dir"/*.yaml 2>/dev/null || true
    print_success "Permissões ajustadas"
    
    # Criar backup
    if [ -f "$netplan_file" ]; then
        cp "$netplan_file" "${netplan_file}.backup"
        print_info "Backup criado: ${netplan_file}.backup"
    fi
    
    # Adicionar configuração WoL
    echo ""
    print_info "Adicionando configuração WoL ao netplan..."
    echo ""
    
    cat > "$netplan_file" << EOF
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    $INTERFACE:
      wakeonlan: true
EOF
    
    print_success "Arquivo $netplan_file criado/atualizado"
    echo ""
    print_info "Conteúdo do arquivo:"
    cat "$netplan_file"
}

configure_interfaces() {
    print_header "4. Configurando arquivo de rede (interfaces)"
    
    local interfaces_file="/etc/network/interfaces"
    local interfaces_dir="/etc/network/interfaces.d"
    local temp_file=$(mktemp)
    
    if [ ! -f "$interfaces_file" ]; then
        print_warning "Arquivo $interfaces_file não encontrado"
        return 1
    fi
    
    # Criar backup
    cp "$interfaces_file" "${interfaces_file}.backup"
    print_info "Backup criado: ${interfaces_file}.backup"
    
    # Criar diretório se não existir
    if [ ! -d "$interfaces_dir" ]; then
        mkdir -p "$interfaces_dir"
        print_info "Diretório $interfaces_dir criado"
    fi
    
    # Adicionar configuração WoL
    echo ""
    print_info "Adicionando configuração WoL para interface $INTERFACE..."
    echo ""
    
    local found=0
    local in_interface=0
    local indent=""
    
    # Ler o arquivo original e adicionar WoL ao final da interface
    while IFS= read -r line; do
        echo "$line" >> "$temp_file"
        
        # Detectar se iniciamos a configuração da interface
        if [[ "$line" =~ ^iface[[:space:]]+$INTERFACE[[:space:]] ]]; then
            found=1
            in_interface=1
            # Pega o nível de indentação (geralmente 4 espaços)
            indent="    "
        elif [ "$in_interface" = "1" ] && [[ "$line" =~ ^[^[:space:]] ]]; then
            # Nova interface ou seção encontrada, fecha a anterior
            if [ "$found" = "1" ]; then
                # Adiciona linhas WoL antes desta nova linha
                sed -i '$ d' "$temp_file"  # Remove a última linha
                echo "${indent}post-up /usr/sbin/ethtool -s $INTERFACE wol g" >> "$temp_file"
                echo "${indent}post-down /usr/sbin/ethtool -s $INTERFACE wol d" >> "$temp_file"
                echo "$line" >> "$temp_file"
                found=0
                in_interface=0
            fi
        fi
    done < "$interfaces_file"
    
    # Se a interface estava no final do arquivo
    if [ "$found" = "1" ]; then
        echo "${indent}post-up /usr/sbin/ethtool -s $INTERFACE wol g" >> "$temp_file"
        echo "${indent}post-down /usr/sbin/ethtool -s $INTERFACE wol d" >> "$temp_file"
    fi
    
    # Copiar arquivo temporário para o original
    cp "$temp_file" "$interfaces_file"
    rm "$temp_file"
    
    print_success "Arquivo $interfaces_file atualizado"
    echo ""
    print_info "Seção da interface $INTERFACE:"
    grep -A 10 "^iface $INTERFACE" "$interfaces_file" | head -15
}

# ==========================================
# 5. Aplicar configurações
# ==========================================

apply_netplan() {
    print_header "5. Aplicando configurações"
    
    print_info "Executando: netplan apply"
    if netplan apply; then
        print_success "Configurações aplicadas com sucesso"
    else
        print_error "Erro ao aplicar configurações netplan"
        print_warning "Tente editar manualmente: nano /etc/netplan/01-netcfg.yaml"
        return 1
    fi
}

apply_interfaces() {
    print_header "5. Aplicando configurações"
    
    print_info "Reiniciando serviço de rede..."
    
    if systemctl restart networking; then
        print_success "Serviço de rede reiniciado com sucesso"
    else
        print_error "Erro ao reiniciar serviço de rede"
        print_warning "Tente manualmente: sudo systemctl restart networking"
        print_info "Ou reboot o sistema para aplicar as configurações"
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
    
    if validate_wol; then
        print_success "WoL já está ativado, pulando para configuração de rede..."
    else
        enable_wol
    fi
    
    # Detectar sistema de rede
    local network_system=$(detect_network_system)
    
    if [ "$network_system" = "netplan" ]; then
        configure_netplan
        apply_netplan
    elif [ "$network_system" = "interfaces" ]; then
        configure_interfaces
        apply_interfaces
    else
        print_error "Sistema de rede não identificado"
        print_warning "Use: netplan ou /etc/network/interfaces manualmente"
        return 1
    fi
    
    show_final_instructions
    
    print_success "Configuração concluída!"
    echo ""
}

# ==========================================
# Executar
# ==========================================

main "$@"
