
$ErrorActionPreference = "Stop"

Write-Host "`n=== Developify Backend Diagnostic ===" -ForegroundColor Cyan

if (-not (Test-Path ".env")) {
    Write-Host "ERROR: .env file not found." -ForegroundColor Red
    exit 1
}

Write-Host "`nChecking Prisma schema..."
& npx.cmd prisma validate

if ($LASTEXITCODE -ne 0) {
    Write-Host "Prisma schema validation failed." -ForegroundColor Red
    exit 1
}

Write-Host "`nChecking database connection..."
& npx.cmd prisma migrate status

if ($LASTEXITCODE -ne 0) {
    Write-Host "`nDatabase connection failed." -ForegroundColor Yellow
    Write-Host "If error P1000 appears, the PostgreSQL credentials need fixing."
    Write-Host "Editing .env alone does not change the PostgreSQL user's password."
    exit 1
}

Write-Host "`nDatabase connection check completed." -ForegroundColor Green
Write-Host "Review the migration status above before starting the backend."
