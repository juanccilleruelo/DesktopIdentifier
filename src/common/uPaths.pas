unit uPaths;

{ Rutas y nombres fijos del producto. Es el unico sitio donde viven. }

interface

uses
  Winapi.Windows, System.SysUtils;

const
  NombreProducto       = 'DesktopIdentifier';
  NombreConfig         = 'DesktopIdentifier.exe';
  NombreHost           = 'DesktopIdentifierHost.exe';
  NombreIni            = 'desktopidentifier.ini';
  NombreIniLegado      = 'distintive.ini';

  ValorRun             = 'DesktopIdentifier';
  ClaveRun             = '\Software\Microsoft\Windows\CurrentVersion\Run';
  ClaveStartupApproved = '\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run';

  ClaseVentanaHost     = 'DesktopIdentifierHostWindow';
  MutexHost            = 'Local\DesktopIdentifier_Host';
  MensajeRecarga       = 'DesktopIdentifier_RELOAD';
  MensajeSalir         = 'DesktopIdentifier_QUIT';

  ArchivoFondo         = 'fondo-distintivo.png';
  ArchivoFondoOriginal = 'fondo-original.dat';
  ArchivoMarcador      = 'fondo-original.ini';

  VersionAjustes       = 2;

function DirectorioInstalacion: string;
function DirectorioExe: string;
function RutaIniInstalada: string;
function RutaHostInstalado: string;
function RutaHostFuente: string;
function RutaIniLegado: string;

implementation

function DirectorioExe: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
end;

function DirectorioInstalacion: string;
var
  Base: string;
begin
  Base := GetEnvironmentVariable('LOCALAPPDATA');
  if Base = '' then
    Base := GetEnvironmentVariable('APPDATA');
  if Base <> '' then
    Result := IncludeTrailingPathDelimiter(IncludeTrailingPathDelimiter(Base) + NombreProducto)
  else
    Result := DirectorioExe;
end;

function RutaIniInstalada: string;
begin
  Result := DirectorioInstalacion + NombreIni;
end;

function RutaHostInstalado: string;
begin
  Result := DirectorioInstalacion + NombreHost;
end;

function RutaHostFuente: string;
begin
  Result := DirectorioExe + NombreHost;
end;

function RutaIniLegado: string;
begin
  Result := DirectorioExe + NombreIniLegado;
end;

end.
