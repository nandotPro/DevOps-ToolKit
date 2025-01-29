#!/bin/bash

echo "=== Monitor do Sistema ==="
echo "Data e Hora: $(date)"
echo "Uptime do Sistema: $(uptime -p)"
echo "Uso de CPU:"
top -bn1 | grep "Cpu(s)" | awk '{print "  Uso: " $2 "%"}'
echo "Uso de Memória:"
free -h | awk '/Mem/ {print "  Total: " $2, "| Usado: " $3, "| Livre: " $4}'
echo "Uso de Disco:"
df -h | awk '$NF=="/"{print "  Total: " $2, "| Usado: " $3, "| Livre: " $4}'

