# ==============================================================================
# Script: Remove-ADComputersBulk.ps1
# Descrição: Remoção em lote de objetos de computador no Active Directory.
# Desenvolvido com auxílio de IA para automação de governança de TI.
# ==============================================================================

# Definição de caminhos
$Pasta = $PSScriptRoot
$ListaHosts = Join-Path $Pasta "computadores_para_remover.txt"

# Variável de Simulação (Deixe $true para apenas testar, $false para deletar de verdade)
$WhatIf = $true 

if (-not (Test-Path $ListaHosts)) {
    Write-Host "ERRO: O arquivo computadores_para_remover.txt não foi encontrado." -ForegroundColor Red
    exit
}

# Importa lista de hostnames ignorando linhas vazias
$hosts = Get-Content -Path $ListaHosts | Where-Object { $_.Trim() -ne "" }

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Iniciando limpeza de AD para $($hosts.Count) host(s)..." -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

foreach ($h in $hosts) {
    try {
        if ($WhatIf) {
            Write-Host "[SIMULACAO] O computador '${h}' seria removido do AD." -ForegroundColor Yellow
        } else {
            # O comando abaixo requer o módulo ActiveDirectory instalado
            Remove-ADComputer -Identity $h -Confirm:$false -ErrorAction Stop
            Write-Host "SUCESSO: Host '${h}' removido com sucesso!" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "ERRO ao processar '${h}': $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Processo concluído!" -ForegroundColor Cyan
