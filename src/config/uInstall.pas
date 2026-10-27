unit uInstall;

{ Instalacion, aplicacion y desinstalacion del configurador.

  Instalar: copia el host a %LOCALAPPDATA%\DesktopIdentifier, escribe el INI,
  registra el arranque y lo pone en marcha. Solo este flujo copia y toca el
  registro.

  Aplicar: escribe el INI y el fondo, y recarga el host. No copia nada ni
  toca el registro. }

interface

uses
  uSettings;

type
  TEstadoInstalacion = record
    HostInstalado: Boolean;
    ConfiguracionPresente: Boolean;
    InicioRegistrado: Boolean;
    RunCorrecto: Boolean;
    HostEnMarcha: Boolean;
    CarpetaPresente: Boolean;
    RutaRun: string;
    VersionInstalada: string;
    VersionDisponible: string;
    ActualizacionDisponible: Boolean;
    RequiereReparacion: Boolean;
    Problema: string;
  end;

function EstadoInstalacion: TEstadoInstalacion;
function DescripcionEstado(const E: TEstadoInstalacion): string;
function Instalar(const Ajustes: TSettings; out Mensaje: string): Boolean;
function ActualizarHost(out Mensaje: string): Boolean;
function Aplicar(const Ajustes: TSettings; out Mensaje: string): Boolean;
function Desinstalar(ConservarConfiguracion: Boolean; out Mensaje: string): Boolean;
function CerrarHost(EsperaMs: Cardinal): Boolean;

implementation

uses
  Winapi.Windows, Winapi.ShellAPI, System.SysUtils,
  uPaths, uUtils, uWallpaper, uStartup, uVersion, Languages;

procedure LanzarHost;
begin
  if not FileExists(RutaHostInstalado) then
    Exit;
  ShellExecute(0, 'open', PChar(RutaHostInstalado), nil,
    PChar(DirectorioInstalacion), SW_SHOWNORMAL);
end;

procedure EsperarArranqueHost(Ms: Cardinal);
var
  T: Cardinal;
begin
  T := 0;
  while (T < Ms) and (not HostEnEjecucion) do
  begin
    Sleep(100);
    Inc(T, 100);
  end;
end;

function CerrarHost(EsperaMs: Cardinal): Boolean;
var
  H: HWND;
  Pid: DWORD;
  Proc: THandle;
  M: Cardinal;
  Restante: Cardinal;
begin
  H := VentanaHost;
  if H = 0 then
    Exit(True);

  Pid := 0;
  GetWindowThreadProcessId(H, @Pid);
  M := RegisterWindowMessage(PChar(MensajeSalir));
  if M <> 0 then
    PostMessage(H, M, 0, 0);

  if Pid <> 0 then
  begin
    Proc := OpenProcess(SYNCHRONIZE or PROCESS_TERMINATE, False, Pid);
    if Proc <> 0 then
    begin
      try
        if WaitForSingleObject(Proc, EsperaMs) = WAIT_TIMEOUT then
        begin
          TerminateProcess(Proc, 1);
          WaitForSingleObject(Proc, 2000);
        end;
      finally
        CloseHandle(Proc);
      end;
    end;
  end;

  Restante := 2000;
  while (VentanaHost <> 0) and (Restante > 0) do
  begin
    Sleep(50);
    if Restante >= 50 then
      Dec(Restante, 50)
    else
      Restante := 0;
  end;

  Result := VentanaHost = 0;
end;

function EstadoInstalacion: TEstadoInstalacion;
var
  Problemas: string;

  procedure Agregar(const S: string);
  begin
    if Problemas <> '' then
      Problemas := Problemas + ' ';
    Problemas := Problemas + S;
  end;

