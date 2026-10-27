unit uBandRender;

{ Dibujo de la banda superior con GDI+. Solo lo usa el configurador: el host
  no compone el fondo, solo pinta el cartel. }

interface

uses
  Winapi.Windows, System.SysUtils, System.Math,
  Winapi.GDIPAPI, Winapi.GDIPOBJ, uUtils, uBadgeRender;

procedure DibujarBanda(G: TGPGraphics; const Area: TGPRectF; Color: TRgb;
  const Texto: string; ColorTexto: TRgb; const Alineacion: string);
procedure DibujarTextoEscritorio(G: TGPGraphics; const Area: TGPRectF;
  const Grande, Pequeno, Fuente: string; Tamano: Integer);

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

procedure DibujarTextoEscritorio(G: TGPGraphics; const Area: TGPRectF;
  const Grande, Pequeno, Fuente: string; Tamano: Integer);
var
  FntGrande, FntPequeno: TGPFont;
  Fmt: TGPStringFormat;
  MedidaGrande, MedidaPequeno: TGPRectF;
  GrandeT, PequenoT, F: string;
  GrandeSize, PequenoSize, Factor, Top, Gap, SombraOffset: Single;
  Pincel, Sombra: TGPSolidBrush;
begin
  GrandeT := Trim(Grande);
  PequenoT := Trim(Pequeno);
  if (GrandeT = '') and (PequenoT = '') then
    Exit;
  if (Area.Width <= 0) or (Area.Height <= 0) then
    Exit;
  if Tamano < 8 then
    Tamano := 8;

  F := Fuente;
  if F = '' then
    F := 'Segoe UI';
  GrandeSize := Tamano;
  PequenoSize := Max(8, Round(Tamano * 0.42));
  Gap := Max(6, Round(Tamano * 0.32));
  SombraOffset := Max(1, Round(Tamano * 0.035));

  Fmt := TGPStringFormat.Create;
  try
    Fmt.SetAlignment(StringAlignmentCenter);
    Fmt.SetLineAlignment(StringAlignmentCenter);
    Fmt.SetFormatFlags(Integer(StringFormatFlagsNoWrap));

    FntGrande := TGPFont.Create(WideString(F), GrandeSize, FontStyleBold, UnitPixel);
    try
      G.MeasureString(WideString(GrandeT), Length(GrandeT), FntGrande,
        RF(Area.X, Area.Y, Area.Width * 10, Area.Height * 10), Fmt, MedidaGrande);
      if (MedidaGrande.Width > Area.Width * 0.88) and (MedidaGrande.Width > 0) then
      begin
        Factor := Area.Width * 0.88 / MedidaGrande.Width;
        FntGrande.Free;
        GrandeSize := Max(8, GrandeSize * Factor);
        FntGrande := TGPFont.Create(WideString(F), GrandeSize, FontStyleBold, UnitPixel);
        G.MeasureString(WideString(GrandeT), Length(GrandeT), FntGrande,
          RF(Area.X, Area.Y, Area.Width * 10, Area.Height * 10), Fmt, MedidaGrande);
      end;

      FntPequeno := TGPFont.Create(WideString(F), PequenoSize, FontStyleRegular, UnitPixel);
      try
        G.MeasureString(WideString(PequenoT), Length(PequenoT), FntPequeno,
          RF(Area.X, Area.Y, Area.Width * 10, Area.Height * 10), Fmt, MedidaPequeno);
        if (MedidaPequeno.Width > Area.Width * 0.82) and (MedidaPequeno.Width > 0) then
        begin
          Factor := Area.Width * 0.82 / MedidaPequeno.Width;
          FntPequeno.Free;
          PequenoSize := Max(7, PequenoSize * Factor);
          FntPequeno := TGPFont.Create(WideString(F), PequenoSize, FontStyleRegular, UnitPixel);
          G.MeasureString(WideString(PequenoT), Length(PequenoT), FntPequeno,
            RF(Area.X, Area.Y, Area.Width * 10, Area.Height * 10), Fmt, MedidaPequeno);
        end;

        if GrandeT <> '' then
        begin
          Sombra := TGPSolidBrush.Create(MakeColor(160, 0, 0, 0));
          try
            G.DrawString(WideString(GrandeT), Length(GrandeT), FntGrande,
              RF(Area.X + SombraOffset, Area.Y + SombraOffset, Area.Width, Area.Height),
              Fmt, Sombra);
          finally
            Sombra.Free;
          end;
          Pincel := TGPSolidBrush.Create(ArgbDe(RgbBlanco, 238));
          try
            G.DrawString(WideString(GrandeT), Length(GrandeT), FntGrande,
              RF(Area.X, Area.Y, Area.Width, Area.Height), Fmt, Pincel);
          finally
            Pincel.Free;
          end;
        end;

        if PequenoT <> '' then
        begin
          if GrandeT <> '' then
            Top := Area.Y + Area.Height / 2 + MedidaGrande.Height / 2 + Gap
          else
            Top := Area.Y + Area.Height / 2 - MedidaPequeno.Height / 2;

          Sombra := TGPSolidBrush.Create(MakeColor(160, 0, 0, 0));
          try
            G.DrawString(WideString(PequenoT), Length(PequenoT), FntPequeno,
              RF(Area.X + SombraOffset, Top + SombraOffset, Area.Width,
                MedidaPequeno.Height * 1.6), Fmt, Sombra);
          finally
            Sombra.Free;
          end;
          Pincel := TGPSolidBrush.Create(ArgbDe(RgbBlanco, 225));
          try
            G.DrawString(WideString(PequenoT), Length(PequenoT), FntPequeno,
              RF(Area.X, Top, Area.Width, MedidaPequeno.Height * 1.6), Fmt, Pincel);
          finally
            Pincel.Free;
          end;
        end;
      finally
        FntPequeno.Free;
      end;
    finally
      FntGrande.Free;
    end;
  finally
    Fmt.Free;
  end;
end;

end.
