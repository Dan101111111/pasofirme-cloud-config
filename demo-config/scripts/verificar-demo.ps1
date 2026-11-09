# ==============================================================================
# Script de verificacion de solo lectura para PasoFirme Config Demo
# ==============================================================================
[CmdletBinding()]
param()

$ErrorActionPreference = "Continue"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "   PASOFIRME: VERIFICACION DE ESTADO SPRING CLOUD CONFIG DEMO   " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ""

$failed = $false

# 1. Comprobar Config Server (18888)
Write-Host "[1/4] Verificando Config Server en http://localhost:18888..." -ForegroundColor Yellow
try {
    $serverHealth = Invoke-RestMethod -Uri "http://localhost:18888/actuator/health" -TimeoutSec 5 -ErrorAction Stop
    $serverEnv = Invoke-RestMethod -Uri "http://localhost:18888/catalogo-demo/dev/main" -TimeoutSec 5 -ErrorAction Stop
    
    if ($serverHealth.status -eq "UP") {
        Write-Host "  -> Estado: OK (Health: UP)" -ForegroundColor Green
        Write-Host "  -> Git Version: $($serverEnv.version)" -ForegroundColor Green
        Write-Host "  -> PropertySources: $($serverEnv.propertySources.Count) fuentes localizadas" -ForegroundColor Green
    } else {
        Write-Host "  -> Estado: ALERTA (Health: $($serverHealth.status))" -ForegroundColor Red
        $failed = $true
    }
} catch {
    Write-Host "  -> ERROR: No fue posible conectar con Config Server (puerto 18888). $($_.Exception.Message)" -ForegroundColor Red
    $failed = $true
}

# 2. Comprobar Catalogo Demo (18881)
Write-Host "`n[2/4] Verificando Catalogo Demo en http://localhost:18881..." -ForegroundColor Yellow
try {
    $cat = Invoke-RestMethod -Uri "http://localhost:18881/api/demo" -TimeoutSec 5 -ErrorAction Stop
    Write-Host "  -> Servicio: $($cat.servicio)" -ForegroundColor Green
    Write-Host "  -> Perfil: $($cat.perfil)" -ForegroundColor Green
    Write-Host "  -> Tienda: $($cat.tienda)" -ForegroundColor Green
    Write-Host "  -> Mensaje: $($cat.mensaje)" -ForegroundColor Green
    Write-Host "  -> InstanciaArranque: $($cat.instanciaArranque)" -ForegroundColor Green
} catch {
    Write-Host "  -> ERROR: No fue posible conectar con catalogo-demo (puerto 18881). $($_.Exception.Message)" -ForegroundColor Red
    $failed = $true
}

# 3. Comprobar Ofertas Demo (18882)
Write-Host "`n[3/4] Verificando Ofertas Demo en http://localhost:18882..." -ForegroundColor Yellow
try {
    $ofe = Invoke-RestMethod -Uri "http://localhost:18882/api/demo" -TimeoutSec 5 -ErrorAction Stop
    Write-Host "  -> Servicio: $($ofe.servicio)" -ForegroundColor Green
    Write-Host "  -> Perfil: $($ofe.perfil)" -ForegroundColor Green
    Write-Host "  -> Tienda: $($ofe.tienda)" -ForegroundColor Green
    Write-Host "  -> Mensaje: $($ofe.mensaje)" -ForegroundColor Green
    Write-Host "  -> InstanciaArranque: $($ofe.instanciaArranque)" -ForegroundColor Green
} catch {
    Write-Host "  -> ERROR: No fue posible conectar con ofertas-demo (puerto 18882). $($_.Exception.Message)" -ForegroundColor Red
    $failed = $true
}

# 4. Comprobar Envios Demo (18883)
Write-Host "`n[4/4] Verificando Envios Demo en http://localhost:18883..." -ForegroundColor Yellow
try {
    $env = Invoke-RestMethod -Uri "http://localhost:18883/api/demo" -TimeoutSec 5 -ErrorAction Stop
    Write-Host "  -> Servicio: $($env.servicio)" -ForegroundColor Green
    Write-Host "  -> Perfil: $($env.perfil)" -ForegroundColor Green
    Write-Host "  -> Tienda: $($env.tienda)" -ForegroundColor Green
    Write-Host "  -> Mensaje: $($env.mensaje)" -ForegroundColor Green
    Write-Host "  -> InstanciaArranque: $($env.instanciaArranque)" -ForegroundColor Green
} catch {
    Write-Host "  -> ERROR: No fue posible conectar con envios-demo (puerto 18883). $($_.Exception.Message)" -ForegroundColor Red
    $failed = $true
}

Write-Host "`n=================================================================" -ForegroundColor Cyan
if ($failed) {
    Write-Host "   RESULTADO FINAL: AL MENOS UN MICROSERVICIO PRESENTO FALLOS    " -ForegroundColor Red
    Write-Host "=================================================================" -ForegroundColor Cyan
    exit 1
} else {
    Write-Host "   RESULTADO FINAL: TODOS LOS MICROSERVICIOS OPERAN CON EXITO   " -ForegroundColor Green
    Write-Host "=================================================================" -ForegroundColor Cyan
    exit 0
}

