unit uSettings;

{ Modelo de ajustes compartido por el configurador y el host, con lectura
  tolerante y escritura atomica del INI. Nunca lanza excepciones al cargar:
  un INI corrupto o ausente equivale a los valores por defecto.

  Lee y escribe con la API de Win32 a proposito: usar TStringList obligaria a
  enlazar System.Classes en el host y el ejecutable pasaria de 1 MB. }

interface

uses
  Winapi.Windows, System.SysUtils, System.Math,
  uUtils, uPaths;

type
  TSettings = record
    Version: Integer;
    // Cartel
    Texto: string;
    Color: TRgb;
    ColorTexto: TRgb;
    Tamano: Integer;
    OpacidadPanel: Double;
    OpacidadLetra: Double;
    MargenDerecha: Integer;
    MargenInferior: Integer;
    Pantalla: Integer;
    Esquinas: Double;
    Fuente: string;
    // Banda
    BandaActiva: Boolean;
    BandaColor: TRgb;
    BandaAlto: Double;
    BandaTexto: string;
    BandaColorTexto: TRgb;
    BandaAlineacion: string;
  end;

function AjustesPorDefecto: TSettings;
function AjustesValidos(const S: TSettings): TSettings;
function CargarAjustes(const Archivo: string): TSettings;
function GuardarAjustes(const Archivo: string; const S: TSettings): Boolean;
function AjustesEnUso: TSettings;
function ColorPorTexto(const Texto: string): TRgb;

implementation

var
  FormatoInv: TFormatSettings;

function AjustesPorDefecto: TSettings;
begin
  Result.Version := VersionAjustes;
  Result.Texto := 'A';
  Result.Color := $001473E6;
  Result.ColorTexto := RgbBlanco;
  Result.Tamano := 170;
  Result.OpacidadPanel := 0.32;
  Result.OpacidadLetra := 0.95;
  Result.MargenDerecha := 30;
  Result.MargenInferior := 30;
  Result.Pantalla := 0;
  Result.Esquinas := 0.24;
  Result.Fuente := 'Segoe UI';
  Result.BandaActiva := True;
  Result.BandaColor := $001473E6;
  Result.BandaAlto := 0.08;
  Result.BandaTexto := '';
  Result.BandaColorTexto := RgbBlanco;
  Result.BandaAlineacion := 'derecha';
end;

function ColorPorTexto(const Texto: string): TRgb;
begin
  if (Texto <> '') and (UpCase(Texto[1]) = 'B') then
    Result := $00E8590C
  else
    Result := $001473E6;
end;

function AjustesValidos(const S: TSettings): TSettings;
begin
  Result := S;
  Result.Version := VersionAjustes;

  Result.Texto := Trim(Result.Texto);
  if Result.Texto = '' then
    Result.Texto := 'A';
  if Length(Result.Texto) > 4 then
    Result.Texto := Copy(Result.Texto, 1, 4);

  Result.Fuente := Trim(Result.Fuente);
  if Result.Fuente = '' then
    Result.Fuente := 'Segoe UI';

  Result.Tamano := EnsureRange(Result.Tamano, 90, 280);
  Result.OpacidadPanel := EnsureRange(Result.OpacidadPanel, 0.10, 0.60);
  Result.OpacidadLetra := EnsureRange(Result.OpacidadLetra, 0.30, 1.00);
  Result.MargenDerecha := EnsureRange(Result.MargenDerecha, 0, 1000);
  Result.MargenInferior := EnsureRange(Result.MargenInferior, 0, 1000);
  Result.Pantalla := EnsureRange(Result.Pantalla, 0, 8);
  Result.Esquinas := EnsureRange(Result.Esquinas, 0.0, 0.5);

  Result.BandaAlto := EnsureRange(Result.BandaAlto, 0.02, 0.20);
  Result.BandaTexto := Trim(Result.BandaTexto);
  if Length(Result.BandaTexto) > 20 then
    Result.BandaTexto := Copy(Result.BandaTexto, 1, 20);

  Result.BandaAlineacion := LowerCase(Trim(Result.BandaAlineacion));
  if (Result.BandaAlineacion <> 'derecha') and
     (Result.BandaAlineacion <> 'centro') and
     (Result.BandaAlineacion <> 'izquierda') then
    Result.BandaAlineacion := 'derecha';
