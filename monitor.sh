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

# Função para monitorar CPU
monitorar_cpu() {
    echo -e "\n${VERDE}=== Uso de CPU ===${RESET}"
    echo -e "Processos: $(ps aux | wc -l)"
    top -bn1 | grep "Cpu(s)" | awk '{print "CPU em uso: " $2 "%"}'
    echo -e "\nTop 5 processos por CPU:"
    ps aux | sort -nr -k 3 | head -5 | awk '{print $2,$3"%",$11}'
}

# Função para monitorar memória
monitorar_memoria() {
    echo -e "\n${VERDE}=== Uso de Memória ===${RESET}"
    free -h | awk '/^Mem/ {print "Total: " $2 "\nUsado: " $3 "\nLivre: " $4 "\nBuffer/Cache: " $6}'
    echo -e "\nTop 5 processos por uso de memória:"
    ps aux | sort -nr -k 4 | head -5 | awk '{print $2,$4"%",$11}'
}

# Função para monitorar disco
monitorar_disco() {
    echo -e "\n${VERDE}=== Uso de Disco ===${RESET}"
    df -h | grep -v "tmpfs" | awk 'BEGIN {print "Montagem\tTotal\tUsado\tLivre\tUso%"} 
        NR>1 {print $6"\t"$2"\t"$3"\t"$4"\t"$5}'
    
    echo -e "\nMaiores diretórios em /:"
    du -h / 2>/dev/null | sort -rh | head -5
}

# Função para monitorar rede
monitorar_rede() {
    echo -e "\n${VERDE}=== Informações de Rede ===${RESET}"
    echo -e "Interfaces de rede:"
    ip -br addr show
    echo -e "\nConexões ativas:"
    netstat -tun | awk 'NR>2 {print $4,$5}'
    echo -e "\nBandwidth por interface:"
    for interface in $(ls /sys/class/net/); do
        rx=$(cat /sys/class/net/$interface/statistics/rx_bytes 2>/dev/null)
        tx=$(cat /sys/class/net/$interface/statistics/tx_bytes 2>/dev/null)
        if [ ! -z "$rx" ] && [ ! -z "$tx" ]; then
            echo "$interface - RX: $(numfmt --to=iec $rx)B TX: $(numfmt --to=iec $tx)B"
        fi
    done
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


