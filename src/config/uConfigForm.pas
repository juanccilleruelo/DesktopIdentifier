unit uConfigForm;

{ Ventana de configuracion (VCL, toda en codigo). }

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, System.Math,
  System.UITypes,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  Vcl.Samples.Spin, Vcl.Dialogs, Vcl.Graphics,
  Winapi.GDIPAPI, Winapi.GDIPOBJ,
  uPaths, uSettings, uUtils, uBadgeRender, uBandRender, uInstall;

type
  TConfigForm = class(TForm)
  private
    FHeader: TPanel;
    FLblTitulo: TLabel;
    FLblSub: TLabel;
    FRbA: TRadioButton;
    FRbB: TRadioButton;
    FSwatch: TPanel;
    FLblHex: TLabel;
    FBtnColor: TButton;
    FSeTamano: TSpinEdit;
    FTbOpacidad: TTrackBar;
    FLblPorc: TLabel;
    FChkBanda: TCheckBox;
    FChkLetraBanda: TCheckBox;
    FPbPreview: TPaintBox;
    FLblInstalacion: TLabel;
    FLblEstado: TLabel;
    FBtnInstalar: TButton;
    FBtnAplicar: TButton;
    FBtnDesinstalar: TButton;
    FBtnCerrarCartel: TButton;
    FBtnCerrar: TButton;
    FColor: TRgb;
    FColorPersonalizado: Boolean;
    FAjustes: TSettings;
    procedure CrearControles;
    procedure ActualizarVista;
    procedure PintarVista(Sender: TObject);
    procedure CambiarColor(Sender: TObject);
    procedure LetraCambiada(Sender: TObject);
    procedure CambioTamano(Sender: TObject);
    procedure CambioOpacidad(Sender: TObject);
    procedure CambioBanda(Sender: TObject);
    procedure InstalarClick(Sender: TObject);
    procedure AplicarClick(Sender: TObject);
    procedure DesinstalarClick(Sender: TObject);
    procedure CerrarCartelClick(Sender: TObject);
    procedure CerrarVentana(Sender: TObject);
    procedure RefrescarEstadoInstalacion;
    procedure MostrarMensaje(const Texto: string; EsError: Boolean);
    function LetraSeleccionada: string;
    function AjustesDeUi: TSettings;
    function EstiloActual: TBadgeStyle;
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

function RgbATColor(C: TRgb): TColor;
begin
  Result := TColor(((C and $FF) shl 16) or (C and $FF00) or ((C shr 16) and $FF));
end;

function TColorARgb(C: TColor): TRgb;
var
  V: Longint;
begin
  V := C;
  Result := RgbOf(Byte(V and $FF), Byte((V shr 8) and $FF), Byte((V shr 16) and $FF));
end;

constructor TConfigForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner, 0);

  Caption := 'DesktopIdentifier - Configuración';
  BorderStyle := bsDialog;
  ClientWidth := 540;
  ClientHeight := 676;
  Position := poScreenCenter;
  Font.Name := 'Segoe UI';
  Font.Size := 9;

  FAjustes := AjustesEnUso;
  FColor := FAjustes.Color;
  FColorPersonalizado := not SameText(RgbAHex(FColor),
    RgbAHex(ColorPorTexto(FAjustes.Texto)));

  CrearControles;
  ActualizarVista;
  RefrescarEstadoInstalacion;
  MostrarMensaje('El cartel no bloquea los clics: puedes pulsar y escribir a través de él.', False);
end;

procedure TConfigForm.CrearControles;
var
  L: TLabel;