end;

{ Lee el archivo completo respetando el BOM (UTF-8 / UTF-16) y, si no hay
  BOM, la pagina ANSI del sistema. Devuelve False si no se puede leer. }
function LeerTexto(const Archivo: string; out Texto: string): Boolean;
var
  H: THandle;
  Tam: DWORD;
  Leidos: DWORD;
  Buf: TBytes;
begin
  Result := False;
  Texto := '';

  H := CreateFile(PChar(Archivo), GENERIC_READ,
    FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING,
    FILE_ATTRIBUTE_NORMAL, 0);
  if H = INVALID_HANDLE_VALUE then
    Exit;
  try
    Tam := GetFileSize(H, nil);
    if (Tam = INVALID_FILE_SIZE) or (Tam > 4 * 1024 * 1024) then
      Exit;
    SetLength(Buf, Tam);
    if Tam > 0 then
    begin
      if not ReadFile(H, Buf[0], Tam, Leidos, nil) then
        Exit;
      SetLength(Buf, Leidos);
    end;
  finally
    CloseHandle(H);
  end;

  if Length(Buf) >= 3 then
    if (Buf[0] = $EF) and (Buf[1] = $BB) and (Buf[2] = $BF) then
    begin
      Texto := TEncoding.UTF8.GetString(Buf, 3, Length(Buf) - 3);
      Exit(True);
    end;
  if Length(Buf) >= 2 then
  begin
    if (Buf[0] = $FF) and (Buf[1] = $FE) then
    begin
      Texto := TEncoding.Unicode.GetString(Buf, 2, Length(Buf) - 2);
      Exit(True);
    end;
    if (Buf[0] = $FE) and (Buf[1] = $FF) then
    begin
      Texto := TEncoding.BigEndianUnicode.GetString(Buf, 2, Length(Buf) - 2);
      Exit(True);
    end;
  end;
  Texto := TEncoding.Default.GetString(Buf);
  Result := True;
end;

function EscribirTextoAtomico(const Archivo, Texto: string): Boolean;
var
  H: THandle;
  Temp: string;
  Preambulo, Datos: TBytes;
  Escrito: DWORD;
  Ok: Boolean;
begin
  Result := False;
  Temp := Archivo + '.tmp';
  Preambulo := TEncoding.UTF8.GetPreamble;
  Datos := TEncoding.UTF8.GetBytes(Texto);

  H := CreateFile(PChar(Temp), GENERIC_WRITE, 0, nil, CREATE_ALWAYS,
    FILE_ATTRIBUTE_NORMAL, 0);
  if H = INVALID_HANDLE_VALUE then
    Exit;
  try
    Ok := True;
    if Length(Preambulo) > 0 then
      Ok := WriteFile(H, Preambulo[0], Length(Preambulo), Escrito, nil);
    if Ok and (Length(Datos) > 0) then
      Ok := WriteFile(H, Datos[0], Length(Datos), Escrito, nil);
    if Ok then
      FlushFileBuffers(H);
  finally
    CloseHandle(H);
  end;

  if not Ok then
  begin
    DeleteFile(Temp);
    Exit;
  end;

  Result := MoveFileEx(PChar(Temp), PChar(Archivo),
    MOVEFILE_REPLACE_EXISTING or MOVEFILE_WRITE_THROUGH);
  if not Result then
  begin
    if DeleteFile(Archivo) then
      Result := RenameFile(Temp, Archivo);
  end;
  if not Result then
    DeleteFile(Temp);
end;

