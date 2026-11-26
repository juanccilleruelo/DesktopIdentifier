unit uBadgeRender;

{ Dibujo del cartel con GDI+, compartido por el host (ventana real) y por
  el configurador (vista previa). Sin dependencias de VCL. }

interface

uses
  Winapi.Windows, System.SysUtils, System.Math,
  Winapi.GDIPAPI, Winapi.GDIPOBJ, uUtils;

type
  TBadgeStyle = record
    Texto: string;
    TextoSecundario: string;
    Color: TRgb;
    ColorTexto: TRgb;
    OpacidadPanel: Double;
    OpacidadLetra: Double;
    Esquinas: Double;
    Fuente: string;
    Tamano: Integer;
  end;

function RF(X, Y, Ancho, Alto: Single): TGPRectF;
function RoundedRectPath(const R: TGPRectF; Radio: Single): TGPGraphicsPath;
function AnchoDistintivo(const Texto, TextoSecundario, Fuente: string;
  Alto: Integer): Integer;
function AltoDistintivo(AltoBase: Integer; const TextoSecundario: string): Integer;
procedure DibujarDistintivo(G: TGPGraphics; const Area: TGPRectF;
  const Estilo: TBadgeStyle);

implementation

const
  ESCALA_SECUNDARIA = 0.30;
  FUENTE_SECUNDARIA = 'Consolas';
  DESPLAZA_X: array[0..7] of Integer = (-1, -1, -1, 0, 0, 1, 1, 1);
  DESPLAZA_Y: array[0..7] of Integer = (-1, 0, 1, -1, 1, -1, 0, 1);

function RF(X, Y, Ancho, Alto: Single): TGPRectF;
begin
  Result.X := X;
  Result.Y := Y;
  Result.Width := Ancho;
  Result.Height := Alto;
end;

function RoundedRectPath(const R: TGPRectF; Radio: Single): TGPGraphicsPath;
var
  D, MaxR: Single;
begin
  MaxR := Min(R.Width, R.Height) / 2;
  if Radio > MaxR then
    Radio := MaxR;
  if Radio < 1 then
    Radio := 1;
  D := Radio * 2;

  Result := TGPGraphicsPath.Create;
  Result.AddArc(R.X, R.Y, D, D, 180, 90);
  Result.AddArc(R.X + R.Width - D, R.Y, D, D, 270, 90);
  Result.AddArc(R.X + R.Width - D, R.Y + R.Height - D, D, D, 0, 90);
  Result.AddArc(R.X, R.Y + R.Height - D, D, D, 90, 90);
  Result.CloseFigure;
end;

function AnchoDistintivo(const Texto, TextoSecundario, Fuente: string;
  Alto: Integer): Integer;
var
  Bmp: TGPBitmap;
  G: TGPGraphics;
  Fnt, Fnt2: TGPFont;
  Fmt: TGPStringFormat;
  Medida, Medida2: TGPRectF;
  S, S2, F: string;
  W, W2, MainFont: Single;
begin
  if Alto < 1 then
    Alto := 1;
  S := Texto;
  if S = '' then
    S := '?';
  S2 := Trim(TextoSecundario);
  F := Fuente;
  if F = '' then
    F := 'Segoe UI';

  Bmp := TGPBitmap.Create(1, 1, PixelFormat32bppARGB);
  try
    G := TGPGraphics.Create(Bmp);
    try
      MainFont := Alto * 0.62;
      if S2 <> '' then
        MainFont := Alto * 0.57;
      Fnt := TGPFont.Create(WideString(F), MainFont, FontStyleBold, UnitPixel);
      try
        Fmt := TGPStringFormat.Create;
        try
          Fmt.SetFormatFlags(Integer(StringFormatFlagsNoWrap));
          Fmt.SetAlignment(StringAlignmentCenter);
          Fmt.SetLineAlignment(StringAlignmentCenter);
          G.MeasureString(WideString(S), Length(S), Fnt,
            RF(0, 0, 100000, 100000), Fmt, Medida);
          W := Medida.Width + Alto * 0.30;
          if W < Alto then
            W := Alto;

          if S2 <> '' then
          begin
            Fnt2 := TGPFont.Create(WideString(FUENTE_SECUNDARIA),
              Max(8, MainFont * ESCALA_SECUNDARIA), FontStyleRegular, UnitPixel);
            try
              G.MeasureString(WideString(S2), Length(S2), Fnt2,
                RF(0, 0, 100000, 100000), Fmt, Medida2);
              W2 := Medida2.Width + Alto * 0.30 + Max(4, Alto * 0.03);
              if W2 > W then
                W := W2;
            finally
              Fnt2.Free;
            end;
          end;

          if (S2 = '') and (Length(S) <= 1) then
            Result := Alto
          else
            Result := Ceil(W);
        finally
          Fmt.Free;
        end;
      finally
        Fnt.Free;
      end;
    finally
      G.Free;
    end;
  finally
    Bmp.Free;
  end;
