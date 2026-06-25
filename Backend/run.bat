@echo off
setlocal
cd /d "%~dp0"

echo Verificando servicio MySQL80...
sc query MySQL80 | find "RUNNING" >nul
if errorlevel 1 (
    echo MySQL80 esta detenido. Pidiendo permisos de administrador para iniciarlo...
    powershell -NoProfile -Command "Start-Process powershell -Verb runAs -ArgumentList '-NoProfile -Command Start-Service -Name MySQL80' -Wait"
) else (
    echo MySQL80 ya esta corriendo.
)

echo.
echo Levantando backend FastAPI en http://localhost:8000 (accesible tambien desde la red local) ...
.venv\Scripts\python.exe -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
