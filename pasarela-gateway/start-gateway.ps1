param(
    [switch]$Rebuild
)

$ErrorActionPreference = "Stop"
$scriptDir = $PSScriptRoot
Set-Location -Path $scriptDir

$jarPath = [System.IO.Path]::GetFullPath((Join-Path $scriptDir "target\pasarela-gateway-0.0.1-SNAPSHOT.jar"))
$logOut = [System.IO.Path]::GetFullPath((Join-Path $scriptDir "gateway.log"))
$logErr = [System.IO.Path]::GetFullPath((Join-Path $scriptDir "gateway-err.log"))
$pidFile = [System.IO.Path]::GetFullPath((Join-Path $scriptDir ".gateway.pid"))
$mvnwCmd = [System.IO.Path]::GetFullPath((Join-Path $scriptDir "mvnw.cmd"))

# 1. Resolución dinámica de Java (JAVA_HOME o PATH) y verificación de compatibilidad (>= 21)
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
    throw "No se encontró un entorno de ejecución Java en el sistema. Configure la variable de entorno JAVA_HOME o agregue 'java' al PATH del sistema (se requiere JDK 21 o superior compatible)."
}

$rawVer = & $javaExe -version 2>&1 | Out-String
$majorVer = $null
if ($rawVer -match '(?:version\s+"(\d+)|openjdk\s+version\s+"(\d+)|java\s+version\s+"(\d+))') {
    $majorVer = [int]($Matches[1], $Matches[2], $Matches[3] | Where-Object { $_ } | Select-Object -First 1)
}

if (-not $majorVer -or $majorVer -lt 21) {
    $detected = if ($majorVer) { "$majorVer" } else { "desconocida" }
    throw "La versión de Java detectada ($detected) no es compatible con el proyecto. Spring Boot 4.1.2 y Spring Cloud 2025.1.4 requieren Java 21 o superior. Configure JAVA_HOME apuntando a un JDK 21+ compatible."
}

# 2. Comprobar si el puerto 18080 está ocupado
$existingConn = Get-NetTCPConnection -LocalPort 18080 -State Listen -ErrorAction SilentlyContinue
if ($existingConn) {
    $procCim = Get-CimInstance Win32_Process | Where-Object { $_.ProcessId -eq $existingConn.OwningProcess }
    if ($procCim -and $procCim.CommandLine -and ($procCim.CommandLine -like "*$jarPath*")) {
        Write-Host "La pasarela Gateway ya está activa en el puerto 18080 (PID $($existingConn.OwningProcess))."
        return
    } else {
        throw "El puerto 18080 está ocupado por otro proceso (PID $($existingConn.OwningProcess)) que no corresponde a este proyecto. No se puede iniciar."
    }
}

# 3. Compilar si el JAR no existe o se solicita Rebuild
if ($Rebuild -or (-not (Test-Path -LiteralPath $jarPath))) {
    Write-Host "Compilando pasarela-gateway con Maven Wrapper..."
    & $mvnwCmd -DskipTests package
    if ($LASTEXITCODE -ne 0) {
        throw "Fallo en la compilación de pasarela-gateway (código de salida $LASTEXITCODE)."
    }
    if (-not (Test-Path -LiteralPath $jarPath)) {
        throw "La compilación finalizó pero no se generó el artefacto $jarPath."
    }
}

# 4. Iniciar el proceso con ventana oculta y rutas absolutas
Write-Host "Iniciando pasarela-gateway en segundo plano con perfil local..."
$proc = Start-Process -FilePath $javaExe -ArgumentList "-jar", "`"$jarPath`"", "--spring.profiles.active=local" -WorkingDirectory $scriptDir -WindowStyle Hidden -PassThru -RedirectStandardOutput $logOut -RedirectStandardError $logErr

$proc.Id | Set-Content -LiteralPath $pidFile -Force

# 4. Esperar con plazo limitado comprobando que el puerto 18080 esté escuchando y responda
$maxWaitSeconds = 45
$elapsed = 0
$startedSuccessfully = $false

Write-Host "Esperando que pasarela-gateway responda en http://localhost:18080 (máximo $maxWaitSeconds s)..."
while ($elapsed -lt $maxWaitSeconds) {
    Start-Sleep -Seconds 2
    $elapsed += 2

    if ($proc.HasExited) {
        throw "El proceso de pasarela-gateway (PID $($proc.Id)) terminó inesperadamente con código $($proc.ExitCode). Revise $logErr o $logOut."
    }

    $socket = Get-NetTCPConnection -LocalPort 18080 -State Listen -ErrorAction SilentlyContinue
    if ($socket) {
        $startedSuccessfully = $true
        break
    }
}

if (-not $startedSuccessfully) {
    throw "Tiempo de espera agotado ($maxWaitSeconds s) sin socket en escucha en puerto 18080. Revise $logErr o $logOut."
}

# 5. Capturar y registrar el PID real del socket en escucha
$actualConn = Get-NetTCPConnection -LocalPort 18080 -State Listen -ErrorAction SilentlyContinue
$actualPid = if ($actualConn) { $actualConn.OwningProcess } else { $proc.Id }
$actualPid | Set-Content -LiteralPath $pidFile -Force

Write-Host "Pasarela Gateway iniciada y verificada exitosamente (PID $actualPid) en http://localhost:18080"
