$ErrorActionPreference = "Stop"
$scriptDir = $PSScriptRoot
Set-Location -Path $scriptDir

$jarPath = [System.IO.Path]::GetFullPath((Join-Path $scriptDir "target\config-server-demo-0.0.1-SNAPSHOT.jar"))
$logOut = [System.IO.Path]::GetFullPath((Join-Path $scriptDir "config-server.log"))
$logErr = [System.IO.Path]::GetFullPath((Join-Path $scriptDir "config-server-err.log"))
$pidFile = [System.IO.Path]::GetFullPath((Join-Path $scriptDir ".config-server.pid"))
$mvnwCmd = [System.IO.Path]::GetFullPath((Join-Path $scriptDir "mvnw.cmd"))

# 1. Resolucion dinamica de Java (JAVA_HOME o PATH) y verificacion de compatibilidad (>= 21)
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
    throw "No se encontro un entorno de ejecucion Java en el sistema. Configure JAVA_HOME o agregue java al PATH (se requiere JDK 21 o superior)."
}

$rawVer = cmd.exe /c "`"$javaExe`" -version 2>&1"
$rawString = $rawVer -join "`n"
$majorVer = $null
if ($rawString -match 'version\s+"(\d+)') {
    $majorVer = [int]$Matches[1]
}

if (-not $majorVer -or $majorVer -lt 21) {
    $detected = if ($majorVer) { "$majorVer" } else { "desconocida" }
    throw "La version de Java detectada ($detected) no es compatible. Spring Boot 4.1.2 requiere Java 21 o superior."
}

# 2. Comprobar si el puerto 18888 esta ocupado
$existingConn = Get-NetTCPConnection -LocalPort 18888 -State Listen -ErrorAction SilentlyContinue
if ($existingConn) {
    $procCim = Get-CimInstance Win32_Process | Where-Object { $_.ProcessId -eq $existingConn.OwningProcess }
    if ($procCim -and $procCim.CommandLine -and ($procCim.CommandLine -like "*$jarPath*")) {
        Write-Host "El Config Server ya esta activo en el puerto 18888 (PID $($existingConn.OwningProcess))."
        return
    } else {
        throw "El puerto 18888 esta ocupado por otro proceso (PID $($existingConn.OwningProcess)). No se detendran procesos ajenos."
    }
}

# 3. Compilar si el JAR no existe
if (-not (Test-Path -LiteralPath $jarPath)) {
    Write-Host "El artefacto JAR no existe. Compilando con Maven Wrapper..."
    & $mvnwCmd -DskipTests package
    if ($LASTEXITCODE -ne 0) {
        throw "Fallo en la compilacion de config-server-demo (codigo de salida $LASTEXITCODE)."
    }
    if (-not (Test-Path -LiteralPath $jarPath)) {
        throw "La compilacion finalizo pero no se genero el artefacto $jarPath."
    }
}

# 4. Iniciar el proceso con ventana oculta y rutas absolutas
Write-Host "Iniciando config-server-demo en segundo plano..."
$proc = Start-Process -FilePath $javaExe -ArgumentList "-jar", "`"$jarPath`"" -WorkingDirectory $scriptDir -WindowStyle Hidden -PassThru -RedirectStandardOutput $logOut -RedirectStandardError $logErr

# Guardar PID inicial como fallback
$proc.Id | Set-Content -LiteralPath $pidFile -Force

# 5. Esperar con plazo limitado comprobando respuesta HTTP
$maxWaitSeconds = 45
$elapsed = 0
$startedSuccessfully = $false

Write-Host "Esperando que config-server-demo responda en http://localhost:18888/actuator/health (maximo $maxWaitSeconds s)..."
while ($elapsed -lt $maxWaitSeconds) {
    Start-Sleep -Seconds 2
    $elapsed += 2

    try {
        $response = Invoke-WebRequest -Uri "http://localhost:18888/actuator/health" -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            $startedSuccessfully = $true
            break
        }
    } catch {
        # Servidor aun iniciando o clonando repositorio
    }
}

if (-not $startedSuccessfully) {
    throw "Tiempo de espera agotado ($maxWaitSeconds s) sin respuesta HTTP 200 en http://localhost:18888/actuator/health. Revise $logErr o $logOut."
}

# 6. Capturar y registrar el PID del proceso en escucha en el puerto 18888
$actualConn = Get-NetTCPConnection -LocalPort 18888 -State Listen -ErrorAction SilentlyContinue
$actualPid = if ($actualConn) { $actualConn.OwningProcess } else { $proc.Id }
$actualPid | Set-Content -LiteralPath $pidFile -Force

Write-Host "Config Server iniciado y verificado exitosamente (PID $actualPid) en http://localhost:18888"