begin
  FHeader := TPanel.Create(Self);
  FHeader.Parent := Self;
  FHeader.Align := alTop;
  FHeader.Height := 64;
  FHeader.BevelOuter := bvNone;
  FHeader.Color := RgbATColor(FColor);
  FHeader.StyleElements := [];

  FLblTitulo := TLabel.Create(Self);
  FLblTitulo.Parent := FHeader;
  FLblTitulo.Caption := 'DesktopIdentifier';
  FLblTitulo.Font.Name := 'Segoe UI';
  FLblTitulo.Font.Size := 16;
  FLblTitulo.Font.Style := [fsBold];
  FLblTitulo.Font.Color := clWhite;
  FLblTitulo.Transparent := True;
  FLblTitulo.SetBounds(20, 8, 320, 30);

  FLblSub := TLabel.Create(Self);
  FLblSub.Parent := FHeader;
  FLblSub.Caption := 'Marca visual para distinguir esta máquina de la otra';
  FLblSub.Font.Name := 'Segoe UI';
  FLblSub.Font.Size := 9;
  FLblSub.Font.Color := RGB(232, 232, 232);
  FLblSub.Transparent := True;
  FLblSub.SetBounds(21, 38, 460, 18);

  L := TLabel.Create(Self);
  L.Parent := Self;
  L.Caption := 'Esta máquina es:';
  L.SetBounds(24, 80, 200, 18);

  FRbA := TRadioButton.Create(Self);
  FRbA.Parent := Self;
  FRbA.Caption := 'Máquina A';
  FRbA.Font.Name := 'Segoe UI';
  FRbA.Font.Size := 11;
  FRbA.SetBounds(26, 102, 110, 24);
  FRbA.Checked := (FAjustes.Texto = '') or (UpCase(FAjustes.Texto[1]) <> 'B');
  FRbA.OnClick := LetraCambiada;

  FRbB := TRadioButton.Create(Self);
  FRbB.Parent := Self;
  FRbB.Caption := 'Máquina B';
  FRbB.Font.Name := 'Segoe UI';
  FRbB.Font.Size := 11;
  FRbB.SetBounds(160, 102, 110, 24);
  FRbB.Checked := (FAjustes.Texto <> '') and (UpCase(FAjustes.Texto[1]) = 'B');
  FRbB.OnClick := LetraCambiada;

  L := TLabel.Create(Self);
  L.Parent := Self;
  L.Caption := 'Color de la banda y del cartel:';
  L.SetBounds(24, 138, 300, 18);

  FSwatch := TPanel.Create(Self);
  FSwatch.Parent := Self;
  FSwatch.SetBounds(24, 160, 54, 30);
  FSwatch.BevelOuter := bvNone;
  FSwatch.Color := RgbATColor(FColor);
  FSwatch.StyleElements := [];

  FLblHex := TLabel.Create(Self);
  FLblHex.Parent := Self;
  FLblHex.Caption := RgbAHex(FColor);
  FLblHex.Font.Name := 'Consolas';
  FLblHex.Font.Size := 10;
  FLblHex.Font.Style := [fsBold];
  FLblHex.SetBounds(88, 166, 80, 20);

  FBtnColor := TButton.Create(Self);
  FBtnColor.Parent := Self;
  FBtnColor.Caption := 'Cambiar color...';
  FBtnColor.SetBounds(176, 158, 120, 32);
  FBtnColor.OnClick := CambiarColor;

  L := TLabel.Create(Self);
  L.Parent := Self;
  L.Caption := 'Tamaño del cartel:';
  L.SetBounds(24, 208, 150, 18);

  FSeTamano := TSpinEdit.Create(Self);
  FSeTamano.Parent := Self;
  FSeTamano.MinValue := 90;
  FSeTamano.MaxValue := 280;
  FSeTamano.Increment := 10;
  FSeTamano.Value := FAjustes.Tamano;
  FSeTamano.SetBounds(150, 204, 70, 24);
  FSeTamano.OnChange := CambioTamano;

  L := TLabel.Create(Self);
  L.Parent := Self;
  L.Caption := 'px';
  L.SetBounds(226, 208, 30, 18);

  L := TLabel.Create(Self);
  L.Parent := Self;
  L.Caption := 'Transparencia del panel:';
  L.SetBounds(24, 242, 200, 18);

  FTbOpacidad := TTrackBar.Create(Self);
  FTbOpacidad.Parent := Self;
  FTbOpacidad.Min := 10;
  FTbOpacidad.Max := 60;
  FTbOpacidad.Frequency := 5;
  FTbOpacidad.SetBounds(22, 260, 330, 36);
  FTbOpacidad.Position := Round(FAjustes.OpacidadPanel * 100);
  FTbOpacidad.OnChange := CambioOpacidad;

  FLblPorc := TLabel.Create(Self);
  FLblPorc.Parent := Self;
  FLblPorc.Caption := IntToStr(FTbOpacidad.Position) + ' %';
  FLblPorc.Font.Style := [fsBold];
  FLblPorc.Font.Size := 10;
  FLblPorc.SetBounds(360, 266, 50, 20);

  L := TLabel.Create(Self);
  L.Parent := Self;
  L.Caption := '(más % = más opaco)';
  L.Font.Color := RGB(110, 110, 110);
  L.SetBounds(402, 268, 130, 18);

  FChkBanda := TCheckBox.Create(Self);
  FChkBanda.Parent := Self;
  FChkBanda.Caption := 'Poner la banda de color en el escritorio (fondo de pantalla)';
  FChkBanda.SetBounds(24, 306, 460, 22);
  FChkBanda.Checked := FAjustes.BandaActiva;
  FChkBanda.OnClick := CambioBanda;

  FChkLetraBanda := TCheckBox.Create(Self);
  FChkLetraBanda.Parent := Self;
  FChkLetraBanda.Caption := 'Mostrar también la letra en la banda';
  FChkLetraBanda.SetBounds(24, 332, 400, 22);
  FChkLetraBanda.Checked := FAjustes.BandaTexto <> '';
  FChkLetraBanda.OnClick := CambioBanda;

  FPbPreview := TPaintBox.Create(Self);
  FPbPreview.Parent := Self;
  FPbPreview.SetBounds(24, 362, 492, 156);
  FPbPreview.OnPaint := PintarVista;

  FLblInstalacion := TLabel.Create(Self);
  FLblInstalacion.Parent := Self;
  FLblInstalacion.Caption := 'Sin instalar';
  FLblInstalacion.Font.Style := [fsBold];
  FLblInstalacion.AutoSize := False;
  FLblInstalacion.SetBounds(24, 526, 492, 18);

  FLblEstado := TLabel.Create(Self);
  FLblEstado.Parent := Self;
  FLblEstado.Caption := '';
  FLblEstado.WordWrap := True;
  FLblEstado.AutoSize := False;
  FLblEstado.SetBounds(24, 546, 492, 38);

  FBtnInstalar := TButton.Create(Self);
  FBtnInstalar.Parent := Self;
  FBtnInstalar.Caption := 'Instalar';
  FBtnInstalar.SetBounds(24, 592, 110, 32);
  FBtnInstalar.OnClick := InstalarClick;

  FBtnAplicar := TButton.Create(Self);
  FBtnAplicar.Parent := Self;
  FBtnAplicar.Caption := 'Aplicar';
  FBtnAplicar.SetBounds(144, 592, 100, 32);
  FBtnAplicar.OnClick := AplicarClick;

  FBtnDesinstalar := TButton.Create(Self);
  FBtnDesinstalar.Parent := Self;
  FBtnDesinstalar.Caption := 'Desinstalar';
  FBtnDesinstalar.SetBounds(254, 592, 110, 32);
  FBtnDesinstalar.OnClick := DesinstalarClick;

  FBtnCerrarCartel := TButton.Create(Self);
  FBtnCerrarCartel.Parent := Self;
  FBtnCerrarCartel.Caption := 'Cerrar el cartel';
  FBtnCerrarCartel.SetBounds(374, 592, 142, 32);
  FBtnCerrarCartel.OnClick := CerrarCartelClick;

  FBtnCerrar := TButton.Create(Self);
  FBtnCerrar.Parent := Self;
  FBtnCerrar.Caption := 'Cerrar';
  FBtnCerrar.Cancel := True;
  FBtnCerrar.SetBounds(424, 632, 90, 32);
  FBtnCerrar.OnClick := CerrarVentana;
