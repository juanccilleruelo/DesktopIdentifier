@echo off
cd /d "%~dp0"

if not exist "bin\DesktopIdentifier.exe" (
    echo No esta compilado. Ejecuta antes Compilar.cmd o compila el grupo con Delphi.
    pause
    exit /b 1
)

start "" "bin\DesktopIdentifier.exe" %*
