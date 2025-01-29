#!/bin/bash

# Cores para melhor visualização
VERDE='\033[0;32m'
VERMELHO='\033[0;31m'
AMARELO='\033[1;33m'
AZUL='\033[0;34m'
RESET='\033[0m'

# Função para mostrar o cabeçalho
mostrar_cabecalho() {
    clear
    echo -e "${AZUL}=============================================${RESET}"
    
    # Detecta se está rodando no WSL
    if grep -qi microsoft /proc/version; then
        echo -e "${VERDE}     MONITOR DO SISTEMA - WSL     ${RESET}"
        echo -e "${AZUL}=============================================${RESET}"
        echo -e "${AMARELO}Nota: Estas informações são do WSL,${RESET}"
        echo -e "${AMARELO}não do Windows host${RESET}"
    else
        echo -e "${VERDE}         MONITOR DO SISTEMA        ${RESET}"
        echo -e "${AZUL}=============================================${RESET}"
    fi
    
    echo -e "${AMARELO}Data: $(date +%d/%m/%Y)${RESET}"
    echo -e "${AMARELO}Hora: $(date +%H:%M:%S)${RESET}"
}

# Função para informações do sistema
info_sistema() {
    echo -e "\n${VERDE}=== Informações Básicas do Computador ===${RESET}"
    
    # Versão do sistema operacional
    OS=$(uname -s)
    case "$OS" in
        "Linux")
            if [ -f /etc/os-release ]; then
                OS=$(grep "PRETTY_NAME" /etc/os-release | cut -d'"' -f2)
            fi
            ;;
        "Darwin")
            OS="macOS $(sw_vers -productVersion)"
            ;;
    esac
    echo -e "Sistema Operacional: $OS"
    
    # Tempo ligado 
    uptime_str=$(uptime -p)
    uptime_str=${uptime_str//up /}
    uptime_str=${uptime_str// days/d}
    uptime_str=${uptime_str// day/d}
    uptime_str=${uptime_str// hours/h}
    uptime_str=${uptime_str// hour/h}
    uptime_str=${uptime_str// minutes/m}
    uptime_str=${uptime_str// minute/m}
    echo -e "Tempo ligado: $uptime_str"
    
    # Versão do kernel 
    kernel_version=$(uname -r)
    echo -e "Versão do sistema(Kernel): ${kernel_version%%-*}"
    
    # Nome do computador
    echo -e "Nome do computador: $(hostname)"
}

# Função para identificar melhor os processos Node.js
identificar_nodejs() {
    local cmd="$1"
    if [[ "$cmd" == *"next"* ]]; then
        echo "Next.js (Servidor de desenvolvimento)"
    elif [[ "$cmd" == *"react-scripts"* ]]; then
        echo "React (Servidor de desenvolvimento)"
    elif [[ "$cmd" == *"vscode"* ]] || [[ "$cmd" == *"code"* ]]; then
        echo "VS Code (Editor)"
    elif [[ "$cmd" == *"npm"* ]]; then
        echo "NPM (Gerenciador de pacotes Node.js)"
    else
        # Tenta pegar o nome do script que está rodando
        local script_name=$(echo "$cmd" | grep -o '[^/]*\.js' || echo "Node.js")
        echo "Node.js - $script_name"
    fi
}

# Função para monitorar CPU
monitorar_cpu() {
    echo -e "\n${VERDE}=== Uso do Processador ===${RESET}"
    echo -e "Total de programas em execução: $(ps aux | wc -l)"
    
    # Uso total da CPU de forma mais amigável
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')
    echo -e "Processador em uso: ${cpu_usage}%"
    
    echo -e "\n5 programas usando mais processamento:"
    ps aux | sort -nr -k 3 | head -5 | while read user pid cpu mem vsz rss tty stat start time cmd; do
        case "$cmd" in
            *"node"*)
                nome=$(identificar_nodejs "$cmd")
                ;;
            *"firefox"*)
                nome="Firefox (Navegador)"
                ;;
            *"chrome"*)
                nome="Google Chrome (Navegador)"
                ;;
            *"python"*)
                nome="Python (Programa/Script)"
                ;;
            *"bash"*)
                nome="Terminal"
                ;;
            *)
                nome="$cmd"
                ;;
        esac
        printf "%-50s %6.1f%%\n" "$nome" "$cpu"
    done
}