end;

function TConfigForm.LetraSeleccionada: string;
begin
  if FRbB.Checked then
    Result := 'B'
  else
    Result := 'A';
end;

function TConfigForm.AjustesDeUi: TSettings;
begin
  Result := FAjustes;
  Result.Texto := LetraSeleccionada;
  Result.Color := FColor;
  Result.BandaColor := FColor;
  Result.Tamano := FSeTamano.Value;
  Result.OpacidadPanel := FTbOpacidad.Position / 100;
  Result.BandaActiva := FChkBanda.Checked;
  if FChkLetraBanda.Checked then
    Result.BandaTexto := LetraSeleccionada
  else
    Result.BandaTexto := '';
  Result := AjustesValidos(Result);
end;

function TConfigForm.EstiloActual: TBadgeStyle;
begin
  Result.Texto := LetraSeleccionada;
  Result.Color := FColor;
  Result.OpacidadPanel := FTbOpacidad.Position / 100;
  Result.OpacidadLetra := FAjustes.OpacidadLetra;
  Result.Esquinas := FAjustes.Esquinas;
  Result.Fuente := FAjustes.Fuente;
  Result.Tamano := FSeTamano.Value;
end;

procedure TConfigForm.ActualizarVista;
begin
  FHeader.Color := RgbATColor(FColor);
  FSwatch.Color := RgbATColor(FColor);
  FLblHex.Caption := RgbAHex(FColor);
  FLblPorc.Caption := IntToStr(FTbOpacidad.Position) + ' %';
  Caption := 'DesktopIdentifier - Configuración - Máquina ' + LetraSeleccionada;
  FPbPreview.Invalidate;
