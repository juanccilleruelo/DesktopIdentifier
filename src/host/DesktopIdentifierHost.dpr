program DesktopIdentifierHost;

{ Programa de inicio: solo el cartel flotante. Sin VCL, sin ventana principal.

  Modos: sin parametros = cartel. Una segunda instancia pide RELOAD al cartel
  que ya esta en marcha y sale. El configurador lo controla con los mensajes
  registrados DesktopIdentifier_RELOAD y DesktopIdentifier_QUIT. }

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils,
  uPaths, uUtils, uHostWindow;

{$APPTYPE GUI}
{$R 'HostResources.res'}

var
  Mutex: THandle;
  Msg: TMsg;
  YaHabia: Boolean;

begin
  Mutex := CreateMutex(nil, False, PChar(MutexHost));
  YaHabia := (Mutex <> 0) and (GetLastError = ERROR_ALREADY_EXISTS);
  if YaHabia then
  begin
    AvisarHost(MensajeRecarga);
    CloseHandle(Mutex);
    Exit;
  end;

  ConfigurarDpi;

  if not IniciarHost then
  begin
    if Mutex <> 0 then
      CloseHandle(Mutex);
    Halt(1);
  end;

  while GetMessage(Msg, 0, 0, 0) do
  begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;

  if Mutex <> 0 then
    CloseHandle(Mutex);
end.