begin
  Result.CarpetaPresente := DirectoryExists(DirectorioInstalacion);
  Result.HostInstalado := FileExists(RutaHostInstalado);
  Result.ConfiguracionPresente := FileExists(RutaIniInstalada);
  Result.InicioRegistrado := InicioRegistrado;
  Result.RutaRun := RutaInicioRegistrada;
  Result.RunCorrecto := Result.InicioRegistrado and
    MismaRuta(Result.RutaRun, RutaHostInstalado);
  Result.HostEnMarcha := HostEnEjecucion;
  Result.VersionInstalada := VersionArchivo(RutaHostInstalado);
  Result.VersionDisponible := VersionArchivo(RutaHostFuente);
  Result.ActualizacionDisponible := Result.HostInstalado and
    (Result.VersionInstalada <> '') and (Result.VersionDisponible <> '') and
    (CompararVersiones(Result.VersionDisponible, Result.VersionInstalada) > 0);

  Problemas := '';
  if Result.HostInstalado then
  begin
    if not Result.InicioRegistrado then
      Agregar(Texto(txtMissingStartup))
    else if not Result.RunCorrecto then
      Agregar(Texto(txtStartupWrongPath));
    if not Result.ConfiguracionPresente then
      Agregar(Texto(txtMissingIni));
  end
  else
  begin
    if Result.InicioRegistrado then
      Agregar(Texto(txtStartupMissingExe))
    else if Result.CarpetaPresente then
      Agregar(Texto(txtLeftovers));
    if Result.HostEnMarcha then
      Agregar(Texto(txtBadgeRunningNotInstalled));
  end;
  Result.Problema := Problemas;
  Result.RequiereReparacion := Problemas <> '';
end;

function DescripcionEstado(const E: TEstadoInstalacion): string;
var
  V: string;
begin
  if E.RequiereReparacion then
  begin
    if E.HostInstalado then
      Result := Texto(txtRepairNeeded)
    else
      Result := Texto(txtLeftoversRepair);
    Exit;
  end;

  if not E.HostInstalado then
  begin
    Result := Texto(txtNotInstalled);
    Exit;
  end;

  V := E.VersionInstalada;
  if V = '' then
    V := '?';
  if E.ActualizacionDisponible then
  begin
    Result := TextoFmt(txtUpdateAvailable, [V, E.VersionDisponible]);
    Exit;
  end;
  Result := TextoFmt(txtInstalledHost, [V]);
  if E.InicioRegistrado then
    Result := Result + Texto(txtStartupActive)
  else
    Result := Result + Texto(txtStartupInactive);
  if E.HostEnMarcha then
    Result := Result + Texto(txtBadgeRunning)
  else
    Result := Result + Texto(txtBadgeStopped);
end;

function Instalar(const Ajustes: TSettings; out Mensaje: string): Boolean;
var
  Fuente, Dir, Ini: string;
  Err: DWORD;
begin
  Result := False;
  Fuente := RutaHostFuente;
  Ini := RutaIniInstalada;
  Dir := DirectorioInstalacion;

  if not FileExists(Fuente) then
  begin
    Mensaje := TextoFmt(txtHostNotFound, [NombreHost]);
    Exit;
  end;

  if not ForceDirectories(Dir) then
  begin
    Mensaje := TextoFmt(txtCreateDirFailed, [Dir]);
    Exit;
  end;

  if HostEnEjecucion then
    if not CerrarHost(5000) then
    begin
      Mensaje := Texto(txtHostStillRunning);
      Exit;
    end;

  if not CopyFile(PChar(Fuente), PChar(RutaHostInstalado), False) then
  begin
    Err := GetLastError;
    Mensaje := TextoFmt(txtCopyFailed, [SysErrorMessage(Err)]);
    Exit;
  end;

  if not GuardarAjustes(Ini, Ajustes) then
  begin
    Mensaje := TextoFmt(txtWriteIniFailed, [Ini]);
    Exit;
  end;

  RegistrarInicio(RutaHostInstalado);
  if not InicioRegistrado then
  begin
    Mensaje := Texto(txtStartupRegisterFailed);
    Exit;
  end;

  if not HostEnEjecucion then
  begin
    LanzarHost;
    EsperarArranqueHost(3000);
  end;

  Mensaje := TextoFmt(txtInstalledIn, [Dir]);
  Result := True;
end;

function ActualizarHost(out Mensaje: string): Boolean;
var
  Fuente, Instalado, VInst, VNueva: string;
  Err: DWORD;
