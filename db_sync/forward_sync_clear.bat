@echo off
echo ============================================================
echo   Krishnasamy Institution - FORWARD SYNC (CLEAR FIRST)
echo   Local PostgreSQL  -^>  Supabase
echo   WARNING: This will CLEAR all data in Supabase first!
echo ============================================================
echo.

cd /d "%~dp0"

set /p confirm="Are you sure you want to clear Supabase and sync? (Y/N): "
if /i not "%confirm%"=="Y" (
    echo Cancelled.
    pause
    exit /b
)

echo.
echo Starting forward sync with clear...
echo.

node Full_sync.js --clear

echo.
echo ============================================================
echo   Forward Sync (Clear) Process Completed
echo ============================================================
pause
