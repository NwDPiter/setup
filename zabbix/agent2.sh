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

# Instalar Zabbix Agent2 em Ubuntu
install_ubuntu() {
    echo "Instalando Zabbix Agent2 em Ubuntu $OS_VERSION..."
    
    if [ ! command -v wget &> /dev/null]; then
        apt update && apt install -y wget
    fi
        wget https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.0+ubuntu24.04_all.deb
        dpkg -i zabbix-release_latest_7.0+ubuntu24.04_all.deb
        apt update

        apt install -y zabbix-agent2
        apt install -y zabbix-agent2-plugin-mongodb zabbix-agent2-plugin-mssql zabbix-agent2-plugin-postgresql

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
    wget https://repo.zabbix.com/zabbix/7.0/debian/pool/main/z/zabbix-release/zabbix-release_latest_7.0+debian13_all.deb
    dpkg -i zabbix-release_latest_7.0+debian13_all.deb
    apt update
    
    apt install -y zabbix-agent2
    apt install -y zabbix-agent2-plugin-mongodb zabbix-agent2-plugin-mssql zabbix-agent2-plugin-postgresql
    
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
    echo "0) Sair"
    echo "========================================"
    echo "OBS: Este script suporta apenas Ubuntu(24.04) e Debian(13)"
    echo ""
    read -p "Escolha uma opção (0-2): " choice < /dev/tty
    
    case "$choice" in
        1)
            return 1  # Instalar
            ;;
        2)
            return 2  # Remover
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
            choose_action
            action=$?
            ;;
        *)
            echo "SO não suportado: $OS"
            echo "Este script suporta apenas Ubuntu(24.04) e Debian(13)"
            exit 1
            ;;
    esac
    
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
    esac
}

# Executar
main