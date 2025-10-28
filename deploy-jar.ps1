# Spring Boot JAR Deployment Script for Windows PowerShell

# Exit immediately if a command exits with a non-zero status
$ErrorActionPreference = "Stop"

# Define variables
$JAR_NAME = "testproject-0.0.1-SNAPSHOT.jar"
$APP_PORT = "8085"
$HOST_PORT = "8082"
$DB_HOST = "team_1_dev_1_postgres"
$DB_USER = "team_1_user"
$DB_PASS = "team_1_pass"
$DB_NAME = "team_1_db"
$DB_URL = "jdbc:postgresql://${DB_HOST}:5432/${DB_NAME}"

Write-Host "=== Spring Boot JAR Deployment Script ===" -ForegroundColor Green

# --- Build JAR ---
Write-Host "--- Building JAR file ---" -ForegroundColor Yellow
mvn clean package -DskipTests

# --- Stop Previous App ---
Write-Host "--- Stopping previous application (if running) ---" -ForegroundColor Yellow
# Find and stop only our specific Spring Boot application
Get-Process -Name "java" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*target/${JAR_NAME}*" -or $_.CommandLine -like "*testproject*jar*" } | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3

# --- Deploy JAR ---
Write-Host "--- Starting Spring Boot application ---" -ForegroundColor Yellow
$javaArgs = @(
    "-jar", "target/${JAR_NAME}",
    "--server.port=${APP_PORT}",
    "--spring.profiles.active=dev",
    "--spring.datasource.url=${DB_URL}",
    "--spring.datasource.username=${DB_USER}",
    "--spring.datasource.password=${DB_PASS}"
)

Start-Process -FilePath "java" -ArgumentList $javaArgs -RedirectStandardOutput "app.log" -RedirectStandardError "app-error.log" -WindowStyle Hidden

Write-Host "--- Application started in background ---" -ForegroundColor Green

# --- Wait for startup ---
Write-Host "--- Waiting for application to start (20 seconds) ---" -ForegroundColor Yellow
Start-Sleep -Seconds 20

# --- Verify Deployment ---
Write-Host "--- Verifying application status ---" -ForegroundColor Yellow
$javaProcess = Get-Process -Name "java" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*target/${JAR_NAME}*" -or $_.CommandLine -like "*testproject*jar*" }

if ($javaProcess) {
    Write-Host "✅ Application is running" -ForegroundColor Green
    Write-Host "📊 Process details:" -ForegroundColor Cyan
    Write-Host "PID: $($javaProcess.Id), Memory: $([math]::Round($javaProcess.WorkingSet64/1MB, 2)) MB"
} else {
    Write-Host "❌ Application is not running!" -ForegroundColor Red
    Write-Host "📋 Last 50 lines of log:" -ForegroundColor Yellow
    if (Test-Path "app.log") {
        Get-Content "app.log" -Tail 50
    }
    if (Test-Path "app-error.log") {
        Write-Host "Error log:" -ForegroundColor Red
        Get-Content "app-error.log" -Tail 20
    }
    exit 1
}

# --- Health Check ---
Write-Host "--- Performing health check ---" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "http://localhost:${APP_PORT}/api/test/health" -Method GET -TimeoutSec 10
    Write-Host "✅ Health check passed!" -ForegroundColor Green
    Write-Host "Response: $response" -ForegroundColor Cyan
} catch {
    Write-Host "⚠️ Health check failed!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "📋 Last 50 lines of log:" -ForegroundColor Yellow
    if (Test-Path "app.log") {
        Get-Content "app.log" -Tail 50
    }
    exit 1
}

Write-Host "--- Deployment complete! Application is running on http://localhost:${APP_PORT} ---" -ForegroundColor Green
Write-Host "📋 Check logs with: Get-Content app.log -Wait" -ForegroundColor Cyan
Write-Host "🛑 Stop application with: Get-Process java | Where-Object { `$_.CommandLine -like '*${JAR_NAME}*' } | Stop-Process" -ForegroundColor Cyan
