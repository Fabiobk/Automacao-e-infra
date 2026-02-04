# ==============================================================================
# Script: PingEmLote.ps1
# Descrição: Testa a conectividade de uma lista de hosts e reporta os offline.
# Desenvolvido com auxílio de IA para otimização de infraestrutura.
# ==============================================================================

# Define a pasta do script como local de trabalho (Caminho Relativo)
$Pasta = $PSScriptRoot
$ListaHosts = Join-Path $Pasta "hosts.txt"
$SaidaOff = Join-Path $Pasta "ping_off.txt"

# Verifica se o arquivo de entrada existe
if (-not (Test-Path $ListaHosts)) {
    Write-Host "ERRO: O arquivo hosts.txt não foi encontrado na pasta do script." -ForegroundColor Red
    exit
}

# Remove o arquivo de saída anterior (se existir) para um novo relatório
if (Test-Path $SaidaOff) { Remove-Item $SaidaOff }

# Lê os nomes de host ou IPs do arquivo
$Hosts = Get-Content $ListaHosts

Write-Host "Iniciando teste de ping em $($Hosts.Count) hosts..." -ForegroundColor Cyan
Write-Host "--------------------------------------"

foreach ($NomeHost in $Hosts) {
    # Realiza o teste de conexão silencioso
    $Resultado = Test-Connection -ComputerName $NomeHost -Count 1 -Quiet -ErrorAction SilentlyContinue
    
    if (-not $Resultado) {
        Write-Host "OFFLINE -> $NomeHost" -ForegroundColor Red
        Add-Content -Path $SaidaOff -Value $NomeHost
    }
    else {
        Write-Host "ONLINE  -> $NomeHost" -ForegroundColor Green
    }
}

Write-Host "--------------------------------------"
Write-Host "Teste concluído! Relatório gerado em: $SaidaOff" -ForegroundColor Yellow
