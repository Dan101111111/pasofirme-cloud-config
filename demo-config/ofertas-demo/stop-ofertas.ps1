$ErrorActionPreference = "Stop"
$scriptDir = $PSScriptRoot
Set-Location -Path $scriptDir

$jarPath = [System.IO.Path]::GetFullPath((Join-Path $scriptDir "target\ofertas-demo-0.0.1-SNAPSHOT.jar"))
$pidFile = [System.IO.Path]::GetFullPath((Join-Path $scriptDir ".ofertas.pid"))

$pidsToCheck = @()
if (Test-Path -LiteralPath $pidFile) {
    $rawPid = (Get-Content -LiteralPath $pidFile -Raw).Trim()
    if ($rawPid -match '^\d+$') { $pidsToCheck += [int]$rawPid }
}
$conn = Get-NetTCPConnection -LocalPort 18882 -State Listen -ErrorAction SilentlyContinue
if ($conn -and $conn.OwningProcess) {
    if ($pidsToCheck -notcontains $conn.OwningProcess) { $pidsToCheck += [int]$conn.OwningProcess }
}

if ($pidsToCheck.Count -eq 0) {
    Write-Host "No se encontro proceso para ofertas-demo (puerto 18882 libre)."
    if (Test-Path -LiteralPath $pidFile) { Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue }
    return
}

$stoppedAny = $false
foreach ($candidatePid in $pidsToCheck) {
    $procCim = Get-CimInstance Win32_Process | Where-Object { $_.ProcessId -eq $candidatePid }
    if ($procCim -and $procCim.CommandLine -and ($procCim.CommandLine -like "*$jarPath*")) {
        Write-Host "Deteniendo ofertas-demo (PID $candidatePid)..."
        Stop-Process -Id $candidatePid -Force
        $stoppedAny = $true
    }
}
if (Test-Path -LiteralPath $pidFile) { Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue }
if ($stoppedAny) { Write-Host "ofertas-demo detenido correctamente." }