end;

procedure TConfigForm.PintarVista(Sender: TObject);
var
  G: TGPGraphics;
  R: TRect;
  Ancho, Alto, BandH, Bt, Bx, By: Integer;
  Br: TGPLinearGradientBrush;
  Estilo: TBadgeStyle;
begin
  R := FPbPreview.ClientRect;
  Ancho := R.Width;
  Alto := R.Height;
  if (Ancho <= 0) or (Alto <= 0) then
    Exit;

  G := TGPGraphics.Create(FPbPreview.Canvas.Handle);
  try
    G.SetSmoothingMode(SmoothingModeAntiAlias);
    G.SetPixelOffsetMode(PixelOffsetModeHighQuality);
    G.SetTextRenderingHint(TextRenderingHintAntiAliasGridFit);

    Br := TGPLinearGradientBrush.Create(RF(0, 0, Ancho, Alto),
      MakeColor(255, 30, 32, 42), MakeColor(255, 72, 76, 96), 35);
    try
      G.FillRectangle(Br, RF(0, 0, Ancho, Alto));
    finally
      Br.Free;
    end;

    if FChkBanda.Checked then
    begin
      BandH := Round(Alto * FAjustes.BandaAlto);
      if BandH < 8 then
        BandH := 8;
      if FChkLetraBanda.Checked then
        DibujarBanda(G, RF(0, 0, Ancho, BandH), FColor, LetraSeleccionada,
          FAjustes.BandaColorTexto)
      else
        DibujarBanda(G, RF(0, 0, Ancho, BandH), FColor, '',
          FAjustes.BandaColorTexto);
    end;

    Estilo := EstiloActual;
    Bt := Round(60 * FSeTamano.Value / 170);
    if Bt < 36 then
      Bt := 36;
    if Bt > 90 then
      Bt := 90;
    Bx := Ancho - Bt - 14;
    By := Alto - Bt - 12;

    G.SetSmoothingMode(SmoothingModeAntiAlias);
    DibujarDistintivo(G, RF(Bx, By, Bt, Bt), Estilo);
  finally
    G.Free;
  end;
end;

procedure TConfigForm.CambiarColor(Sender: TObject);
var
  Dlg: TColorDialog;
begin
  Dlg := TColorDialog.Create(Self);
  try
    Dlg.Color := RgbATColor(FColor);
    Dlg.Options := Dlg.Options + [cdFullOpen];
    if Dlg.Execute then
    begin
      FColor := TColorARgb(Dlg.Color);
      FColorPersonalizado := True;
      ActualizarVista;
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TConfigForm.LetraCambiada(Sender: TObject);
begin
  if not FColorPersonalizado then
    FColor := ColorPorTexto(LetraSeleccionada);
  ActualizarVista;
end;

procedure TConfigForm.CambioTamano(Sender: TObject);
begin
  ActualizarVista;
end;

procedure TConfigForm.CambioOpacidad(Sender: TObject);
begin
  ActualizarVista;
end;

procedure TConfigForm.CambioBanda(Sender: TObject);
begin
  FPbPreview.Invalidate;