begin
  Result := False;
  Fuente := RutaHostFuente;
  Instalado := RutaHostInstalado;

  if not FileExists(Fuente) then
  begin
    Mensaje := TextoFmt(txtHostNotFound, [NombreHost]);
    Exit;
  end;

  if not FileExists(Instalado) then
  begin
    Mensaje := Texto(txtNoInstallToUpdate);
    Exit;
  end;

  VInst := VersionArchivo(Instalado);
  VNueva := VersionArchivo(Fuente);
  if (VInst <> '') and (VNueva <> '') and
     (CompararVersiones(VNueva, VInst) <= 0) then
  begin
    Mensaje := TextoFmt(txtAlreadyVersion, [VInst]);
    Result := True;
    Exit;
  end;

  if HostEnEjecucion then
    if not CerrarHost(5000) then
    begin
      Mensaje := Texto(txtHostRunningNoUpdate);
      Exit;
    end;

  if not CopyFile(PChar(Fuente), PChar(Instalado), False) then
  begin
    Err := GetLastError;
    Mensaje := TextoFmt(txtCopyFailed, [SysErrorMessage(Err)]);
    Exit;
  end;

  if not HostEnEjecucion then
  begin
    LanzarHost;
    EsperarArranqueHost(3000);
  end;

  if VNueva <> '' then
    Mensaje := TextoFmt(txtUpdatedTo, [VNueva])
  else
    Mensaje := Texto(txtUpdated);
  Result := True;
end;

function Aplicar(const Ajustes: TSettings; out Mensaje: string): Boolean;
var
  Dir, Fondo: string;
begin
  Result := False;

  if not FileExists(RutaHostInstalado) then
  begin
    Mensaje := Texto(txtNotInstalledPressInstall);
    Exit;
  end;

  Dir := DirectorioInstalacion;
  if not GuardarAjustes(RutaIniInstalada, Ajustes) then
  begin
    Mensaje := TextoFmt(txtSaveConfigFailed, [RutaIniInstalada]);
    Exit;
  end;

  if Ajustes.BandaActiva or (Ajustes.DesktopFondo <> dfOriginal) or
     (Trim(Ajustes.DesktopTextoGrande) <> '') or
     (Trim(Ajustes.DesktopTextoPequeno) <> '') then
  begin
    if not PrepararOriginal(Dir) then
    begin
      Mensaje := Texto(txtSaveOriginalFailed);
      Exit;
    end;
    Fondo := GenerarFondo(Dir, Ajustes);
    if not FileExists(Fondo) then
    begin
      Mensaje := Texto(txtGenerateBandFailed);
      Exit;
    end;
    if not AplicarFondo(Fondo) then
    begin
      Mensaje := Texto(txtApplyWallpaperFailed);
      Exit;
    end;
  end
  else
    RestaurarFondo(Dir);

  if HostEnEjecucion then
    AvisarHost(MensajeRecarga)
  else
  begin
    LanzarHost;
    EsperarArranqueHost(3000);
  end;

  Mensaje := TextoFmt(txtApplied, [TimeToStr(Now)]);
  Result := True;
end;

function Desinstalar(ConservarConfiguracion: Boolean; out Mensaje: string): Boolean;
var
  Dir: string;
begin
  Dir := DirectorioInstalacion;

  CerrarHost(5000);
  DesregistrarInicio;
  RestaurarFondo(Dir);

  DeleteFile(Dir + ArchivoFondo);
  DeleteFile(Dir + ArchivoFondoOriginal);
  DeleteFile(Dir + ArchivoMarcador);
  DeleteFile(Dir + NombreIni + '.tmp');

  if ConservarConfiguracion then
  begin
    DeleteFile(Dir + NombreHost);
    Mensaje := TextoFmt(txtUninstalledKeep, [Dir]);
  end
  else
  begin
    DeleteFile(Dir + NombreIni);
    DeleteFile(Dir + NombreHost);
    if DirectoryExists(Dir) and not RemoveDir(Dir) then
      Mensaje := Texto(txtUninstallFolderFailed)
    else
      Mensaje := Texto(txtUninstalledAll);
  end;

  Result := True;
end;

end.
