unit uWallpaper;

{ Composicion, aplicacion y restauracion de la banda integrada en el fondo.
  Solo lo usa el configurador: el host no toca el escritorio. }

interface

uses
  Winapi.Windows, System.SysUtils, uSettings;

function FondoActual: string;
function PrepararOriginal(const Dir: string): Boolean;
function RutaOriginal(const Dir: string): string;
function GenerarFondo(const Dir: string; const Ajustes: TSettings): string;
function AplicarFondo(const Ruta: string): Boolean;
function RestaurarFondo(const Dir: string): Boolean;

implementation

uses
  System.Classes, System.Math, System.Win.Registry,
  Winapi.GDIPAPI, Winapi.GDIPOBJ,
  uPaths, uUtils, uBandRender, uBadgeRender;

function LeerClaveIni(const Archivo, Clave: string): string;
var
  L: TStringList;
  I, P: Integer;
  Linea, K: string;
begin
  Result := '';
  if not FileExists(Archivo) then
    Exit;
  L := TStringList.Create;
  try
    try
      L.LoadFromFile(Archivo);
    except
      Exit;
    end;
    for I := 0 to L.Count - 1 do
    begin
      Linea := Trim(L[I]);
      if (Linea = '') or (Linea[1] = ';') or (Linea[1] = '#') or (Linea[1] = '[') then
        Continue;
      P := Pos('=', Linea);
      if P < 2 then
        Continue;
      K := LowerCase(Trim(Copy(Linea, 1, P - 1)));
      if K = LowerCase(Clave) then
        Exit(Trim(Copy(Linea, P + 1, MaxInt)));
    end;
  finally
    L.Free;
  end;
end;

function FondoActual: string;
var
  Reg: TRegistry;
begin
  Result := '';
  Reg := TRegistry.Create(KEY_READ);
  try
    try
      Reg.RootKey := HKEY_CURRENT_USER;
      if Reg.OpenKeyReadOnly('\Control Panel\Desktop') then
        Result := Reg.ReadString('Wallpaper');
    except
      Result := '';
    end;
  finally
    Reg.Free;
  end;
end;

procedure LeerEstilo(out Estilo, Mosaico: string);
var
  Reg: TRegistry;
begin
  Estilo := '10';
  Mosaico := '0';
  Reg := TRegistry.Create(KEY_READ);
  try
    try
      Reg.RootKey := HKEY_CURRENT_USER;
      if Reg.OpenKeyReadOnly('\Control Panel\Desktop') then
      begin
        if Reg.ValueExists('WallpaperStyle') then
          Estilo := Reg.ReadString('WallpaperStyle');
        if Reg.ValueExists('TileWallpaper') then
          Mosaico := Reg.ReadString('TileWallpaper');
      end;
    except
      // se usan los valores por defecto
    end;
  finally
    Reg.Free;
  end;
end;

function FijarFondoRegistro(const Ruta, Estilo, Mosaico: string): Boolean;
var
  Reg: TRegistry;
begin
  Result := False;
  Reg := TRegistry.Create(KEY_WRITE);
  try
    try
      Reg.RootKey := HKEY_CURRENT_USER;
      if Reg.OpenKey('\Control Panel\Desktop', False) then
      begin
        Reg.WriteString('Wallpaper', Ruta);
        Reg.WriteString('WallpaperStyle', Estilo);
        Reg.WriteString('TileWallpaper', Mosaico);
        Result := True;
      end;
    except
      Result := False;
    end;
  finally
    Reg.Free;
  end;
end;

function PrepararOriginal(const Dir: string): Boolean;
var
  Marcador, Ruta, Copia, Estilo, Mosaico: string;
  L: TStringList;
begin
  Marcador := Dir + ArchivoMarcador;
  if FileExists(Marcador) then
    Exit(True);

  Ruta := FondoActual;
  Copia := '';
  if (Ruta <> '') and FileExists(Ruta) and
     (not SameText(ExtractFileName(Ruta), ArchivoFondo)) then
  begin
    Copia := ArchivoFondoOriginal;
    if not CopyFile(PChar(Ruta), PChar(Dir + Copia), False) then
      Copia := '';
  end
  else
    Ruta := '';

  LeerEstilo(Estilo, Mosaico);

  L := TStringList.Create;
  try
    L.Add('; Fondo original guardado por DesktopIdentifier. No borrar: se usa al desinstalar.');
    L.Add('ruta=' + Ruta);
    L.Add('estilo=' + Estilo);
    L.Add('mosaico=' + Mosaico);
    L.Add('copia=' + Copia);
    L.WriteBOM := True;
    L.SaveToFile(Marcador, TEncoding.UTF8);
  finally
    L.Free;
  end;

  Result := True;
end;

function RutaOriginal(const Dir: string): string;
var
  Marcador, Ruta, Copia: string;
begin
  Result := '';
  Marcador := Dir + ArchivoMarcador;
  if not FileExists(Marcador) then
    Exit;

  Copia := LeerClaveIni(Marcador, 'copia');
  if (Copia <> '') and FileExists(Dir + Copia) then
    Exit(Dir + Copia);

  Ruta := LeerClaveIni(Marcador, 'ruta');
  if (Ruta <> '') and FileExists(Ruta) and
     (not SameText(ExtractFileName(Ruta), ArchivoFondo)) then
    Result := Ruta;
