$ErrorActionPreference = "Stop"
$scriptDir = $PSScriptRoot
Set-Location -Path $scriptDir

$jarPath = [System.IO.Path]::GetFullPath((Join-Path $scriptDir "target\catalogo-demo-0.0.1-SNAPSHOT.jar"))
$logOut = [System.IO.Path]::GetFullPath((Join-Path $scriptDir "catalogo.log"))
$logErr = [System.IO.Path]::GetFullPath((Join-Path $scriptDir "catalogo-err.log"))
$pidFile = [System.IO.Path]::GetFullPath((Join-Path $scriptDir ".catalogo.pid"))
$mvnwCmd = [System.IO.Path]::GetFullPath((Join-Path $scriptDir "mvnw.cmd"))

# 1. Resolucion dinamica de Java y comprobacion de version
$javaExe = $null
if ($env:JAVA_HOME -and (Test-Path -LiteralPath "$env:JAVA_HOME\bin\java.exe")) {
    $javaExe = [System.IO.Path]::GetFullPath("$env:JAVA_HOME\bin\java.exe")
} else {
    $javaCmd = Get-Command java -ErrorAction SilentlyContinue
    if ($javaCmd) {
        $javaExe = $javaCmd.Source
    }
}

if (-not $javaExe) {
    throw "No se encontro Java en el sistema. Configure JAVA_HOME o agregue java al PATH."
}

$rawVer = cmd.exe /c "`"$javaExe`" -version 2>&1"
$rawString = $rawVer -join "`n"
$majorVer = $null
if ($rawString -match 'version\s+"(\d+)') {
    $majorVer = [int]$Matches[1]
}

if (-not $majorVer -or $majorVer -lt 21) {
    throw "La version de Java no es compatible. Spring Boot 4.1.2 requiere Java 21 o superior."
}

# 2. Comprobar si el puerto 18881 esta ocupado
$existingConn = Get-NetTCPConnection -LocalPort 18881 -State Listen -ErrorAction SilentlyContinue
if ($existingConn) {
    $procCim = Get-CimInstance Win32_Process | Where-Object { $_.ProcessId -eq $existingConn.OwningProcess }
    if ($procCim -and $procCim.CommandLine -and ($procCim.CommandLine -like "*$jarPath*")) {
        Write-Host "catalogo-demo ya esta activo en el puerto 18881 (PID $($existingConn.OwningProcess))."
        return
    } else {
        throw "El puerto 18881 esta ocupado por otro proceso (PID $($existingConn.OwningProcess)). No se detendran procesos ajenos."
    }
}

# 3. Compilar si el JAR no existe
if (-not (Test-Path -LiteralPath $jarPath)) {
    Write-Host "El artefacto JAR no existe. Compilando con Maven Wrapper..."
    & $mvnwCmd -DskipTests package
    if ($LASTEXITCODE -ne 0) {
        throw "Fallo en la compilacion de catalogo-demo."
    }
}

# 4. Iniciar el proceso
Write-Host "Iniciando catalogo-demo en segundo plano..."
$proc = Start-Process -FilePath $javaExe -ArgumentList "-jar", "`"$jarPath`"" -WorkingDirectory $scriptDir -WindowStyle Hidden -PassThru -RedirectStandardOutput $logOut -RedirectStandardError $logErr
$proc.Id | Set-Content -LiteralPath $pidFile -Force

# 5. Esperar confirmacion de salud
$maxWaitSeconds = 45
$elapsed = 0
$startedSuccessfully = $false

Write-Host "Esperando respuesta en http://localhost:18881/actuator/health..."
while ($elapsed -lt $maxWaitSeconds) {
    Start-Sleep -Seconds 2
    $elapsed += 2

    try {
        $response = Invoke-WebRequest -Uri "http://localhost:18881/actuator/health" -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            $startedSuccessfully = $true
            break
        }
    } catch {
    }
}

if (-not $startedSuccessfully) {
    throw "Tiempo de espera agotado sin respuesta HTTP 200 en http://localhost:18881/actuator/health. Revise los logs."
}

$actualConn = Get-NetTCPConnection -LocalPort 18881 -State Listen -ErrorAction SilentlyContinue
$actualPid = if ($actualConn) { $actualConn.OwningProcess } else { $proc.Id }
$actualPid | Set-Content -LiteralPath $pidFile -Force

Write-Host "catalogo-demo iniciado y verificado exitosamente (PID $actualPid) en http://localhost:18881"

