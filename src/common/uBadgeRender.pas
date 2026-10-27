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
function AnchoDistintivo(const Texto, Fuente: string; Alto: Integer): Integer;
procedure DibujarDistintivo(G: TGPGraphics; const Area: TGPRectF;
  const Estilo: TBadgeStyle);

implementation

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

function AnchoDistintivo(const Texto, Fuente: string; Alto: Integer): Integer;
var
  Bmp: TGPBitmap;
  G: TGPGraphics;
  Fnt: TGPFont;
  Fmt: TGPStringFormat;
  Medida: TGPRectF;
  S, F: string;
  W: Single;
begin
  if Alto < 1 then
    Alto := 1;
  S := Texto;
  if S = '' then
    S := '?';
  F := Fuente;
  if F = '' then
    F := 'Segoe UI';

  Bmp := TGPBitmap.Create(1, 1, PixelFormat32bppARGB);
  try
    G := TGPGraphics.Create(Bmp);
    try
      Fnt := TGPFont.Create(WideString(F), Alto * 0.62, FontStyleBold, UnitPixel);
      try
        Fmt := TGPStringFormat.Create;
        try
          Fmt.SetFormatFlags(Integer(StringFormatFlagsNoWrap));
          Fmt.SetAlignment(StringAlignmentCenter);
          Fmt.SetLineAlignment(StringAlignmentCenter);
          G.MeasureString(WideString(S), Length(S), Fnt,
            RF(0, 0, 100000, 100000), Fmt, Medida);
          W := Medida.Width + Alto * 0.40;
          if W < Alto then
            W := Alto;
          if Length(S) <= 1 then
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

procedure DibujarDistintivo(G: TGPGraphics; const Area: TGPRectF;
  const Estilo: TBadgeStyle);
var
  Ancho, Alto, Inset, PenW, A1, A2, FontSize, Factor, MaxW, MaxH: Single;
  BordeA, AlphaLetra: Integer;
  R, TextR, Medida: TGPRectF;
  Path: TGPGraphicsPath;
  Br: TGPLinearGradientBrush;
  Pen: TGPPen;
  Fnt: TGPFont;
  Fmt: TGPStringFormat;
  Sombra, PincelTexto: TGPSolidBrush;
  Fuente, Texto: string;
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

  Fmt := TGPStringFormat.Create;
  try
    Fmt.SetAlignment(StringAlignmentCenter);
    Fmt.SetLineAlignment(StringAlignmentCenter);
    Fmt.SetFormatFlags(Integer(StringFormatFlagsNoWrap));

    TextR := RF(Area.X, Area.Y + Alto * 0.02, Ancho, Alto);
    FontSize := Alto * 0.62;
    Fnt := TGPFont.Create(WideString(Fuente), FontSize, FontStyleBold, UnitPixel);
    try
      // Medir con un rect grande: si se mide con el rect del cartel, GDI+
      // devuelve la anchura recortada (no la real), el factor de ajuste sale 1
      // y DrawString corta los ultimos caracteres.
      G.MeasureString(WideString(Texto), Length(Texto), Fnt,
        RF(Area.X, Area.Y, Ancho * 10, Alto * 10), Fmt, Medida);

      MaxW := Ancho - Inset * 2 - Alto * 0.08;
      MaxH := Alto - Inset * 2 - Alto * 0.04;
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
          RF(Area.X, Area.Y + Alto * 0.05, Ancho, Alto), Fmt, Sombra);
      finally
        Sombra.Free;
      end;

      AlphaLetra := Min(255, Round(Estilo.OpacidadLetra * 255));
      PincelTexto := TGPSolidBrush.Create(ArgbDe(Estilo.ColorTexto, Byte(AlphaLetra)));
      try
        G.DrawString(WideString(Texto), Length(Texto), Fnt, TextR, Fmt, PincelTexto);
      finally
        PincelTexto.Free;
      end;
    finally
      Fnt.Free;
    end;
  finally
    Fmt.Free;
  end;
end;

end.
