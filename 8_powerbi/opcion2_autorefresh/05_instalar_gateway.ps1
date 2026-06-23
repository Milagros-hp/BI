# ============================================================
# 05_instalar_gateway.ps1
# Instala y registra el On-premises Data Gateway de Power BI
# Ejecutar como Administrador en Windows
# ============================================================

#Requires -RunAsAdministrator

param(
    [string]$GatewayName    = "CECOMSAP-Gateway",
    [string]$RecoveryKey    = "CecomsapGW2026!",   # Cambia esto
    [string]$GatewayRegion  = "South America"
)

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " CECOMSAP · Instalacion Gateway Power BI   " -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# ── 1. Descargar Gateway ──────────────────────────────────────
$gatewayUrl  = "https://download.microsoft.com/download/D/A/1/DA1FDDB8-6DA8-4F0B-B047-1D7CF5A40BEF/GatewayInstall.exe"
$installerPath = "$env:TEMP\GatewayInstall.exe"

Write-Host "`n[1/4] Descargando On-premises Data Gateway ..."
if (-not (Test-Path $installerPath)) {
    Invoke-WebRequest -Uri $gatewayUrl -OutFile $installerPath -UseBasicParsing
    Write-Host "      Descargado en $installerPath" -ForegroundColor Green
} else {
    Write-Host "      Ya existe en $installerPath" -ForegroundColor Yellow
}

# ── 2. Instalar silenciosamente ───────────────────────────────
Write-Host "`n[2/4] Instalando Gateway (modo silencioso) ..."
Start-Process -FilePath $installerPath `
    -ArgumentList "/quiet AcceptEula=1" `
    -Wait -NoNewWindow
Write-Host "      Instalacion completada" -ForegroundColor Green

# ── 3. Verificar que PostgreSQL es accesible ──────────────────
Write-Host "`n[3/4] Verificando conectividad a PostgreSQL ..."
$pgHost = "localhost"
$pgPort = 5432
$tcpClient = New-Object System.Net.Sockets.TcpClient
try {
    $tcpClient.Connect($pgHost, $pgPort)
    Write-Host "      PostgreSQL $pgHost`:$pgPort accesible" -ForegroundColor Green
} catch {
    Write-Host "      ERROR: No se puede conectar a PostgreSQL $pgHost`:$pgPort" -ForegroundColor Red
    Write-Host "      Asegurate de que el contenedor Docker este corriendo:" -ForegroundColor Yellow
    Write-Host "        docker-compose up -d postgres" -ForegroundColor Yellow
} finally {
    $tcpClient.Close()
}

# ── 4. Instrucciones de registro manual ───────────────────────
Write-Host "`n[4/4] Pasos para registrar el Gateway en Power BI Service:"
Write-Host ""
Write-Host "  1. Abrir el Gateway configurator (ya instalado)"
Write-Host "     Inicio → 'On-premises data gateway'"
Write-Host ""
Write-Host "  2. Iniciar sesion con tu cuenta Power BI"
Write-Host ""
Write-Host "  3. Seleccionar 'Register a new gateway on this computer'"
Write-Host "     Nombre: $GatewayName"
Write-Host "     Recovery key: $RecoveryKey"
Write-Host ""
Write-Host "  4. En Power BI Service (app.powerbi.com):"
Write-Host "     Settings → Manage gateways → $GatewayName"
Write-Host "     → Add data source → PostgreSQL"
Write-Host ""
Write-Host "     Server:   localhost"
Write-Host "     Database: dw_cecomsap"
Write-Host "     Username: pbi_reader"
Write-Host "     Password: pbi_readonly_2026"
Write-Host ""
Write-Host "  5. En el Dataset publicado:"
Write-Host "     Settings → Gateway connection → $GatewayName"
Write-Host "     Scheduled refresh → ON → cada 30 minutos"
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host " Gateway listo para conectar con Power BI  " -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