end;

function AltoDistintivo(AltoBase: Integer; const TextoSecundario: string): Integer;
begin
  if AltoBase < 1 then
    AltoBase := 1;
  Result := AltoBase;
end;

procedure DibujarDistintivo(G: TGPGraphics; const Area: TGPRectF;
  const Estilo: TBadgeStyle);
var
  Ancho, Alto, BaseAlto, Inset, PenW, A1, A2, FontSize, Factor, MaxW, MaxH: Single;
  BordeA, AlphaLetra: Integer;
  R, MainR, SecR, Medida: TGPRectF;
  Path: TGPGraphicsPath;
  Br: TGPLinearGradientBrush;
  Pen: TGPPen;
  Fnt, Fnt2: TGPFont;
  Fmt: TGPStringFormat;
  Sombra, PincelTexto, Sombra2, Pincel2, PincelBlanco: TGPSolidBrush;
  Fuente, Texto, Texto2: string;
  SecFontSize, SecLineH, SecShadow, Outline: Single;
  MainFontSize, MainH, TopPad, BottomPad, SecTop: Single;
  I: Integer;
begin
  Ancho := Area.Width;
  Alto := Area.Height;
  if (Ancho <= 0) or (Alto <= 0) then
    Exit;

  Inset := Max(1.5, Alto * 0.018);
  PenW := Max(1.5, Alto * 0.016);
  R := RF(Area.X + Inset, Area.Y + Inset,
    Ancho - Inset * 2, Alto - Inset * 2);

  A1 := Estilo.OpacidadPanel * 255;
  A2 := Estilo.OpacidadPanel * 0.72 * 255;
  if A1 < 0 then
    A1 := 0;
  if A1 > 255 then
    A1 := 255;
  if A2 < 0 then
    A2 := 0;
  if A2 > 255 then
    A2 := 255;

  Path := RoundedRectPath(R, Alto * Estilo.Esquinas);
  try
    Br := TGPLinearGradientBrush.Create(R,
      MezclaArgb(Estilo.Color, RgbBlanco, 0.28, Byte(Round(A1))),
      MezclaArgb(Estilo.Color, RgbNegro, 0.34, Byte(Round(A2))), 90);
    try
      G.FillPath(Br, Path);
    finally
      Br.Free;
    end;

    BordeA := Min(255, Round((Estilo.OpacidadPanel + 0.50) * 255));
    Pen := TGPPen.Create(MezclaArgb(Estilo.Color, RgbBlanco, 0.45, Byte(BordeA)), PenW);
    try
      G.DrawPath(Pen, Path);
    finally
      Pen.Free;
    end;
  finally
    Path.Free;
  end;

  Fuente := Estilo.Fuente;
  if Fuente = '' then
    Fuente := 'Segoe UI';
  Texto := Estilo.Texto;
  if Texto = '' then
    Texto := '?';
  Texto2 := Trim(Estilo.TextoSecundario);
  BaseAlto := Estilo.Tamano;
  if BaseAlto < 1 then
    BaseAlto := Alto;
  SecFontSize := 0;
  BottomPad := 0;

  Fmt := TGPStringFormat.Create;
  try
    Fmt.SetAlignment(StringAlignmentCenter);
    Fmt.SetLineAlignment(StringAlignmentCenter);
    Fmt.SetFormatFlags(Integer(StringFormatFlagsNoWrap));

    MainFontSize := BaseAlto * 0.62;
    if Texto2 <> '' then
    begin
      MainFontSize := BaseAlto * 0.57;
      SecFontSize := Max(8, MainFontSize * ESCALA_SECUNDARIA);
      SecLineH := SecFontSize * 1.3;
      TopPad := Max(1, BaseAlto * 0.005);
      BottomPad := Max(3, BaseAlto * 0.03);
      SecTop := Alto - SecLineH - BottomPad - Max(2, BaseAlto * 0.04);
      MainH := SecTop - TopPad;
      MainR := RF(Area.X, Area.Y + TopPad, Ancho, MainH);
      SecR := RF(Area.X, Area.Y + SecTop, Ancho, SecLineH);
    end
    else
    begin
      MainH := Alto;
      MainR := RF(Area.X, Area.Y + BaseAlto * 0.02, Ancho, Alto);
      SecR := RF(Area.X, Area.Y, 0, 0);
    end;
    FontSize := MainFontSize;

    Fnt := TGPFont.Create(WideString(Fuente), FontSize, FontStyleBold, UnitPixel);
    try
      // Medir con un rect grande: si se mide con el rect del cartel, GDI+
      // devuelve la anchura recortada (no la real), el factor de ajuste sale 1
      // y DrawString corta los ultimos caracteres.
      G.MeasureString(WideString(Texto), Length(Texto), Fnt,
        RF(Area.X, Area.Y, Ancho * 10, Alto * 10), Fmt, Medida);

      MaxW := Ancho - Inset * 2 - Alto * 0.08;
      MaxH := MainH - Inset * 2 - BaseAlto * 0.04;
      Factor := 1;
      if (Medida.Width > MaxW) and (Medida.Width > 0) then
        Factor := MaxW / Medida.Width;
      if (Medida.Height > MaxH) and (Medida.Height > 0) then
        Factor := Min(Factor, MaxH / Medida.Height);
      if Factor < 1 then
      begin
        Fnt.Free;
        FontSize := FontSize * Factor;
        Fnt := TGPFont.Create(WideString(Fuente), FontSize, FontStyleBold, UnitPixel);
      end;

      Sombra := TGPSolidBrush.Create(
        MakeColor(Byte(Round(Estilo.OpacidadLetra * 0.42 * 255)), 0, 0, 0));
      try
        G.DrawString(WideString(Texto), Length(Texto), Fnt,
          RF(Area.X, MainR.Y + BaseAlto * 0.03, Ancho, MainR.Height), Fmt, Sombra);
      finally
        Sombra.Free;
      end;

      AlphaLetra := Min(255, Round(Estilo.OpacidadLetra * 255));
      PincelTexto := TGPSolidBrush.Create(ArgbDe(Estilo.ColorTexto, Byte(AlphaLetra)));
      try
        G.DrawString(WideString(Texto), Length(Texto), Fnt, MainR, Fmt, PincelTexto);
      finally
        PincelTexto.Free;
      end;
    finally
      Fnt.Free;
    end;

    if Texto2 <> '' then
    begin
      Fnt2 := TGPFont.Create(WideString(FUENTE_SECUNDARIA), SecFontSize,
        FontStyleRegular, UnitPixel);
      try
        SecShadow := Max(1.5, SecFontSize * 0.10);
        Outline := Max(1, SecFontSize * 0.06);

        Sombra2 := TGPSolidBrush.Create(
          MakeColor(Byte(Round(Estilo.OpacidadLetra * 0.65 * 255)), 0, 0, 0));
        try
          G.DrawString(WideString(Texto2), Length(Texto2), Fnt2,
            RF(SecR.X + SecShadow, SecR.Y + SecShadow, SecR.Width, SecR.Height),
            Fmt, Sombra2);
        finally
          Sombra2.Free;
        end;

        Pincel2 := TGPSolidBrush.Create(MakeColor(240, 0, 0, 0));
        try
          for I := 0 to 7 do
            G.DrawString(WideString(Texto2), Length(Texto2), Fnt2,
              RF(SecR.X + DESPLAZA_X[I] * Outline,
                 SecR.Y + DESPLAZA_Y[I] * Outline,
                 SecR.Width, SecR.Height), Fmt, Pincel2);
        finally
          Pincel2.Free;
        end;

        PincelBlanco := TGPSolidBrush.Create(ArgbDe(RgbBlanco,
          Byte(Min(255, Round(Estilo.OpacidadLetra * 255)))));
        try
          G.DrawString(WideString(Texto2), Length(Texto2), Fnt2, SecR, Fmt, PincelBlanco);
        finally
          PincelBlanco.Free;
        end;
      finally
        Fnt2.Free;
      end;
    end;
  finally
    Fmt.Free;
  end;
end;

end.
