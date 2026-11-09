# scripts/set-local-env.ps1
# Carga segura de variables de entorno desde .env al proceso PowerShell actual.
# Uso: . .\scripts\set-local-env.ps1  (utilizando dot-sourcing)

$envFilePath = Join-Path $PSScriptRoot "..\.env"
if (-not (Test-Path -LiteralPath $envFilePath)) {
    Write-Warning "No se encontró el archivo .env en la raíz del proyecto ($envFilePath)."
    return
}

$parsedVars = @{}

Get-Content -LiteralPath $envFilePath | ForEach-Object {
    $line = $_.Trim()
    # Ignorar líneas vacías y comentarios
    if ($line -and -not ($line.StartsWith("#"))) {
        $equalIndex = $line.IndexOf("=")
        if ($equalIndex -gt 0) {
            $key = $line.Substring(0, $equalIndex).Trim()
            $value = $line.Substring($equalIndex + 1).Trim()
            
            # Remover comillas dobles o simples que envuelvan el valor
            if (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'"))) {
                $value = $value.Substring(1, $value.Length - 2)
            }
            
            $parsedVars[$key] = $value
        }
    }
}

# Mapeo a las variables de entorno utilizadas por Spring Boot (perfil local)
if ($parsedVars.ContainsKey("MYSQL_PORT")) {
    $env:DB_PORT = $parsedVars["MYSQL_PORT"]
} else {
    $env:DB_PORT = "3308"
}

if ($parsedVars.ContainsKey("MYSQL_USER")) {
    $env:DB_USERNAME = $parsedVars["MYSQL_USER"]
}

if ($parsedVars.ContainsKey("MYSQL_PASSWORD")) {
    $env:DB_PASSWORD = $parsedVars["MYSQL_PASSWORD"]
}

if ($parsedVars.ContainsKey("MYSQL_DATABASE")) {
    $env:DB_NAME = $parsedVars["MYSQL_DATABASE"]
}

Write-Host "[OK] Variables de entorno locales configuradas para el proceso PowerShell:" -ForegroundColor Green
Write-Host "     DB_PORT     = $env:DB_PORT"
Write-Host "     DB_USERNAME = $env:DB_USERNAME"
Write-Host "     DB_NAME     = $env:DB_NAME"
Write-Host "     DB_PASSWORD = [CONFIGURADA - OCULTA]"
