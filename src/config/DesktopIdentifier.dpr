program DesktopIdentifier;

{ Configurador: ventana de configuracion, generacion de la banda,
  instalacion y desinstalacion del programa de inicio.

  Sin parametros abre la configuracion. Tambien acepta:
    /install            instala (si hace falta) y aplica
    /apply              aplica la configuracion ya instalada
    /uninstall [/discard]  desinstala (conserva el INI salvo /discard)
    /quit               cierra el cartel }

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils,
  Vcl.Forms,
  uPaths, uSettings, uUtils, uInstall, uConfigForm;

{$APPTYPE GUI}
{$R 'ConfigResources.res'}

var
  Param1, Param2: string;
  Form: TConfigForm;
  Ajustes: TSettings;
  Mensaje: string;

begin
  ConfigurarDpi;

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'DesktopIdentifier';

  Param1 := '';
  Param2 := '';
  if ParamCount > 0 then
    Param1 := ParamStr(1);
  if ParamCount > 1 then
    Param2 := ParamStr(2);

  if SameText(Param1, '/quit') or SameText(Param1, '-quit') then
  begin
    AvisarHost(MensajeSalir);
    Exit;
  end;

  if SameText(Param1, '/install') or SameText(Param1, '-install') then
  begin
    Ajustes := AjustesEnUso;
    if not Instalar(Ajustes, Mensaje) then
      Halt(1);
    if not Aplicar(Ajustes, Mensaje) then
      Halt(2);
    Exit;
  end;

  if SameText(Param1, '/apply') or SameText(Param1, '-apply') then
  begin
    if not FileExists(RutaIniInstalada) then
      Halt(3);
    Ajustes := CargarAjustes(RutaIniInstalada);
    if not Aplicar(Ajustes, Mensaje) then
      Halt(1);
    Exit;
  end;

  if SameText(Param1, '/uninstall') or SameText(Param1, '-uninstall') then
  begin
    if not Desinstalar(not SameText(Param2, '/discard'), Mensaje) then
      Halt(1);
    Exit;
  end;

  Application.CreateForm(TConfigForm, Form);
  Application.Run;
end.
