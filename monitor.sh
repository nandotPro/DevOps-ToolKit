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
    echo -e "${VERDE}         MONITOR AVANÇADO DO SISTEMA        ${RESET}"
    echo -e "${AZUL}=============================================${RESET}"
    echo -e "${AMARELO}Data: $(date +%d/%m/%Y)${RESET}"
    echo -e "${AMARELO}Hora: $(date +%H:%M:%S)${RESET}"
}

# Função para informações do sistema
info_sistema() {
    echo -e "\n${VERDE}=== Informações do Sistema ===${RESET}"
    echo -e "Sistema: $(uname -a)"
    echo -e "Uptime: $(uptime -p)"
    echo -e "Kernel: $(uname -r)"
    echo -e "Hostname: $(hostname)"
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


