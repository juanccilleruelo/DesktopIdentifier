@echo off
setlocal
cd /d "%~dp0"

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
set "BIN=%ROOT%\bin"
set "DCU=%ROOT%\dcu"
set "COMMON=%ROOT%\src\common"

set "BDSDIR="
if defined BDS if exist "%BDS%\bin\dcc32.exe" set "BDSDIR=%BDS%"
if not defined BDSDIR if exist "%ProgramFiles(x86)%\Embarcadero\Studio\23.0\bin\dcc32.exe" set "BDSDIR=%ProgramFiles(x86)%\Embarcadero\Studio\23.0"

if not defined BDSDIR (
    where dcc32.exe >nul 2>&1
    if errorlevel 1 goto :notool
)

if defined BDSDIR (
    set "DCC=%BDSDIR%\bin\dcc32.exe"
    set "BRC=%BDSDIR%\bin\brcc32.exe"
) else (
    set "DCC=dcc32.exe"
    set "BRC=brcc32.exe"
)
if defined BDSDIR if not exist "%DCC%" goto :notool
if defined BDSDIR if not exist "%BRC%" goto :notool

if not exist "%BIN%" mkdir "%BIN%"
if not exist "%DCU%\host" mkdir "%DCU%\host"
if not exist "%DCU%\config" mkdir "%DCU%\config"

echo [1/4] Recursos del programa de inicio...
pushd "%ROOT%\src\host"
"%BRC%" -fo"HostResources.res" "HostResources.rc"
set "ERR=%ERRORLEVEL%"
popd
if not "%ERR%"=="0" goto :error

echo [2/4] DesktopIdentifierHost.exe (sin VCL)...
pushd "%ROOT%\src\host"
"%DCC%" -B -Q -$D- -$L- -$O+ -$R- "-E%BIN%" "-NU%DCU%\host" "-U%COMMON%" "-I%COMMON%" "DesktopIdentifierHost.dpr"
set "ERR=%ERRORLEVEL%"
popd
if not "%ERR%"=="0" goto :error

echo [3/4] Recursos del configurador...
pushd "%ROOT%\src\config"
"%BRC%" -fo"ConfigResources.res" "ConfigResources.rc"
set "ERR=%ERRORLEVEL%"
popd
if not "%ERR%"=="0" goto :error

echo [4/4] DesktopIdentifier.exe (VCL)...
pushd "%ROOT%\src\config"
"%DCC%" -B -Q -$D- -$L- -$O+ -$R- "-E%BIN%" "-NU%DCU%\config" "-U%COMMON%" "-I%COMMON%" "DesktopIdentifier.dpr"
set "ERR=%ERRORLEVEL%"
popd
if not "%ERR%"=="0" goto :error

echo.
echo Compilado en "%BIN%":
for %%F in ("%BIN%\DesktopIdentifierHost.exe" "%BIN%\DesktopIdentifier.exe") do (
    if exist "%%~F" echo   %%~nxF  %%~zF bytes
)
echo.
echo Ejecuta Configurar.cmd para abrir la configuracion.
if /i not "%~1"=="--no-pause" pause
exit /b 0

:notool
echo.
echo No encuentro dcc32.exe.
echo Abre la consola de RAD Studio ^(rsvars.bat^) o instala Delphi 12 en la ruta habitual.
goto :error

:error
echo.
echo ERROR de compilacion.
if /i not "%~1"=="--no-pause" pause
exit /b 1
