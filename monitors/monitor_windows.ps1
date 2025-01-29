# Cores para melhor visualização
$VERDE = [System.ConsoleColor]::Green
$VERMELHO = [System.ConsoleColor]::Red
$AMARELO = [System.ConsoleColor]::Yellow
$AZUL = [System.ConsoleColor]::Cyan
$RESET = [System.ConsoleColor]::White

# Função para mostrar o cabeçalho
function Mostrar-Cabecalho {
    Clear-Host
    Write-Host "=============================================" -ForegroundColor $AZUL
    Write-Host "         MONITOR DO SISTEMA WINDOWS          " -ForegroundColor $VERDE
    Write-Host "=============================================" -ForegroundColor $AZUL
    Write-Host "Data: $(Get-Date -Format 'dd/MM/yyyy')" -ForegroundColor $AMARELO
    Write-Host "Hora: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor $AMARELO
}

# Função para informações do sistema
function Info-Sistema {
    Write-Host "`n=== Informações Básicas do Computador ===" -ForegroundColor $VERDE
    
    $os = Get-CimInstance Win32_OperatingSystem
    $comp = Get-CimInstance Win32_ComputerSystem
    
    Write-Host "Sistema Operacional: Windows $($os.Version)"
    Write-Host "Tempo ligado: $([math]::Round($os.LastBootUpTime.DateTime.Subtract([DateTime]::Now).TotalHours * -1)) horas"
    Write-Host "Nome do computador: $($comp.Name)"
    Write-Host "Fabricante: $($comp.Manufacturer)"
    Write-Host "Modelo: $($comp.Model)"
}

# Função para monitorar CPU
function Monitorar-CPU {
    Write-Host "`n=== Uso do Processador ===" -ForegroundColor $VERDE
    
    $cpu = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue
    $cpuUso = [math]::Round($cpu.CounterSamples.CookedValue)
    Write-Host "Processador em uso: $cpuUso%"
    
    Write-Host "`n5 programas usando mais processamento:"
    Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 | ForEach-Object {
        $nome = switch -Wildcard ($_.ProcessName) {
            "chrome" { "Google Chrome (Navegador)" }
            "firefox" { "Firefox (Navegador)" }
            "code" { "VS Code (Editor)" }
            "explorer" { "Explorador de Arquivos" }
            "Teams" { "Microsoft Teams" }
            default { $_.ProcessName }
        }
        Write-Host ("{0,-40} {1,6:N1}%" -f $nome, $_.CPU)
    }
}

# Função para monitorar memória
function Monitorar-Memoria {
    Write-Host "`n=== Uso da Memória RAM ===" -ForegroundColor $VERDE
    
    $os = Get-CimInstance Win32_OperatingSystem
    $total = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $livre = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $usado = $total - $livre
    
    Write-Host "Memória Total: $total GB"
    Write-Host "Memória em Uso: $usado GB"
    Write-Host "Memória Livre: $livre GB"
    
    Write-Host "`n5 programas usando mais memória:"
    Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 5 | ForEach-Object {
        $nome = switch -Wildcard ($_.ProcessName) {
            "chrome" { "Google Chrome (Navegador)" }
            "firefox" { "Firefox (Navegador)" }
            "code" { "VS Code (Editor)" }
            "explorer" { "Explorador de Arquivos" }
            "Teams" { "Microsoft Teams" }
            default { $_.ProcessName }
        }
        $memMB = [math]::Round($_.WorkingSet / 1MB, 2)
        Write-Host ("{0,-40} {1,6:N2} MB" -f $nome, $memMB)
    }
}

# Função para monitorar disco
function Monitorar-Disco {
    Write-Host "`n=== Armazenamento ===" -ForegroundColor $VERDE
    
    Write-Host "Unidades conectadas:"
    Get-Volume | Where-Object { $_.DriveLetter -ne $null } | ForEach-Object {
        $usado = [math]::Round(($_.Size - $_.SizeRemaining) / 1GB, 2)
        $total = [math]::Round($_.Size / 1GB, 2)
        $livre = [math]::Round($_.SizeRemaining / 1GB, 2)
        $porcentagem = [math]::Round(($usado / $total) * 100, 1)
        
        $nome = switch ($_.DriveLetter) {
            "C" { "Windows (C:)" }
            "D" { "Dados (D:)" }
            default { "Unidade ($($_.DriveLetter):)" }
        }
        
        Write-Host "$nome`t${total}GB total`t${usado}GB usado`t${livre}GB livre`t${porcentagem}% em uso"
    }
}

# Função para monitorar rede
function Monitorar-Rede {
    Write-Host "`n=== Informações de Rede ===" -ForegroundColor $VERDE
    
    # Verifica conexão com a internet
    $ping = Test-Connection 8.8.8.8 -Count 1 -Quiet
    if ($ping) {
        Write-Host "✓ Internet conectada" -ForegroundColor $VERDE
    } else {
        Write-Host "✗ Sem conexão com a internet" -ForegroundColor $VERMELHO
    }
    
    Write-Host "`nAdaptadores de rede ativos:"
    Get-NetAdapter | Where-Object Status -eq "Up" | ForEach-Object {
        $nome = switch -Wildcard ($_.Name) {
            "*Ethernet*" { "Conexão Ethernet" }
            "*Wi-Fi*" { "Conexão Wi-Fi" }
            default { $_.Name }
        }
        Write-Host "$nome:" -ForegroundColor $VERDE
        $ip = Get-NetIPAddress -InterfaceIndex $_.ifIndex -AddressFamily IPv4
        Write-Host "   Endereço IP: $($ip.IPAddress)"
    }
    
    Write-Host "`nConexões ativas: $((Get-NetTCPConnection -State Established).Count)"
}

# Loop principal
while ($true) {
    Mostrar-Cabecalho
    Info-Sistema
    Monitorar-CPU
    Monitorar-Memoria
    Monitorar-Disco
    Monitorar-Rede
    
    Write-Host "`n=============================================" -ForegroundColor $AZUL
    Write-Host "Pressione CTRL+C para sair" -ForegroundColor $AMARELO
    Write-Host "=============================================" -ForegroundColor $AZUL
    
    Start-Sleep -Seconds 5
}