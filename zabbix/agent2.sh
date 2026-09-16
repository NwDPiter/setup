#!/bin/bash

# Detectar o sistema operacional
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
        OS_VERSION=$(lsb_release -sr)
    else
        echo "Sistema operacional não identificado"
        exit 1
    fi
}

# Executar com privilégios de root
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        echo "Este script deve ser executado como root"
        exit 1
    fi
}

# Função para verificar os sttus do agente
check_status() {
    if systemctl is-active --quiet zabbix-agent2; then
        echo "Zabbix Agent2 está ativo e em execução"
    else
        echo "Zabbix Agent2 não está em execução"
        echo "Use: systemctl status zabbix-agent2"
    fi

}

# Solicitar e validar o IPv4 do servidor Zabbix
read_zabbix_server_ip() {
    local octet
    local -a octets

    while true; do
        read -r -p "Informe o IP do servidor Zabbix: " ZABBIX_SERVER_IP < /dev/tty

        if [[ "$ZABBIX_SERVER_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
            IFS='.' read -r -a octets <<< "$ZABBIX_SERVER_IP"

            if (( ${#octets[@]} == 4 && 10#${octets[0]} <= 255 && 10#${octets[1]} <= 255 && 10#${octets[2]} <= 255 && 10#${octets[3]} <= 255 )); then
                return 0
            fi
        fi

        echo "IP inválido. Informe um endereço IPv4, por exemplo: 192.168.1.10"
    done
}

# Solicitar e validar o nome do host monitorado
read_zabbix_host_name() {
    while true; do
        read -r -p "Informe o nome do host monitorado: " ZABBIX_HOST_NAME < /dev/tty

        if [[ "$ZABBIX_HOST_NAME" =~ ^[A-Za-z0-9._-]+$ ]]; then
            return 0
        fi

        echo "Nome inválido. Use apenas letras, números, ponto, hífen ou sublinhado."
    done
}

# Configurar o endereço do servidor no agente
configure_zabbix_agent() {
    local config_file="/etc/zabbix/zabbix_agent2.conf"

    read_zabbix_server_ip
    read_zabbix_host_name

    sed -i -E "s|^[[:space:]]*#?[[:space:]]*Server=.*$|Server=$ZABBIX_SERVER_IP|" "$config_file"
    sed -i -E "s|^[[:space:]]*#?[[:space:]]*ServerActive=.*$|ServerActive=$ZABBIX_SERVER_IP|" "$config_file"
    sed -i -E "s|^[[:space:]]*#?[[:space:]]*Hostname=.*$|Hostname=$ZABBIX_HOST_NAME|" "$config_file"

    echo "Servidor Zabbix configurado: $ZABBIX_SERVER_IP"
    echo "Host monitorado configurado: $ZABBIX_HOST_NAME"
}


# Instalar Zabbix Agent2 em Ubuntu
install_ubuntu() {
    echo "Instalando Zabbix Agent2 em Ubuntu $OS_VERSION..."
    
    if ! command -v wget &> /dev/null; then
        apt update && apt install -y wget
    fi
        wget https://repo.zabbix.com/zabbix/7.4/release/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.4+ubuntu24.04_all.deb
        dpkg -i zabbix-release_latest_7.4+ubuntu24.04_all.deb
        apt update 

        apt install -y zabbix-agent2
        apt install -y zabbix-agent2-plugin-mongodb zabbix-agent2-plugin-mssql zabbix-agent2-plugin-postgresql

        configure_zabbix_agent
        systemctl restart zabbix-agent2
        systemctl enable zabbix-agent2

        echo "Zabbix Agent2 instalado com sucesso em Ubuntu"
}

# Instalar Zabbix Agent2 em Debian
install_debian() {
    echo "Instalando Zabbix Agent2 em Debian $OS_VERSION..."
    
    if [ ! command -v wget &> /dev/null ]; then
        apt update && apt install -y wget
    fi

    wget https://repo.zabbix.com/zabbix/7.4/release/debian/pool/main/z/zabbix-release/zabbix-release_latest_7.4+debian13_all.deb
    dpkg -i zabbix-release_latest_7.4+debian13_all.deb
    apt update 
    
    apt install -y zabbix-agent2
    apt install -y zabbix-agent2-plugin-mongodb zabbix-agent2-plugin-mssql zabbix-agent2-plugin-postgresql
    
    configure_zabbix_agent
    systemctl restart zabbix-agent2
    systemctl enable zabbix-agent2
    
    echo "Zabbix Agent2 instalado com sucesso em Debian"
}

# Remover Zabbix Agent2 em Ubuntu
remove_ubuntu() {
    echo "Removendo Zabbix Agent2 em Ubuntu $OS_VERSION..."
    
    systemctl stop zabbix-agent2
    systemctl disable zabbix-agent2
    
    apt remove -y zabbix-agent2
    apt remove -y zabbix-agent2-plugin-mongodb zabbix-agent2-plugin-mssql zabbix-agent2-plugin-postgresql
    apt remove -y zabbix-release
    apt autoremove -y
    
    echo "Zabbix Agent2 removido com sucesso de Ubuntu"
}

# Remover Zabbix Agent2 em Debian
remove_debian() {
    echo "Removendo Zabbix Agent2 em Debian $OS_VERSION..."
    
    systemctl stop zabbix-agent2
    systemctl disable zabbix-agent2
    
    apt remove -y zabbix-agent2
    apt remove -y zabbix-agent2-plugin-mongodb zabbix-agent2-plugin-mssql zabbix-agent2-plugin-postgresql
    apt remove -y zabbix-release
    apt autoremove -y
    
    echo "Zabbix Agent2 removido com sucesso de Debian"
}

# Menu de escolha para o usuário
choose_action() {
    echo ""
    echo "========================================"
    echo "Zabbix Agent2 - Instalação/Remoção"
    echo "========================================"
    echo "1) Instalar Zabbix Agent2"
    echo "2) Remover Zabbix Agent2"
    echo "3) Verificar status do Zabbix Agent2"
    echo "0) Sair"
    echo "========================================"
    echo "OBS: Este script suporta apenas Ubuntu(24.04) e Debian(13)"
    echo ""
    read -p "Escolha uma opção (0-3): " choice < /dev/tty
    clear
    
    case "$choice" in
        1)
            return 1  # Instalar
            ;;
        2)
            return 2  # Remover
            ;;
        3)
            return 3  # Verificar status
            ;;
        0)
            echo "Saindo..."
            exit 0
            ;;
        *)
            echo "Opção inválida!"
            sleep 1
            choose_action
            ;;
    esac
}

# Função principal
main() {
    check_root
    detect_os
    
    echo "Sistema detectado: $OS $OS_VERSION"
    echo ""
    
    # Verificar se o SO é suportado
    case "$OS" in
        ubuntu|debian)
            action=$?
            ;;
        *)
            echo "SO não suportado: $OS"
            echo "Este script suporta apenas Ubuntu(24.04) e Debian(13)"
            exit 1
            ;;
    esac
    
    while true; do
        choose_action
        action=$?

        # Executar a ação escolhida
        case "$action" in
            1)  # Instalar
                case "$OS" in
                    ubuntu)
                        install_ubuntu
                        ;;
                    debian)
                        install_debian
                        ;;
                esac
                ;;
            2)  # Remover
                case "$OS" in
                    ubuntu)
                        remove_ubuntu
                        ;;
                    debian)
                        remove_debian
                        ;;
                esac
                ;;
            3)  # Verificar status
                check_status
                ;;
        esac

        read -r -p "Pressione Enter para voltar ao menu..." < /dev/tty
    done
}

# Executar
main