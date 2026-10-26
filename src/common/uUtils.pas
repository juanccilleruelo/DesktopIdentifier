unit uUtils;

{ Utilidades compartidas por el configurador y el host: colores, DPI,
  resolucion, lectura simple de INI y comunicacion entre procesos.
  No depende de VCL (el host debe quedar sin VCL). }

interface

uses
  Winapi.Windows, System.SysUtils, System.Math,
  Winapi.GDIPAPI, uPaths;

type
  { Color RGB canonico en formato $00RRGGBB (distinto del TColor de VCL,
    que es $00BBGGRR). }
  TRgb = Cardinal;

const
  RgbBlanco: TRgb = $00FFFFFF;
  RgbNegro:  TRgb = $00000000;

function RgbOf(R, G, B: Byte): TRgb; inline;
function HexARgb(const Hex: string; Defecto: TRgb): TRgb;
function RgbAHex(C: TRgb): string;
function ArgbDe(C: TRgb; Alpha: Byte): ARGB;
function MezclarRgb(A, B: TRgb; T: Double): TRgb;
function MezclaArgb(C, Destino: TRgb; T: Double; Alpha: Byte): ARGB;

function DpiDeVentana(Wnd: HWND): Cardinal;
function DpiDeMonitor(Mon: HMONITOR): Cardinal;
procedure ConfigurarDpi;
function ResolucionPrimaria(out Ancho, Alto: Integer): Boolean;

function GetEncoderClsid(const MimeType: string; out Clsid: TGUID): Boolean;
function NormalizarRuta(const Ruta: string): string;
function MismaRuta(const A, B: string): Boolean;

function VentanaHost: HWND;
function HostEnEjecucion: Boolean;
procedure AvisarHost(const NombreMensaje: string);

implementation

function RgbOf(R, G, B: Byte): TRgb;
begin
  Result := (TRgb(R) shl 16) or (TRgb(G) shl 8) or TRgb(B);
end;

function HexARgb(const Hex: string; Defecto: TRgb): TRgb;
var
  S: string;
  R, G, B: Integer;
begin
  Result := Defecto;
  S := Trim(Hex);
  if (S <> '') and (S[1] = '#') then
    Delete(S, 1, 1);
  if Length(S) = 3 then
    S := S[1] + S[1] + S[2] + S[2] + S[3] + S[3];
  if Length(S) <> 6 then
    Exit;
  try
    R := StrToInt('$' + Copy(S, 1, 2));
    G := StrToInt('$' + Copy(S, 3, 2));
    B := StrToInt('$' + Copy(S, 5, 2));
    Result := RgbOf(Byte(R), Byte(G), Byte(B));
  except
    Result := Defecto;
  end;
end;

function RgbAHex(C: TRgb): string;
begin
  Result := Format('#%.2X%.2X%.2X',
    [Byte((C shr 16) and $FF), Byte((C shr 8) and $FF), Byte(C and $FF)]);
end;

function ArgbDe(C: TRgb; Alpha: Byte): ARGB;
begin
  Result := MakeColor(Alpha, Byte((C shr 16) and $FF),
    Byte((C shr 8) and $FF), Byte(C and $FF));
end;

function MezclarRgb(A, B: TRgb; T: Double): TRgb;
var
  Ra, Ga, Ba, Rb, Gb, Bb: Integer;
begin
  if T < 0 then
    T := 0;
  if T > 1 then
    T := 1;
  Ra := (A shr 16) and $FF;
  Ga := (A shr 8) and $FF;
  Ba := A and $FF;
  Rb := (B shr 16) and $FF;
  Gb := (B shr 8) and $FF;
  Bb := B and $FF;
  Result := RgbOf(Byte(Round(Ra + (Rb - Ra) * T)),
    Byte(Round(Ga + (Gb - Ga) * T)),
    Byte(Round(Ba + (Bb - Ba) * T)));
end;

function MezclaArgb(C, Destino: TRgb; T: Double; Alpha: Byte): ARGB;
begin
  Result := ArgbDe(MezclarRgb(C, Destino, T), Alpha);
end;

type
  TGetDpiForWindow = function(hwnd: HWND): UINT; stdcall;
  TGetDpiForMonitor = function(hmonitor: HMONITOR; dpiType: Integer;
    dpiX, dpiY: PUINT): HRESULT; stdcall;

var
  GDpiForMonitor: TGetDpiForMonitor = nil;
  GDpiForMonitorBuscado: Boolean = False;

function DpiDeVentana(Wnd: HWND): Cardinal;
var
  Fn: TGetDpiForWindow;