function CargarAjustes(const Archivo: string): TSettings;
var
  Contenido, Linea, Seccion: string;
  I, J, P: Integer;
  BandaColorLeida: Boolean;

  function ADouble(const S: string; Defecto: Double): Double;
  begin
    Result := StrToFloatDef(StringReplace(Trim(S), ',', '.', [rfReplaceAll]),
      Defecto, FormatoInv);
  end;

  function AEntero(const S: string; Defecto: Integer): Integer;
  begin
    Result := Round(ADouble(S, Defecto));
  end;

  function ABool(const S: string; Defecto: Boolean): Boolean;
  var
    V: string;
  begin
    V := LowerCase(Trim(S));
    if (V = '1') or (V = 'true') or (V = 'si') or (V = 'yes') or (V = 'on') then
      Result := True
    else if (V = '0') or (V = 'false') or (V = 'no') or (V = 'off') then
      Result := False
    else
      Result := Defecto;
  end;

  procedure AplicarClave(const Sec, K, V: string);
  begin
    if (Sec = '') or (Sec = 'general') then
      if K = 'version' then
        Result.Version := AEntero(V, Result.Version);

    // Claves del cartel (seccion [cartel] o INI antiguo sin secciones).
    if (Sec = '') or (Sec = 'cartel') then
    begin
      if (K = 'texto') or (K = 'letra') then
        Result.Texto := Trim(V)
      else if K = 'color' then
        Result.Color := HexARgb(V, Result.Color)
      else if K = 'color_texto' then
        Result.ColorTexto := HexARgb(V, Result.ColorTexto)
      else if K = 'tamano' then
        Result.Tamano := AEntero(V, Result.Tamano)
      else if K = 'opacidad_panel' then
        Result.OpacidadPanel := ADouble(V, Result.OpacidadPanel)
      else if K = 'opacidad_letra' then
        Result.OpacidadLetra := ADouble(V, Result.OpacidadLetra)
      else if K = 'margen_derecha' then
        Result.MargenDerecha := AEntero(V, Result.MargenDerecha)
      else if K = 'margen_inferior' then
        Result.MargenInferior := AEntero(V, Result.MargenInferior)
      else if K = 'pantalla' then
        Result.Pantalla := AEntero(V, Result.Pantalla)
      else if K = 'esquinas' then
        Result.Esquinas := ADouble(V, Result.Esquinas)
      else if K = 'fuente' then
        Result.Fuente := Trim(V);
    end;

    // Claves de la banda (seccion [banda] o INI antiguo banda_*).
    if (Sec = '') or (Sec = 'banda') then
    begin
      if (K = 'banda_activa') or ((Sec = 'banda') and (K = 'activa')) then
        Result.BandaActiva := ABool(V, Result.BandaActiva)
      else if (K = 'banda_alto') or ((Sec = 'banda') and (K = 'alto')) then
        Result.BandaAlto := ADouble(V, Result.BandaAlto)
      else if (K = 'banda_texto') or ((Sec = 'banda') and (K = 'texto')) then
        Result.BandaTexto := Trim(V)
      else if (Sec = 'banda') and (K = 'color') then
      begin
        Result.BandaColor := HexARgb(V, Result.BandaColor);
        BandaColorLeida := True;
      end
      else if (Sec = 'banda') and (K = 'color_texto') then
        Result.BandaColorTexto := HexARgb(V, Result.BandaColorTexto)
      else if (K = 'banda_alineacion') or ((Sec = 'banda') and (K = 'alineacion')) then
        Result.BandaAlineacion := Trim(V);
    end;
  end;

  procedure ProcesarLinea(const L: string);
  begin
    if L[1] = '[' then
    begin
      P := Pos(']', L);
      if P > 1 then
        Seccion := LowerCase(Trim(Copy(L, 2, P - 2)));
      Exit;
    end;
    if (L[1] = ';') or (L[1] = '#') then
      Exit;
    P := Pos('=', L);
    if P < 2 then
      Exit;
    AplicarClave(Seccion, LowerCase(Trim(Copy(L, 1, P - 1))),
      Trim(Copy(L, P + 1, MaxInt)));
  end;

