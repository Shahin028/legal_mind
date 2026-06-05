@echo off
echo ============================================
echo  LegalMind - Starting Backend Servers
echo ============================================
echo.

REM Start Auth Server (port 8000) in a new window
echo [1] Starting Auth Server on port 8000...
start "LegalMind Auth Server :8000" cmd /k "cd /d d:\parent\trying_flutter\legal_mind\backend && uvicorn auth_server:app --host 0.0.0.0 --port 8000 --reload"

REM Wait 2 seconds before starting second server
timeout /t 2 /nobreak > nul

REM Start Main API Server (port 9000) in a new window
echo [2] Starting Main API Server on port 9000...
start "LegalMind Main API :9000" cmd /k "cd /d d:\parent\trying_flutter\legal_mind\backend && uvicorn main:app --host 0.0.0.0 --port 9000 --reload"

echo.
echo Both servers are starting in separate windows.
echo  - Auth Server  : http://0.0.0.0:8000
echo  - Main API     : http://0.0.0.0:9000
echo.
echo Flutter app is configured for: http://172.16.16.197
echo.
pause