begin
  Result := 0;
  if Wnd <> 0 then
  begin
    Fn := TGetDpiForWindow(GetProcAddress(GetModuleHandle('user32.dll'),
      'GetDpiForWindow'));
    if Assigned(Fn) then
      Result := Fn(Wnd);
  end;
  if Result < 72 then
    Result := 96;
end;

function DpiDeMonitor(Mon: HMONITOR): Cardinal;
const
  MDT_EFFECTIVE_DPI = 0;
var
  Dx, Dy: UINT;
  Lib: HMODULE;
begin
  Result := 0;
  if Mon = 0 then
    Exit;
  if not GDpiForMonitorBuscado then
  begin
    GDpiForMonitorBuscado := True;
    Lib := LoadLibrary('shcore.dll');
    if Lib <> 0 then
      GDpiForMonitor := TGetDpiForMonitor(GetProcAddress(Lib, 'GetDpiForMonitor'));
  end;
  if Assigned(GDpiForMonitor) then
  begin
    Dx := 0;
    Dy := 0;
    if GDpiForMonitor(Mon, MDT_EFFECTIVE_DPI, @Dx, @Dy) = 0 then
      Result := Dx;
  end;
  if Result < 72 then
    Result := 0;
end;

procedure ConfigurarDpi;
type
  TSetProcessDpiAwarenessContext = function(Value: THandle): BOOL; stdcall;
var
  Fn: TSetProcessDpiAwarenessContext;
begin
  Fn := TSetProcessDpiAwarenessContext(GetProcAddress(
    GetModuleHandle('user32.dll'), 'SetProcessDpiAwarenessContext'));
  if Assigned(Fn) then
  begin
    if Fn(THandle(-4)) then
      Exit; // PER_MONITOR_AWARE_V2
    if Fn(THandle(-3)) then
      Exit; // PER_MONITOR_AWARE
  end;
  SetProcessDPIAware;
end;

function ResolucionPrimaria(out Ancho, Alto: Integer): Boolean;
var
  DevMode: TDevMode;
begin
  ZeroMemory(@DevMode, SizeOf(DevMode));
  DevMode.dmSize := SizeOf(DevMode);
  Result := EnumDisplaySettings(nil, DWORD(-1), DevMode);
  if Result then
  begin
    Ancho := Integer(DevMode.dmPelsWidth);
    Alto := Integer(DevMode.dmPelsHeight);
  end
  else
  begin
    Ancho := 1920;
    Alto := 1080;
  end;
end;

function GetEncoderClsid(const MimeType: string; out Clsid: TGUID): Boolean;
var
  Num, Size: UINT;
  Encoders: PImageCodecInfo;
  Info: PImageCodecInfo;
  I: Integer;
  S: string;
begin
  Result := False;
  Num := 0;
  Size := 0;
  if GdipGetImageEncodersSize(Num, Size) <> Ok then
    Exit;
  if (Size = 0) or (Num = 0) then
    Exit;

  GetMem(Encoders, Size);
  try
    if GdipGetImageEncoders(Num, Size, Encoders) <> Ok then
      Exit;
    Info := Encoders;
    for I := 0 to Num - 1 do
    begin
      S := Info.MimeType;
      if SameText(S, MimeType) then
      begin
        Clsid := Info.Clsid;
        Exit(True);
      end;
      Inc(Info);
    end;
  finally
    FreeMem(Encoders);
  end;
end;

function NormalizarRuta(const Ruta: string): string;
var
  S: string;
begin
  Result := '';
  S := Trim(Ruta);
  if (Length(S) >= 2) and (S[1] = '"') and (S[Length(S)] = '"') then
    S := Copy(S, 2, Length(S) - 2);
  if S = '' then
    Exit;
  Result := LowerCase(ExcludeTrailingPathDelimiter(ExpandFileName(S)));
end;

function MismaRuta(const A, B: string): Boolean;
var
  Na, Nb: string;
begin
  Na := NormalizarRuta(A);
  Nb := NormalizarRuta(B);
  Result := (Na <> '') and (Na = Nb);
end;

function VentanaHost: HWND;
begin
  Result := FindWindow(PChar(ClaseVentanaHost), nil);
end;

function HostEnEjecucion: Boolean;
var
  H: THandle;
begin
  H := OpenMutex(SYNCHRONIZE, False, PChar(MutexHost));
  Result := H <> 0;
  if Result then
    CloseHandle(H);
end;

procedure AvisarHost(const NombreMensaje: string);
var
  H: HWND;
  M: Cardinal;
begin
  H := VentanaHost;
  if H = 0 then
    Exit;
  M := RegisterWindowMessage(PChar(NombreMensaje));
  if M <> 0 then
    PostMessage(H, M, 0, 0);
end;

end.
