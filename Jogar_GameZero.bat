@echo off
setlocal
title GameZero Beta - Launcher NVIDIA RTX
cd /d "%~dp0"

echo ==================================================
echo   GAMEZERO BETA - VULKAN FORWARD+ (NVIDIA GEFORCE)
echo ==================================================
echo.

if exist "%~dp0GameZero.exe" (
    echo [MODO NATIVO WINDOWS] Executando GameZero.exe na GPU GeForce...
    start "" "%~dp0GameZero.exe"
    exit /b 0
)

if exist "%~dp0..\GameZero.exe" (
    echo [MODO NATIVO WINDOWS] Executando GameZero.exe na GPU GeForce...
    start "" "%~dp0..\GameZero.exe"
    exit /b 0
)

echo [AVISO] GameZero.exe nao encontrado no diretorio local.
echo Tentando inicializar via subsistema WSL...
wsl bash -c "cd /home/eudespatricio/Games/GameZero && godot"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Falha ao abrir via WSL. Certifique-se de que GameZero.exe e GameZero.pck estao na mesma pasta.
    pause
)
