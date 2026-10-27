@echo off
setlocal
set "ROOT=%~dp0"
set "ISCC=%LOCALAPPDATA%\Programs\Inno Setup 6\ISCC.exe"
if not exist "%ISCC%" set "ISCC=%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"
if not exist "%ISCC%" set "ISCC=%ProgramFiles%\Inno Setup 6\ISCC.exe"
if not exist "%ISCC%" (
  echo No se encuentra Inno Setup 6. Instalalo o ajusta ISCC en este script.
  exit /b 1
)

call "%ROOT%Compilar.cmd" --no-pause
if errorlevel 1 exit /b 1

"%ISCC%" "%ROOT%installer\DesktopIdentifier.iss"
if errorlevel 1 exit /b 1

echo.
echo Instalador generado en "%ROOT%dist\DesktopIdentifier-Setup.exe"
endlocal
