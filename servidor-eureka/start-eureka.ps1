$ErrorActionPreference = "Stop"
$scriptDir = $PSScriptRoot
Set-Location -Path $scriptDir

$jarPath = [System.IO.Path]::GetFullPath((Join-Path $scriptDir "target\servidor-eureka-0.0.1-SNAPSHOT.jar"))
$logOut = [System.IO.Path]::GetFullPath((Join-Path $scriptDir "eureka.log"))
$logErr = [System.IO.Path]::GetFullPath((Join-Path $scriptDir "eureka-err.log"))
$pidFile = [System.IO.Path]::GetFullPath((Join-Path $scriptDir ".eureka.pid"))
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

# 2. Comprobar si el puerto 18760 está ocupado
$existingConn = Get-NetTCPConnection -LocalPort 18760 -State Listen -ErrorAction SilentlyContinue
if ($existingConn) {
    # Comprobar si pertenece a este proyecto
    $procCim = Get-CimInstance Win32_Process | Where-Object { $_.ProcessId -eq $existingConn.OwningProcess }
    if ($procCim -and $procCim.CommandLine -and ($procCim.CommandLine -like "*$jarPath*")) {
        Write-Host "El servidor Eureka de este proyecto ya está activo en el puerto 18760 (PID $($existingConn.OwningProcess))."
        return
    } else {
        throw "El puerto 18760 está ocupado por otro proceso (PID $($existingConn.OwningProcess)) que no corresponde a este proyecto. No se puede iniciar."
    }
}

# 3. Compilar si el JAR no existe
if (-not (Test-Path -LiteralPath $jarPath)) {
    Write-Host "El artefacto JAR no existe. Compilando con Maven Wrapper..."
    & $mvnwCmd -DskipTests package
    if ($LASTEXITCODE -ne 0) {
        throw "Fallo en la compilación de servidor-eureka (código de salida $LASTEXITCODE)."
    }
    if (-not (Test-Path -LiteralPath $jarPath)) {
        throw "La compilación finalizó pero no se generó el artefacto $jarPath."
    }
}

# 4. Iniciar el proceso con ventana oculta y rutas absolutas
Write-Host "Iniciando servidor-eureka en segundo plano..."
$proc = Start-Process -FilePath $javaExe -ArgumentList "-jar", "`"$jarPath`"" -WorkingDirectory $scriptDir -WindowStyle Hidden -PassThru -RedirectStandardOutput $logOut -RedirectStandardError $logErr

# Guardar PID inicial como fallback
$proc.Id | Set-Content -LiteralPath $pidFile -Force

# 4. Esperar con plazo limitado comprobando que el proceso sigue activo y el dashboard responde HTTP 200
$maxWaitSeconds = 45
$elapsed = 0
$startedSuccessfully = $false

Write-Host "Esperando que el servidor Eureka responda en http://localhost:18760 (máximo $maxWaitSeconds s)..."
while ($elapsed -lt $maxWaitSeconds) {
    Start-Sleep -Seconds 2
    $elapsed += 2

    # Probar si el dashboard responde HTTP 200
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:18760" -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            $startedSuccessfully = $true
            break
        }
    } catch {
        # Contexto o servidor todavía iniciando
    }
}

if (-not $startedSuccessfully) {
    throw "Tiempo de espera agotado ($maxWaitSeconds s) sin respuesta HTTP 200 en http://localhost:18760. Revise $logErr o $logOut."
}

# 5. Capturar y registrar el PID del proceso en escucha en el puerto 18760
$actualConn = Get-NetTCPConnection -LocalPort 18760 -State Listen -ErrorAction SilentlyContinue
$actualPid = if ($actualConn) { $actualConn.OwningProcess } else { $proc.Id }
$actualPid | Set-Content -LiteralPath $pidFile -Force

Write-Host "Servidor Eureka iniciado y verificado exitosamente (PID $actualPid) en http://localhost:18760"
