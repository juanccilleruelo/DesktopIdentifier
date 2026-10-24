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
    HostEnMarcha: Boolean;
  end;

function EstadoInstalacion: TEstadoInstalacion;
function DescripcionEstado(const E: TEstadoInstalacion): string;
function Instalar(const Ajustes: TSettings; out Mensaje: string): Boolean;
function Aplicar(const Ajustes: TSettings; out Mensaje: string): Boolean;
function Desinstalar(ConservarConfiguracion: Boolean; out Mensaje: string): Boolean;
function CerrarHost(EsperaMs: Cardinal): Boolean;

implementation

uses
  Winapi.Windows, Winapi.ShellAPI, System.SysUtils,
  uPaths, uUtils, uWallpaper, uStartup;

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
begin
  Result.HostInstalado := FileExists(RutaHostInstalado);
  Result.ConfiguracionPresente := FileExists(RutaIniInstalada);
  Result.InicioRegistrado := InicioRegistrado;
  Result.HostEnMarcha := HostEnEjecucion;
end;

function DescripcionEstado(const E: TEstadoInstalacion): string;
begin
  if not E.HostInstalado then
    Exit('Sin instalar');
  Result := 'Instalado';
  if E.InicioRegistrado then
    Result := Result + ' · arranque activo'
  else
    Result := Result + ' · arranque NO activo';
  if E.HostEnMarcha then
    Result := Result + ' · cartel en marcha'
  else
    Result := Result + ' · cartel detenido';
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
    Mensaje := 'No encuentro ' + NombreHost +
      ' junto al configurador. Compila el grupo completo.';
    Exit;
  end;

  if not ForceDirectories(Dir) then
  begin
    Mensaje := 'No se pudo crear la carpeta ' + Dir;
    Exit;
  end;

  if HostEnEjecucion then
    if not CerrarHost(5000) then
    begin
      Mensaje := 'El cartel sigue en marcha y no se puede actualizar. Cierralo e intentalo de nuevo.';
      Exit;
    end;

  if not CopyFile(PChar(Fuente), PChar(RutaHostInstalado), False) then
  begin
    Err := GetLastError;
    Mensaje := 'No se pudo copiar el programa de inicio: ' + SysErrorMessage(Err);
    Exit;
  end;

  if not GuardarAjustes(Ini, Ajustes) then
  begin
    Mensaje := 'No se pudo escribir ' + Ini;
    Exit;
  end;

  RegistrarInicio(RutaHostInstalado);
  if not InicioRegistrado then
  begin
    Mensaje := 'Copiado, pero no se pudo registrar el arranque automatico.';
    Exit;
  end;

  if not HostEnEjecucion then
  begin
    LanzarHost;
    EsperarArranqueHost(3000);
  end;

  Mensaje := 'Instalado en ' + Dir + ' y arranque activo.';
  Result := True;
end;

function Aplicar(const Ajustes: TSettings; out Mensaje: string): Boolean;
var
  Dir, Fondo: string;
begin
  Result := False;

  if not FileExists(RutaHostInstalado) then
  begin
    Mensaje := 'El programa de inicio no esta instalado. Pulsa Instalar.';
    Exit;
  end;

  Dir := DirectorioInstalacion;
  if not GuardarAjustes(RutaIniInstalada, Ajustes) then
  begin
    Mensaje := 'No se pudo guardar la configuracion en ' + RutaIniInstalada;
    Exit;
  end;

  if Ajustes.BandaActiva then
  begin
    if not PrepararOriginal(Dir) then
    begin
      Mensaje := 'No se pudo guardar una copia del fondo original.';
      Exit;
    end;
    Fondo := GenerarFondo(Dir, Ajustes);
    if not FileExists(Fondo) then
    begin
      Mensaje := 'No se pudo generar la imagen de la banda.';
      Exit;
    end;
    if not AplicarFondo(Fondo) then
    begin
      Mensaje := 'No se pudo aplicar el fondo de pantalla.';
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

  Mensaje := 'Aplicado a las ' + TimeToStr(Now) + '.';
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
    Mensaje := 'Desinstalado. Se conserva la configuracion en ' + Dir;
  end
  else
  begin
    DeleteFile(Dir + NombreIni);
    DeleteFile(Dir + NombreHost);
    if DirectoryExists(Dir) and not RemoveDir(Dir) then
      Mensaje := 'Desinstalado, pero la carpeta no se pudo borrar (puede estar en uso).'
    else
      Mensaje := 'Desinstalado por completo. Fondo original restaurado.';
  end;

  Result := True;
end;

end.
