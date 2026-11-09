$ErrorActionPreference = "Stop"
$scriptDir = $PSScriptRoot
Set-Location -Path $scriptDir

$jarPath = [System.IO.Path]::GetFullPath((Join-Path $scriptDir "target\config-server-demo-0.0.1-SNAPSHOT.jar"))
$pidFile = [System.IO.Path]::GetFullPath((Join-Path $scriptDir ".config-server.pid"))

$pidsToCheck = @()

# 1. Candidato desde .config-server.pid
if (Test-Path -LiteralPath $pidFile) {
    $rawPid = (Get-Content -LiteralPath $pidFile -Raw).Trim()
    if ($rawPid -match '^\d+$') {
        $pidsToCheck += [int]$rawPid
    }
}

# 2. Candidato desde el puerto 18888
$conn = Get-NetTCPConnection -LocalPort 18888 -State Listen -ErrorAction SilentlyContinue
if ($conn -and $conn.OwningProcess) {
    if ($pidsToCheck -notcontains $conn.OwningProcess) {
        $pidsToCheck += [int]$conn.OwningProcess
    }
}

if ($pidsToCheck.Count -eq 0) {
    Write-Host "No se encontro ningun proceso candidato para config-server-demo (puerto 18888 libre)."
    if (Test-Path -LiteralPath $pidFile) { Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue }
    return
}

$stoppedAny = $false

foreach ($candidatePid in $pidsToCheck) {
    # Verificacion estricta mediante CommandLine y ruta absoluta del JAR
    $procCim = Get-CimInstance Win32_Process | Where-Object { $_.ProcessId -eq $candidatePid }
    if (-not $procCim) {
        continue
    }

    $cmdLine = $procCim.CommandLine
    if ($cmdLine -and ($cmdLine -like "*$jarPath*")) {
        Write-Host "Proceso verificado como config-server-demo (PID $candidatePid). Deteniendo..."
        Stop-Process -Id $candidatePid -Force

        $wait = 0
        while ((Get-Process -Id $candidatePid -ErrorAction SilentlyContinue) -and ($wait -lt 10)) {
            Start-Sleep -Milliseconds 500
            $wait++
        }
        $stoppedAny = $true
    } else {
        Write-Warning "El proceso con PID $candidatePid no coincide con el JAR de este proyecto ($jarPath). Por seguridad, NO se detendra."
    }
}

if (Test-Path -LiteralPath $pidFile) {
    Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue
}

if ($stoppedAny) {
    Write-Host "config-server-demo detenido correctamente."
} else {
    Write-Host "No se encontro ningun proceso con el JAR de este proyecto en ejecucion."
}

