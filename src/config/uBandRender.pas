unit uBandRender;

{ Dibujo de la banda superior con GDI+. Solo lo usa el configurador: el host
  no compone el fondo, solo pinta el cartel. }

interface

uses
  Winapi.Windows, System.SysUtils, System.Math,
  Winapi.GDIPAPI, Winapi.GDIPOBJ, uUtils, uBadgeRender;

procedure DibujarBanda(G: TGPGraphics; const Area: TGPRectF; Color: TRgb;
  const Texto: string; ColorTexto: TRgb; const Alineacion: string);

implementation

procedure DibujarBanda(G: TGPGraphics; const Area: TGPRectF; Color: TRgb;
  const Texto: string; ColorTexto: TRgb; const Alineacion: string);
var
  Br: TGPLinearGradientBrush;
  Pen: TGPPen;
  Fnt: TGPFont;
  Fmt: TGPStringFormat;
  Pincel: TGPSolidBrush;
  FontSize, Margen, X, AnchoTexto, AnchoDisponible, Factor: Single;
  AlineacionGdi: StringAlignment;
  Medida: TGPRectF;
begin
  if (Area.Width <= 0) or (Area.Height <= 0) then
    Exit;

  Br := TGPLinearGradientBrush.Create(Area,
    MezclaArgb(Color, RgbBlanco, 0.16, 255),
    MezclaArgb(Color, RgbNegro, 0.34, 255), 90);
  try
    G.FillRectangle(Br, Area);
  finally
    Br.Free;
  end;

  Pen := TGPPen.Create(MezclaArgb(Color, RgbBlanco, 0.60, 255), 2);
  try
    G.DrawLine(Pen, Area.X, Area.Y + Area.Height - 1,
      Area.X + Area.Width, Area.Y + Area.Height - 1);
  finally
    Pen.Free;
  end;

  if Texto = '' then
    Exit;

  FontSize := Max(12, Area.Height * 0.58);
  Margen := Max(12, Area.Height * 0.55);
  AnchoDisponible := Area.Width - Margen * 2;
  if SameText(Alineacion, 'centro') then
  begin
    AlineacionGdi := StringAlignmentCenter;
    X := Area.X + Margen;
    AnchoTexto := Area.Width - Margen * 2;
  end
  else if SameText(Alineacion, 'izquierda') then
  begin
    AlineacionGdi := StringAlignmentNear;
    X := Area.X + Margen;
    AnchoTexto := Area.Width - Margen * 2;
  end
  else
  begin
    AlineacionGdi := StringAlignmentFar;
    X := Area.X;
    AnchoTexto := Area.Width - Margen;
  end;

  Fnt := TGPFont.Create('Segoe UI', FontSize, FontStyleBold, UnitPixel);
  try
    Fmt := TGPStringFormat.Create;
    try
      Fmt.SetAlignment(AlineacionGdi);
      Fmt.SetLineAlignment(StringAlignmentCenter);

      // Si el texto no cabe a lo ancho, reducir la fuente. Se mide con un rect
      // grande para que GDI+ no devuelva una anchura recortada.
      if AnchoDisponible > 0 then
      begin
        G.MeasureString(WideString(Texto), Length(Texto), Fnt,
          RF(Area.X, Area.Y, Area.Width * 10, Area.Height * 10), Fmt, Medida);
        if (Medida.Width > AnchoDisponible) and (Medida.Width > 0) then
        begin
          Factor := AnchoDisponible / Medida.Width;
          Fnt.Free;
          FontSize := Max(6, FontSize * Factor);
          Fnt := TGPFont.Create('Segoe UI', FontSize, FontStyleBold, UnitPixel);
        end;
      end;

      Pincel := TGPSolidBrush.Create(ArgbDe(ColorTexto, 205));
      try
        G.DrawString(WideString(Texto), Length(Texto), Fnt,
          RF(X, Area.Y, AnchoTexto, Area.Height), Fmt, Pincel);
      finally
        Pincel.Free;
      end;
    finally
      Fmt.Free;
    end;
  finally
    Fnt.Free;
  end;
end;

end.
