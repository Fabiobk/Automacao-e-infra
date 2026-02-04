# ==============================================================================
# Script: Auditoria-Inventario-AD.ps1
# Descrição: Auditoria cruzada entre Rede (Ping), AD e Registro Remoto.
# Objetivo: Identificar máquinas órfãs, versões de OS e tempo de inatividade.
# Desenvolvido com auxílio de IA para governança de ativos de TI.
# ==============================================================================

# Caminho dos arquivos baseado na pasta do script
$Pasta = $PSScriptRoot
$hostsFile = Join-Path $Pasta "hosts.txt"
$reportFile = Join-Path $Pasta "relatorio_auditoria.txt"

if (-not (Test-Path $hostsFile)) {
    Write-Host "ERRO: Crie o arquivo hosts.txt com a lista de computadores." -ForegroundColor Red
    exit
}

$hosts = Get-Content $hostsFile
$total = $hosts.Count
$contador = 0

function Test-PingFast {
    param($hostName)
    if (Test-Connection -ComputerName $hostName -Count 1 -Quiet) { return "ON" } else { return "OFF" }
}

function ObterInfoAD {
    param($hostName)
    try {
        $ad = Get-ADComputer -Identity $hostName -Properties LastLogonDate -ErrorAction Stop
        $lastLogon = $ad.LastLogonDate
        $dias = if ($lastLogon) { (New-TimeSpan -Start $lastLogon -End (Get-Date)).Days } else { "N/A" }
        return @{AD="Encontrado"; LastLogon=$dias}
    } catch {
        return @{AD="Não encontrado"; LastLogon="N/A"}
    }
}

function ObterWindowsVersion {
    param($hostName)
    try {
        $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $hostName)
        $subKey = $reg.OpenSubKey("SOFTWARE\Microsoft\Windows NT\CurrentVersion")
        $osName = $subKey.GetValue("ProductName")
        $osBuild = $subKey.GetValue("CurrentBuild")
        $reg.Close() # Fecha a conexão remota
        return "$osName ($osBuild)"
    } catch {
        return "Acesso Negado/Erro"
    }
}

# Inicializa Relatório
$header = "{0,-20} | {1,-6} | {2,-15} | {3,-15} | {4,-25}" -f "HOSTNAME", "PING", "STATUS AD", "DIAS SEM LOGON", "ACAO SUGERIDA"
$sep = "-" * 90
$header | Out-File $reportFile
$sep | Out-File $reportFile -Append

foreach ($hostName in $hosts) {
    $contador++
    Write-Host "[$contador/$total] Analisando: $hostName" -ForegroundColor Cyan

    $ping = Test-PingFast $hostName
    $infoAD = ObterInfoAD $hostName
    $winVer = if ($ping -eq "ON") { ObterWindowsVersion $hostName } else { "Offline" }

    # Lógica de tomada de decisão (Governança)
    if ($ping -eq "OFF" -and $infoAD.AD -eq "Não encontrado") { $acao = "Descartar (Inativo)" }
    elif ($ping -eq "ON" -and $infoAD.AD -eq "Não encontrado") { $acao = "Regularizar no AD" }
    elif ($ping -eq "OFF" -and $infoAD.AD -eq "Encontrado") { $acao = "Check Físico (Offline)" }
    else { $acao = "OK" }

    $line = "{0,-20} | {1,-6} | {2,-15} | {3,-15} | {4,-25}" -f $hostName, $ping, $infoAD.AD, $infoAD.LastLogon, $acao
    $line | Out-File $reportFile -Append
}

Write-Host "`nRelatório gerado com sucesso em: $reportFile" -ForegroundColor Green
