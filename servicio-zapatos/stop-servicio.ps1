$ErrorActionPreference = "Stop"
$scriptDir = $PSScriptRoot
Set-Location -Path $scriptDir

$jarPath = [System.IO.Path]::GetFullPath((Join-Path $scriptDir "target\servicio-zapatos-0.0.1-SNAPSHOT.jar"))
$pidFile = [System.IO.Path]::GetFullPath((Join-Path $scriptDir ".servicio.pid"))

$pidsToCheck = @()

# 1. Candidato desde .servicio.pid
if (Test-Path -LiteralPath $pidFile) {
    $rawPid = (Get-Content -LiteralPath $pidFile -Raw).Trim()
    if ($rawPid -match '^\d+$') {
        $pidsToCheck += [int]$rawPid
    }
}

# 2. Candidato desde el puerto 18761
$conn = Get-NetTCPConnection -LocalPort 18761 -State Listen -ErrorAction SilentlyContinue
if ($conn -and $conn.OwningProcess) {
    if ($pidsToCheck -notcontains $conn.OwningProcess) {
        $pidsToCheck += [int]$conn.OwningProcess
    }
}

if ($pidsToCheck.Count -eq 0) {
    Write-Host "No se encontró ningún proceso candidato para servicio-zapatos (puerto 18761 libre)."
    if (Test-Path -LiteralPath $pidFile) { Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue }
    return
}

$stoppedAny = $false

foreach ($candidatePid in $pidsToCheck) {
    # VERIFICACIÓN ESTRICTA DE IDENTIDAD MEDIANTE CommandLine Y RUTA ABSOLUTA DEL JAR:
    $procCim = Get-CimInstance Win32_Process | Where-Object { $_.ProcessId -eq $candidatePid }
    if (-not $procCim) {
        continue
    }

    $cmdLine = $procCim.CommandLine
    if ($cmdLine -and ($cmdLine -like "*$jarPath*")) {
        Write-Host "Proceso verificado como servicio-zapatos de este proyecto (PID $candidatePid). Deteniendo..."
        Stop-Process -Id $candidatePid -Force

        # Esperar confirmación de detención
        $wait = 0
        while ((Get-Process -Id $candidatePid -ErrorAction SilentlyContinue) -and ($wait -lt 10)) {
            Start-Sleep -Milliseconds 500
            $wait++
        }
        $stoppedAny = $true
    } else {
        Write-Warning "El proceso con PID $candidatePid no coincide con el JAR de este proyecto ($jarPath). Por seguridad, NO se detendrá."
    }
}

if (Test-Path -LiteralPath $pidFile) {
    Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue
}

if ($stoppedAny) {
    Write-Host "Servicio Zapatos detenido correctamente."
} else {
    Write-Host "No se encontró ningún proceso con el JAR de servicio-zapatos en ejecución."
}