begin
  Result := AjustesPorDefecto;
  BandaColorLeida := False;

  if not FileExists(Archivo) then
    Exit;
  if not LeerTexto(Archivo, Contenido) then
    Exit;

  Seccion := '';
  I := 1;
  while I <= Length(Contenido) do
  begin
    J := I;
    while (J <= Length(Contenido)) and (Contenido[J] <> #10) and
      (Contenido[J] <> #13) do
      Inc(J);
    Linea := Trim(Copy(Contenido, I, J - I));
    if Linea <> '' then
      ProcesarLinea(Linea);
    while (J <= Length(Contenido)) and ((Contenido[J] = #10) or
      (Contenido[J] = #13)) do
      Inc(J);
    I := J;
  end;

  // En el INI antiguo habia un solo color para banda y cartel.
  if not BandaColorLeida then
    Result.BandaColor := Result.Color;

  Result := AjustesValidos(Result);
end;

function GuardarAjustes(const Archivo: string; const S: TSettings): Boolean;
var
  A: TSettings;
  T: string;
begin
  A := AjustesValidos(S);

  if ExtractFilePath(Archivo) <> '' then
    ForceDirectories(ExtractFilePath(Archivo));

  T := '';
  T := T + '; DesktopIdentifier - configuracion' + sLineBreak;
  T := T + '; Se puede editar a mano. El host la relee al recibir RELOAD.' + sLineBreak;
  T := T + sLineBreak;
  T := T + '[general]' + sLineBreak;
  T := T + 'version=' + IntToStr(A.Version) + sLineBreak;
  T := T + sLineBreak;
  T := T + '[cartel]' + sLineBreak;
  T := T + 'texto=' + A.Texto + sLineBreak;
  T := T + 'color=' + RgbAHex(A.Color) + sLineBreak;
  T := T + 'color_texto=' + RgbAHex(A.ColorTexto) + sLineBreak;
  T := T + 'tamano=' + IntToStr(A.Tamano) + sLineBreak;
  T := T + 'opacidad_panel=' + FloatToStr(A.OpacidadPanel, FormatoInv) + sLineBreak;
  T := T + 'opacidad_letra=' + FloatToStr(A.OpacidadLetra, FormatoInv) + sLineBreak;
  T := T + 'margen_derecha=' + IntToStr(A.MargenDerecha) + sLineBreak;
  T := T + 'margen_inferior=' + IntToStr(A.MargenInferior) + sLineBreak;
  T := T + 'pantalla=' + IntToStr(A.Pantalla) + sLineBreak;
  T := T + 'esquinas=' + FloatToStr(A.Esquinas, FormatoInv) + sLineBreak;
  T := T + 'fuente=' + A.Fuente + sLineBreak;
  T := T + sLineBreak;
  T := T + '[banda]' + sLineBreak;
  if A.BandaActiva then
    T := T + 'activa=1' + sLineBreak
  else
    T := T + 'activa=0' + sLineBreak;
  T := T + 'color=' + RgbAHex(A.BandaColor) + sLineBreak;
  T := T + 'alto=' + FloatToStr(A.BandaAlto, FormatoInv) + sLineBreak;
  T := T + 'texto=' + A.BandaTexto + sLineBreak;
  T := T + 'color_texto=' + RgbAHex(A.BandaColorTexto) + sLineBreak;
  T := T + 'alineacion=' + A.BandaAlineacion + sLineBreak;

  Result := EscribirTextoAtomico(Archivo, T);
end;

function AjustesEnUso: TSettings;
begin
  if FileExists(RutaIniInstalada) then
    Result := CargarAjustes(RutaIniInstalada)
  else if FileExists(RutaIniLegado) then
    Result := CargarAjustes(RutaIniLegado)
  else
    Result := AjustesPorDefecto;
end;

initialization
  FormatoInv := TFormatSettings.Create('en-US');
  FormatoInv.DecimalSeparator := '.';
  FormatoInv.ThousandSeparator := #0;

end.
