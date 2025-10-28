# Post-build PowerShell script to start Spring Boot application
# This script runs after Jenkins pipeline completion to ensure the app keeps running

# Define variables
$JAR_NAME = "testproject-0.0.1-SNAPSHOT.jar"
$APP_PORT = "8085"
$DB_HOST = "team_1_dev_1_postgres"
$DB_USER = "team_1_user"
$DB_PASS = "team_1_pass"
$DB_NAME = "team_1_db"
$DB_URL = "jdbc:postgresql://${DB_HOST}:5432/${DB_NAME}"

# Get the workspace directory (Jenkins sets this)
$WORKSPACE_DIR = if ($env:WORKSPACE) { $env:WORKSPACE } else { Get-Location }

Write-Host "=== Post-Build Spring Boot Application Starter ===" -ForegroundColor Green
Write-Host "Workspace: $WORKSPACE_DIR" -ForegroundColor Cyan
Write-Host "JAR: $JAR_NAME" -ForegroundColor Cyan
Write-Host "Port: $APP_PORT" -ForegroundColor Cyan

# Navigate to workspace
Set-Location $WORKSPACE_DIR

# Check if JAR exists
if (-not (Test-Path "target/${JAR_NAME}")) {
    Write-Host "❌ JAR file not found: target/${JAR_NAME}" -ForegroundColor Red
    Write-Host "Available files in target/:" -ForegroundColor Yellow
    Get-ChildItem "target/" -ErrorAction SilentlyContinue | Format-Table
    exit 1
}

# Stop any existing application
Write-Host "🛑 Stopping any existing application..." -ForegroundColor Yellow
Get-Process -Name "java" -ErrorAction SilentlyContinue | Where-Object { 
    $_.CommandLine -like "*target/${JAR_NAME}*" -or $_.CommandLine -like "*testproject*jar*" 
} | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3

# Start the application
Write-Host "🚀 Starting Spring Boot application..." -ForegroundColor Yellow
$javaArgs = @(
    "-jar", "target/${JAR_NAME}",
    "--server.port=${APP_PORT}",
    "--spring.profiles.active=dev",
    "--spring.datasource.url=${DB_URL}",
    "--spring.datasource.username=${DB_USER}",
    "--spring.datasource.password=${DB_PASS}"
)

# Start process in background
$process = Start-Process -FilePath "java" -ArgumentList $javaArgs -RedirectStandardOutput "app.log" -RedirectStandardError "app-error.log" -WindowStyle Hidden -PassThru

Write-Host "✅ Application started successfully!" -ForegroundColor Green
Write-Host "📋 Process ID: $($process.Id)" -ForegroundColor Cyan
Write-Host "🌐 Application URL: http://localhost:${APP_PORT}" -ForegroundColor Cyan
Write-Host "📝 Log file: $WORKSPACE_DIR/app.log" -ForegroundColor Cyan
Write-Host "🔍 Check status with: Get-Process -Id $($process.Id)" -ForegroundColor Cyan

# Wait a moment and verify it's running
Start-Sleep -Seconds 5

if (-not $process.HasExited) {
    Write-Host "✅ Application is running (PID: $($process.Id))" -ForegroundColor Green
    
    # Try to do a health check
    Write-Host "🔍 Performing health check..." -ForegroundColor Yellow
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:${APP_PORT}/api/test/health" -Method GET -TimeoutSec 10
        Write-Host "✅ Health check passed!" -ForegroundColor Green
        Write-Host "Response: $response" -ForegroundColor Cyan
    } catch {
        Write-Host "⚠️ Health check failed, but application is running" -ForegroundColor Yellow
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Application failed to start" -ForegroundColor Red
    Write-Host "📋 Last 20 lines of log:" -ForegroundColor Yellow
    if (Test-Path "app.log") {
        Get-Content "app.log" -Tail 20
    }
    if (Test-Path "app-error.log") {
        Write-Host "Error log:" -ForegroundColor Red
        Get-Content "app-error.log" -Tail 10
    }
    exit 1
}

Write-Host "🎉 Post-build deployment complete!" -ForegroundColor Green
