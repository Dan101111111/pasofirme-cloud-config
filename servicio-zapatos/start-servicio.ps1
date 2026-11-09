$ErrorActionPreference = "Stop"
$scriptDir = $PSScriptRoot
Set-Location -Path $scriptDir

$jarPath = [System.IO.Path]::GetFullPath((Join-Path $scriptDir "target\servicio-zapatos-0.0.1-SNAPSHOT.jar"))
$logOut = [System.IO.Path]::GetFullPath((Join-Path $scriptDir "servicio.log"))
$logErr = [System.IO.Path]::GetFullPath((Join-Path $scriptDir "servicio-err.log"))
$pidFile = [System.IO.Path]::GetFullPath((Join-Path $scriptDir ".servicio.pid"))
$mvnwCmd = [System.IO.Path]::GetFullPath((Join-Path $scriptDir "mvnw.cmd"))
$envScript = [System.IO.Path]::GetFullPath((Join-Path $scriptDir "..\scripts\set-local-env.ps1"))

# 1. Cargar variables de entorno si no están definidas
if (-not $env:DB_USERNAME -or -not $env:DB_PASSWORD) {
    if (Test-Path -LiteralPath $envScript) {
        Write-Host "Cargando variables de entorno desde set-local-env.ps1..."
        . $envScript
    } else {
        throw "No se encontraron las variables de entorno DB_USERNAME/DB_PASSWORD ni el script $envScript."
    }
}

# 2. Resolución dinámica de Java (JAVA_HOME o PATH) y verificación de compatibilidad (>= 21)
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

# 3. Comprobar si el puerto 18761 está ocupado
$existingConn = Get-NetTCPConnection -LocalPort 18761 -State Listen -ErrorAction SilentlyContinue
if ($existingConn) {
    $procCim = Get-CimInstance Win32_Process | Where-Object { $_.ProcessId -eq $existingConn.OwningProcess }
    if ($procCim -and $procCim.CommandLine -and ($procCim.CommandLine -like "*$jarPath*")) {
        Write-Host "El servicio de zapatos ya está activo en el puerto 18761 (PID $($existingConn.OwningProcess))."
        return
    } else {
        throw "El puerto 18761 está ocupado por otro proceso (PID $($existingConn.OwningProcess)) que no corresponde a este proyecto. No se puede iniciar."
    }
}

# 4. Compilar si el JAR no existe
if (-not (Test-Path -LiteralPath $jarPath)) {
    Write-Host "El artefacto JAR no existe. Compilando con Maven Wrapper..."
    & $mvnwCmd -DskipTests package
    if ($LASTEXITCODE -ne 0) {
        throw "Fallo en la compilación de servicio-zapatos (código de salida $LASTEXITCODE)."
    }
    if (-not (Test-Path -LiteralPath $jarPath)) {
        throw "La compilación finalizó pero no se generó el artefacto $jarPath."
    }
}

# 5. Iniciar el proceso con ventana oculta y rutas absolutas
Write-Host "Iniciando servicio-zapatos en segundo plano con perfil local..."
$proc = Start-Process -FilePath $javaExe -ArgumentList "-jar", "`"$jarPath`"", "--spring.profiles.active=local" -WorkingDirectory $scriptDir -WindowStyle Hidden -PassThru -RedirectStandardOutput $logOut -RedirectStandardError $logErr

$proc.Id | Set-Content -LiteralPath $pidFile -Force

# 5. Esperar con plazo limitado comprobando que el servicio responda en puerto 18761
$maxWaitSeconds = 50
$elapsed = 0
$startedSuccessfully = $false

Write-Host "Esperando que servicio-zapatos responda en http://localhost:18761/api/zapatos (máximo $maxWaitSeconds s)..."
while ($elapsed -lt $maxWaitSeconds) {
    Start-Sleep -Seconds 2
    $elapsed += 2

    if ($proc.HasExited) {
        throw "El proceso de servicio-zapatos (PID $($proc.Id)) terminó inesperadamente con código $($proc.ExitCode). Revise $logErr o $logOut."
    }

    try {
        $response = Invoke-WebRequest -Uri "http://localhost:18761/api/zapatos" -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            $startedSuccessfully = $true
            break
        }
    } catch {
        # Contexto Spring o conexión Hibernate aún inicializándose
    }
}

if (-not $startedSuccessfully) {
    throw "Tiempo de espera agotado ($maxWaitSeconds s) sin respuesta HTTP 200 en http://localhost:18761/api/zapatos. Revise $logErr o $logOut."
}

# 6. Capturar y registrar el PID real del socket en escucha
$actualConn = Get-NetTCPConnection -LocalPort 18761 -State Listen -ErrorAction SilentlyContinue
$actualPid = if ($actualConn) { $actualConn.OwningProcess } else { $proc.Id }
$actualPid | Set-Content -LiteralPath $pidFile -Force

Write-Host "Servicio Zapatos iniciado y verificado exitosamente (PID $actualPid) en http://localhost:18761/api/zapatos"
