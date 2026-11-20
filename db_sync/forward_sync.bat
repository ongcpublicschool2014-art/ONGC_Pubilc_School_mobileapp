@echo off
echo ============================================================
echo   Krishnasamy Institution - FORWARD SYNC
echo   Local PostgreSQL  -^>  Supabase
echo ============================================================
echo.

cd /d "%~dp0"

echo Starting forward sync...
echo.

node Full_sync.js %*

echo.
echo ============================================================
echo   Forward Sync Process Completed
echo ============================================================
pause
