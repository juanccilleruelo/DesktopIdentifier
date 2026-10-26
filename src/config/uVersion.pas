unit uVersion;

{ Lectura y comparacion de la version del ejecutable. La version real vive en
  los recursos (.rc); VersionProducto es solo el valor de reserva. }

interface

uses
  System.SysUtils;

const
  VersionProducto = '1.1.0.0';

function VersionArchivo(const Ruta: string): string;
function VersionApp: string;
function CompararVersiones(const A, B: string): Integer;

implementation

uses
  Winapi.Windows;

function VersionArchivo(const Ruta: string): string;
var
  Dummy, Tam: DWORD;
  Buf, BufPtr: Pointer;
  Fixed: PVSFixedFileInfo;
  Len: UINT;
  MS, LS: DWORD;
begin
  Result := '';
  if not FileExists(Ruta) then
    Exit;

  Dummy := 0;
  Tam := GetFileVersionInfoSize(PChar(Ruta), Dummy);
  if Tam = 0 then
    Exit;

  GetMem(Buf, Tam);
  try
    if not GetFileVersionInfo(PChar(Ruta), 0, Tam, Buf) then
      Exit;
    BufPtr := nil;
    Len := 0;
    if not VerQueryValue(Buf, '\', BufPtr, Len) then
      Exit;
    Fixed := PVSFixedFileInfo(BufPtr);
    if (Fixed = nil) or (Len < SizeOf(TVSFixedFileInfo)) then
      Exit;
    MS := Fixed.dwFileVersionMS;
    LS := Fixed.dwFileVersionLS;
    Result := Format('%d.%d.%d.%d', [HiWord(MS), LoWord(MS), HiWord(LS), LoWord(LS)]);
  finally
    FreeMem(Buf);
  end;
end;

function VersionApp: string;
begin
  Result := VersionArchivo(ParamStr(0));
  if Result = '' then
    Result := VersionProducto;
end;

function CompararVersiones(const A, B: string): Integer;
var
  VA, VB: array[0..3] of Integer;
  I: Integer;

  procedure Parsear(const Texto: string; var V: array of Integer);
  var
    Indice, P, N: Integer;
    T: string;
  begin
    for Indice := Low(V) to High(V) do
      V[Indice] := 0;
    T := Trim(Texto);
    Indice := 0;
    P := 1;
    while (P <= Length(T)) and (Indice <= High(V)) do
    begin
      N := P;
      while (N <= Length(T)) and (T[N] <> '.') do
        Inc(N);
      V[Indice] := StrToIntDef(Copy(T, P, N - P), 0);
      Inc(Indice);
      P := N + 1;
    end;
  end;

begin
  Parsear(A, VA);
  Parsear(B, VB);
  for I := 0 to 3 do
    if VA[I] <> VB[I] then
    begin
      if VA[I] > VB[I] then
        Result := 1
      else
        Result := -1;
      Exit;
    end;
  Result := 0;
end;

end.