# Função para monitorar memória
monitorar_memoria() {
    echo -e "\n${VERDE}=== Uso da Memória RAM ===${RESET}"
    
    # Converte valores para GB e arredonda para 2 casas decimais
    total=$(free -g | awk '/^Mem/ {printf "%.1f", $2}')
    usado=$(free -g | awk '/^Mem/ {printf "%.1f", $3}')
    livre=$(free -g | awk '/^Mem/ {printf "%.1f", $4}')
    cache=$(free -g | awk '/^Mem/ {printf "%.1f", $6}')
    
    echo -e "Memória Total: ${total}GB"
    echo -e "Memória em Uso: ${usado}GB"
    echo -e "Memória Livre: ${livre}GB"
    echo -e "Memória em Cache: ${cache}GB"
    
    echo -e "\n5 programas usando mais memória:"
    ps aux | sort -nr -k 4 | head -5 | while read user pid cpu mem vsz rss tty stat start time cmd; do
        case "$cmd" in
            *"node"*)
                nome=$(identificar_nodejs "$cmd")
                ;;
            *"firefox"*)
                nome="Firefox (Navegador)"
                ;;
            *"chrome"*)
                nome="Google Chrome (Navegador)"
                ;;
            *"code"*)
                nome="VS Code (Editor de código)"
                ;;
            *"python"*)
                nome="Python (Programa/Script)"
                ;;
            *"bash"*)
                nome="Terminal"
                ;;
            *)
                nome="$cmd"
                ;;
        esac
        printf "%-50s %6.1f%%\n" "$nome" "$mem"
    done
}

# Função para monitorar disco
monitorar_disco() {
    echo -e "\n${VERDE}=== Armazenamento ===${RESET}"
    
    echo -e "Unidades conectadas:"
    
    # Lista apenas as unidades importantes e com descrições amigáveis
    df -h | grep -E '/mnt/[c-z]|/$' | while read fs size used avail use mnt; do
        case "$mnt" in
            "/mnt/c")
                echo -e "Windows (C:)\t$size\t$used usado\t$avail livre\t$use em uso"
                ;;
            "/mnt/d")
                echo -e "Dados (D:)\t$size\t$used usado\t$avail livre\t$use em uso"
                ;;
            "/")
                echo -e "Ubuntu WSL\t$size\t$used usado\t$avail livre\t$use em uso"
                ;;
            *)
                # Para outros discos que possam existir (E:, F:, etc)
                letra=${mnt##*/}
                letra=${letra^^} # Converte para maiúsculo
                echo -e "Unidade ($letra:)\t$size\t$used usado\t$avail livre\t$use em uso"
                ;;
        esac
    done
    
    # Removendo a parte que estava travando e substituindo por algo mais útil
    echo -e "\nPastas grandes no seu Ubuntu WSL:"
    du -h /home 2>/dev/null | sort -rh | head -3 | while read size path; do
        echo -e "$(basename $path)\t$size"
    done
}

# Função para monitorar rede
monitorar_rede() {
    echo -e "\n${VERDE}=== Informações de Rede ===${RESET}"
    
    # Verifica conexão com a internet
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        echo -e "${VERDE}✓ Internet conectada${RESET}"
    else
        echo -e "${VERMELHO}✗ Sem conexão com a internet${RESET}"
    fi
    
    echo -e "\nAdaptadores de rede ativos:"
    # Lista interfaces de rede de forma mais amigável
    ip -br addr show | while read line; do
        interface=$(echo $line | awk '{print $1}')
        status=$(echo $line | awk '{print $2}')
        ip=$(echo $line | awk '{print $3}')
        
        case "$interface" in
            "lo")
                # Ignora interface de loopback
                continue
                ;;
            "eth"*)
                nome="Conexão Ethernet"
                ;;
            "wlan"*)
                nome="Conexão Wi-Fi"
                ;;
            "wsl"*)
                nome="Conexão WSL"
                ;;
            *)
                nome="Conexão $interface"
                ;;
        esac
        
        if [ "$status" = "UP" ]; then
            echo -e "${VERDE}$nome: Conectado${RESET}"
            if [ ! -z "$ip" ]; then
                echo -e "   Endereço IP: $ip"
            fi
        else
            echo -e "${VERMELHO}$nome: Desconectado${RESET}"
        fi
    done
    
    echo -e "\nUso da rede:"
    # Mostra uso de rede de forma mais amigável
    for interface in $(ls /sys/class/net/ | grep -v "lo"); do
        rx=$(cat /sys/class/net/$interface/statistics/rx_bytes 2>/dev/null)
        tx=$(cat /sys/class/net/$interface/statistics/tx_bytes 2>/dev/null)
        if [ ! -z "$rx" ] && [ ! -z "$tx" ]; then
            case "$interface" in
                "eth"*)
                    nome="Ethernet"
                    ;;
                "wlan"*)
                    nome="Wi-Fi"
                    ;;
                "wsl"*)
                    nome="WSL"
                    ;;
                *)
                    nome="$interface"
                    ;;
            esac
            echo -e "$nome:"
            echo -e "   Recebido: $(numfmt --to=iec $rx)B"
            echo -e "   Enviado:  $(numfmt --to=iec $tx)B"
        fi
    done
    
    echo -e "\nConexões ativas: $(netstat -tn | grep ESTABLISHED | wc -l)"
}

# Loop principal
while true; do
    mostrar_cabecalho
    info_sistema
    monitorar_cpu
    monitorar_memoria
    monitorar_disco
    monitorar_rede
    
    echo -e "\n${AZUL}=============================================${RESET}"
    echo -e "${AMARELO}Pressione CTRL+C para sair${RESET}"
    echo -e "${AZUL}=============================================${RESET}"
    
    sleep 5  # Atualiza a cada 5 segundos
done


