@echo off
echo ============================================================
echo   Krishnasamy Institution - REVERSE SYNC (CLEAR FIRST)
echo   Supabase  -^>  Local PostgreSQL
echo   WARNING: This will CLEAR all data in Local DB first!
echo ============================================================
echo.

cd /d "%~dp0"

set /p confirm="Are you sure you want to clear Local DB and sync? (Y/N): "
if /i not "%confirm%"=="Y" (
    echo Cancelled.
    pause
    exit /b
)

echo.
echo Starting reverse sync with clear...
echo.

node Reverse_sync.js --clear

echo.
echo ============================================================
echo   Reverse Sync (Clear) Process Completed
echo ============================================================
pause