end;

function GenerarFondo(const Dir: string; const Ajustes: TSettings): string;
var
  W, H, Dx, Dy, Dw, Dh: Integer;
  Bmp: TGPBitmap;
  G: TGPGraphics;
  Src: TGPImage;
  Ruta, Salida: string;
  Clsid: TGUID;
  Alto, SombraAlto, Escala: Single;
  Area, SombraR: TGPRectF;
  Br: TGPLinearGradientBrush;
  Dibujado: Boolean;
begin
  if not ResolucionPrimaria(W, H) then
  begin
    W := 1920;
    H := 1080;
  end;
  if W < 320 then
    W := 1920;
  if H < 240 then
    H := 1080;

  Salida := Dir + ArchivoFondo;
  Result := Salida;

  Bmp := TGPBitmap.Create(W, H, PixelFormat32bppARGB);
  try
    G := TGPGraphics.Create(Bmp);
    try
      G.SetSmoothingMode(SmoothingModeAntiAlias);
      G.SetInterpolationMode(InterpolationModeHighQualityBicubic);
      G.SetPixelOffsetMode(PixelOffsetModeHighQuality);

      Dibujado := False;
      Ruta := RutaOriginal(Dir);
      if Ruta <> '' then
      begin
        try
          Src := TGPImage.Create(WideString(Ruta));
          try
            Escala := Max(Double(W) / Src.GetWidth, Double(H) / Src.GetHeight);
            Dw := Ceil(Src.GetWidth * Escala);
            Dh := Ceil(Src.GetHeight * Escala);
            Dx := (W - Dw) div 2;
            Dy := (H - Dh) div 2;
            G.DrawImage(Src, Dx, Dy, Dw, Dh);
            Dibujado := True;
          finally
            Src.Free;
          end;
        except
          Dibujado := False;
        end;
      end;

      if not Dibujado then
      begin
        Br := TGPLinearGradientBrush.Create(RF(0, 0, W, H),
          MakeColor(255, 22, 24, 32), MakeColor(255, 54, 58, 72), 90);
        try
          G.FillRectangle(Br, RF(0, 0, W, H));
        finally
          Br.Free;
        end;
      end;

      Alto := H * Ajustes.BandaAlto;
      if Alto < 10 then
        Alto := 10;
      if Alto > H * 0.22 then
        Alto := H * 0.22;
      Area := RF(0, 0, W, Alto);
      DibujarBanda(G, Area, Ajustes.BandaColor, Ajustes.BandaTexto,
        Ajustes.BandaColorTexto);

      SombraAlto := Max(6, Alto * 0.12);
      SombraR := RF(0, Alto, W, SombraAlto);
      Br := TGPLinearGradientBrush.Create(SombraR,
        MakeColor(85, 0, 0, 0), MakeColor(0, 0, 0, 0), 90);
      try
        G.FillRectangle(Br, SombraR);
      finally
        Br.Free;
      end;
    finally
      G.Free;
    end;

    if GetEncoderClsid('image/png', Clsid) then
      Bmp.Save(WideString(Salida), Clsid);
  finally
    Bmp.Free;
  end;
end;

function AplicarFondo(const Ruta: string): Boolean;
begin
  FijarFondoRegistro(Ruta, '10', '0');
  Result := SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, Pointer(PWideChar(Ruta)),
    SPIF_UPDATEINIFILE or SPIF_SENDCHANGE);
end;

function RestaurarFondo(const Dir: string): Boolean;
var
  Marcador, Ruta, Copia, Destino, Estilo, Mosaico, Transcoded: string;
begin
  Result := False;
  Marcador := Dir + ArchivoMarcador;
  if not FileExists(Marcador) then
    Exit;

  Ruta := LeerClaveIni(Marcador, 'ruta');
  Copia := LeerClaveIni(Marcador, 'copia');
  Estilo := LeerClaveIni(Marcador, 'estilo');
  Mosaico := LeerClaveIni(Marcador, 'mosaico');
  if Estilo = '' then
    Estilo := '10';
  if Mosaico = '' then
    Mosaico := '0';

  Destino := '';
  if (Copia <> '') and FileExists(Dir + Copia) then
  begin
    Transcoded := IncludeTrailingPathDelimiter(GetEnvironmentVariable('APPDATA')) +
      'Microsoft\Windows\Themes\TranscodedWallpaper';
    if CopyFile(PChar(Dir + Copia), PChar(Transcoded), False) then
      Destino := Transcoded
    else if FileExists(Transcoded) then
      Destino := Transcoded
    else
      Destino := Dir + Copia;
  end
  else if (Ruta <> '') and FileExists(Ruta) and
          (not SameText(ExtractFileName(Ruta), ArchivoFondo)) then
    Destino := Ruta;

  if Destino = '' then
  begin
    // El escritorio original era un color liso: quitar el fondo.
    FijarFondoRegistro('', Estilo, Mosaico);
    SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, nil,
      SPIF_UPDATEINIFILE or SPIF_SENDCHANGE);
    Exit(True);
  end;

  FijarFondoRegistro(Destino, Estilo, Mosaico);
  SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, Pointer(PWideChar(Destino)),
    SPIF_UPDATEINIFILE or SPIF_SENDCHANGE);
  Result := True;
end;

end.