end;

procedure TConfigForm.MostrarMensaje(const Texto: string; EsError: Boolean);
begin
  FLblEstado.Caption := Texto;
  if EsError then
    FLblEstado.Font.Color := RGB(170, 30, 30)
  else
    FLblEstado.Font.Color := RGB(20, 120, 60);
end;

procedure TConfigForm.RefrescarEstadoInstalacion;
var
  E: TEstadoInstalacion;
begin
  E := EstadoInstalacion;
  if E.HostInstalado then
  begin
    FLblInstalacion.Font.Color := RGB(20, 110, 60);
    FLblInstalacion.Caption := DescripcionEstado(E);
  end
  else
  begin
    FLblInstalacion.Font.Color := RGB(150, 90, 0);
    FLblInstalacion.Caption := 'Sin instalar · pulsa Instalar para activar el cartel';
  end;
end;

procedure TConfigForm.InstalarClick(Sender: TObject);
var
  Mensaje: string;
begin
  FBtnInstalar.Enabled := False;
  Screen.Cursor := crHourGlass;
  try
    FAjustes := AjustesDeUi;
    if not Instalar(FAjustes, Mensaje) then
    begin
      MostrarMensaje('Error: ' + Mensaje, True);
      Exit;
    end;
    if not Aplicar(FAjustes, Mensaje) then
    begin
      MostrarMensaje('Instalado, pero no se pudo aplicar: ' + Mensaje, True);
      Exit;
    end;
    MostrarMensaje('Instalado y aplicado a las ' + TimeToStr(Now) + '.', False);
  finally
    Screen.Cursor := crDefault;
    FBtnInstalar.Enabled := True;
    RefrescarEstadoInstalacion;
  end;
end;

procedure TConfigForm.AplicarClick(Sender: TObject);
var
  Mensaje: string;
begin
  if not EstadoInstalacion.HostInstalado then
  begin
    MostrarMensaje('Sin instalar: pulsa Instalar antes de aplicar.', True);
    Exit;
  end;

  FBtnAplicar.Enabled := False;
  Screen.Cursor := crHourGlass;
  try
    FAjustes := AjustesDeUi;
    if Aplicar(FAjustes, Mensaje) then
      MostrarMensaje(Mensaje, False)
    else
      MostrarMensaje('Error: ' + Mensaje, True);
  finally
    Screen.Cursor := crDefault;
    FBtnAplicar.Enabled := True;
    RefrescarEstadoInstalacion;
  end;
end;

procedure TConfigForm.DesinstalarClick(Sender: TObject);
var
  Dlg: TTaskDialog;
  Conservar: Boolean;
  Mensaje: string;
begin
  Dlg := TTaskDialog.Create(Self);
  try
    Dlg.Caption := 'Desinstalar DesktopIdentifier';
    Dlg.Title := 'Desinstalar';
    Dlg.Text := 'Se quitará el cartel, el arranque automático y la banda, ' +
      'y se restaurará el fondo de pantalla original.';
    Dlg.CommonButtons := [tcbYes, tcbNo];
    Dlg.DefaultButton := tcbNo;
    Dlg.VerificationText := 'Conservar la configuración';
    Dlg.Flags := Dlg.Flags + [tfVerificationFlagChecked];
    if not Dlg.Execute then
      Exit;
    if Dlg.ModalResult <> mrYes then
      Exit;
    Conservar := tfVerificationFlagChecked in Dlg.Flags;
  finally
    Dlg.Free;
  end;

  Screen.Cursor := crHourGlass;
  try
    if Desinstalar(Conservar, Mensaje) then
      MostrarMensaje(Mensaje, False)
    else
      MostrarMensaje('Error: ' + Mensaje, True);
  finally
    Screen.Cursor := crDefault;
    RefrescarEstadoInstalacion;
  end;
end;

procedure TConfigForm.CerrarCartelClick(Sender: TObject);
begin
  AvisarHost(MensajeSalir);
  Sleep(150);
  MostrarMensaje('Petición de cierre enviada al cartel.', False);
  RefrescarEstadoInstalacion;
end;

procedure TConfigForm.CerrarVentana(Sender: TObject);
begin
  Close;
end;

end.
