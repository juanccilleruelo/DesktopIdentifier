unit uConfigForm;

{ Ventana de configuracion (VCL, toda en codigo). }

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, System.Math,
  System.UITypes,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  Vcl.Samples.Spin, Vcl.Dialogs, Vcl.Graphics,
  Winapi.GDIPAPI, Winapi.GDIPOBJ,
  uPaths, uSettings, uUtils, uBadgeRender, uBandRender, uInstall, uVersion,
  Languages;

type
  TConfigForm = class(TForm)
  private
    FHeader: TPanel;
    FLblTitulo: TLabel;
    FLblSub: TLabel;
    FPages: TPageControl;
    FTabCartel: TTabSheet;
    FTabBanda: TTabSheet;
    // Cartel
    FEdTexto: TEdit;
    FSwCartel: TPanel;
    FLblCartelHex: TLabel;
    FBtnCartelColor: TButton;
    FSwTexto: TPanel;
    FLblTextoHex: TLabel;
    FBtnTextoColor: TButton;
    FSeTamano: TSpinEdit;
    FTbOpacidad: TTrackBar;
    FLblOpacidad: TLabel;
    FTbOpacidadTexto: TTrackBar;
    FLblOpacidadTexto: TLabel;
    FTbEsquinas: TTrackBar;
    FLblEsquinas: TLabel;
    FSeMargenDer: TSpinEdit;
    FSeMargenInf: TSpinEdit;
    // Banda
    FChkBanda: TCheckBox;
    FSwBanda: TPanel;
    FLblBandaHex: TLabel;
    FBtnBandaColor: TButton;
    FSwTextoBanda: TPanel;
    FLblTextoBandaHex: TLabel;
    FBtnTextoBandaColor: TButton;
    FTbAlto: TTrackBar;
    FLblAlto: TLabel;
    FEdTextoBanda: TEdit;
    FCbAlineacion: TComboBox;
    // Vista previa y estado
    FPbPreview: TPaintBox;
    FLblInstalacion: TLabel;
    FLblEstado: TLabel;
    FBtnInstalar: TButton;
    FBtnAplicar: TButton;
    FBtnDesinstalar: TButton;
    FBtnReaplicar: TButton;
    FBtnCerrarCartel: TButton;
    FBtnCerrar: TButton;
    // Estado
    FColor: TRgb;
    FColorTexto: TRgb;
    FColorBanda: TRgb;
    FColorTextoBanda: TRgb;
    FColorPersonalizado: Boolean;
    FAjustes: TSettings;
    FHIconSmall: HICON;
    procedure CrearControles;
    procedure CrearTabCartel;
    procedure CrearTabBanda;
    procedure ActualizarVista;
    procedure PintarVista(Sender: TObject);
    procedure TextoCambiado(Sender: TObject);
    procedure CambiarColorCartel(Sender: TObject);
    procedure CambiarColorTexto(Sender: TObject);
    procedure CambiarColorBanda(Sender: TObject);
    procedure CambiarColorTextoBanda(Sender: TObject);
    procedure CambioTamano(Sender: TObject);
    procedure CambioOpacidad(Sender: TObject);
    procedure CambioOpacidadTexto(Sender: TObject);
    procedure CambioEsquinas(Sender: TObject);
    procedure CambioMargenes(Sender: TObject);
    procedure CambioBanda(Sender: TObject);
    procedure CambioAlto(Sender: TObject);
    procedure CambioTextoBanda(Sender: TObject);
    procedure InstalarClick(Sender: TObject);
    procedure AplicarClick(Sender: TObject);
    procedure ReaplicarClick(Sender: TObject);
    procedure DesinstalarClick(Sender: TObject);
    procedure CerrarCartelClick(Sender: TObject);
    procedure CerrarVentana(Sender: TObject);
    procedure AplicarDesdeUi(const MensajeOk: string);
    procedure RefrescarEstadoInstalacion;
    procedure MostrarMensaje(const Texto: string; EsError: Boolean);
    function TextoUi: string;
    function TituloVentana: string;
    function AjustesDeUi: TSettings;
    function EstiloActual: TBadgeStyle;
    function ElegirColor(var C: TRgb): Boolean;
    function AlineacionSeleccionada: string;
    function ColorAutomatico: Boolean;
    procedure MostrarEstadoInicial;
    procedure ActualizarDesdeUi;
    function ConfirmarActualizacion(const VInstalada, VDisponible: string): Boolean;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
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

function IndiceDeAlineacion(const S: string): Integer;
begin
  if SameText(S, 'centro') then
    Result := 1
  else if SameText(S, 'izquierda') then
    Result := 2
  else
    Result := 0;
end;

constructor TConfigForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner, 0);

  try
    Icon.LoadFromResourceName(HInstance, 'MAINICON');
  except
    // sin icono propio: se usa el predeterminado
  end;
  ShowInTaskbar := True;

  Caption := Texto(txtAppTitle) + ' - ' + Texto(txtSettings);
  BorderStyle := bsSingle;
  BorderIcons := [biSystemMenu, biMinimize];
  ClientWidth := 620;
  ClientHeight := 764;
  Position := poScreenCenter;
  Font.Name := 'Segoe UI';
  Font.Size := 9;

  FAjustes := AjustesEnUso;
  FColor := FAjustes.Color;
  FColorTexto := FAjustes.ColorTexto;
  FColorBanda := FAjustes.BandaColor;
  FColorTextoBanda := FAjustes.BandaColorTexto;
  FColorPersonalizado := not ColorAutomatico;

  CrearControles;
  ActualizarVista;
  RefrescarEstadoInstalacion;
  MostrarEstadoInicial;
end;

procedure TConfigForm.CreateParams(var Params: TCreateParams);
begin
  inherited;
  // El configurador es una ventana normal: icono y boton en la barra de tareas.
  Params.ExStyle := (Params.ExStyle or WS_EX_APPWINDOW) and not WS_EX_TOOLWINDOW;
end;

procedure TConfigForm.CreateWnd;
var
  H: HICON;
begin
  inherited;
  if FHIconSmall <> 0 then
  begin
    DestroyIcon(FHIconSmall);
    FHIconSmall := 0;
  end;
  if Icon.Handle = 0 then
    Exit;
  SendMessage(Handle, WM_SETICON, ICON_BIG, Icon.Handle);
  H := LoadImage(HInstance, 'MAINICON', IMAGE_ICON, 16, 16, LR_DEFAULTCOLOR);
  if H <> 0 then
  begin
    FHIconSmall := H;
    SendMessage(Handle, WM_SETICON, ICON_SMALL, H);
  end
  else
    SendMessage(Handle, WM_SETICON, ICON_SMALL, Icon.Handle);
end;

destructor TConfigForm.Destroy;
begin
  if FHIconSmall <> 0 then
    DestroyIcon(FHIconSmall);
  inherited;
end;

function TConfigForm.ColorAutomatico: Boolean;
var
  T: string;
begin
  T := UpperCase(Trim(FAjustes.Texto));
  Result := ((T = 'A') or (T = 'B')) and
    SameText(RgbAHex(FAjustes.Color), RgbAHex(ColorPorTexto(T)));
end;

function TConfigForm.TextoUi: string;
begin
  Result := Trim(FEdTexto.Text);
end;

function TConfigForm.TituloVentana: string;
var
  T: string;
begin
  T := TextoUi;
  if T = '' then
    T := 'A';
  if SameText(T, 'A') then
    Result := Texto(txtMachineA)
  else if SameText(T, 'B') then
    Result := Texto(txtMachineB)
  else
    Result := T;
end;

procedure TConfigForm.CrearControles;
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
  FLblTitulo.Caption := Texto(txtAppTitle);
  FLblTitulo.Font.Name := 'Segoe UI';
  FLblTitulo.Font.Size := 16;
  FLblTitulo.Font.Style := [fsBold];
  FLblTitulo.Font.Color := clWhite;
  FLblTitulo.Transparent := True;
  FLblTitulo.SetBounds(20, 8, 320, 30);

  FLblSub := TLabel.Create(Self);
  FLblSub.Parent := FHeader;
  FLblSub.Caption := TextoFmt(txtSubtitle, [VersionApp]);
  FLblSub.Font.Name := 'Segoe UI';
  FLblSub.Font.Size := 9;
  FLblSub.Font.Color := RGB(232, 232, 232);
  FLblSub.Transparent := True;
  FLblSub.SetBounds(21, 38, 460, 18);

  FPages := TPageControl.Create(Self);
  FPages.Parent := Self;
  FPages.SetBounds(16, 76, 588, 336);

  FTabCartel := TTabSheet.Create(Self);
  FTabCartel.PageControl := FPages;
  FTabCartel.Caption := Texto(txtTabBadge);

  FTabBanda := TTabSheet.Create(Self);
  FTabBanda.PageControl := FPages;
  FTabBanda.Caption := Texto(txtTabBand);

  CrearTabCartel;
  CrearTabBanda;

  FPages.ActivePage := FTabCartel;

  FPbPreview := TPaintBox.Create(Self);
  FPbPreview.Parent := Self;
  FPbPreview.SetBounds(16, 422, 588, 180);
  FPbPreview.OnPaint := PintarVista;

  FLblInstalacion := TLabel.Create(Self);
  FLblInstalacion.Parent := Self;
  FLblInstalacion.Caption := Texto(txtNotInstalled);
  FLblInstalacion.Font.Style := [fsBold];
  FLblInstalacion.AutoSize := False;
  FLblInstalacion.SetBounds(16, 610, 588, 18);

  FLblEstado := TLabel.Create(Self);
  FLblEstado.Parent := Self;
  FLblEstado.Caption := '';
  FLblEstado.WordWrap := True;
  FLblEstado.AutoSize := False;
  FLblEstado.SetBounds(16, 630, 588, 38);

  FBtnInstalar := TButton.Create(Self);
  FBtnInstalar.Parent := Self;
  FBtnInstalar.Caption := Texto(txtInstall);
  FBtnInstalar.SetBounds(16, 676, 110, 32);
  FBtnInstalar.OnClick := InstalarClick;

  FBtnAplicar := TButton.Create(Self);
  FBtnAplicar.Parent := Self;
  FBtnAplicar.Caption := Texto(txtApply);
  FBtnAplicar.SetBounds(136, 676, 100, 32);
  FBtnAplicar.OnClick := AplicarClick;

  FBtnDesinstalar := TButton.Create(Self);
  FBtnDesinstalar.Parent := Self;
  FBtnDesinstalar.Caption := Texto(txtUninstall);
  FBtnDesinstalar.SetBounds(246, 676, 110, 32);
  FBtnDesinstalar.OnClick := DesinstalarClick;

  FBtnReaplicar := TButton.Create(Self);
  FBtnReaplicar.Parent := Self;
  FBtnReaplicar.Caption := Texto(txtReapply);
  FBtnReaplicar.SetBounds(366, 676, 140, 32);
  FBtnReaplicar.OnClick := ReaplicarClick;

  FBtnCerrarCartel := TButton.Create(Self);
  FBtnCerrarCartel.Parent := Self;
  FBtnCerrarCartel.Caption := Texto(txtCloseBadge);
  FBtnCerrarCartel.SetBounds(16, 716, 142, 32);
  FBtnCerrarCartel.OnClick := CerrarCartelClick;

  FBtnCerrar := TButton.Create(Self);
  FBtnCerrar.Parent := Self;
  FBtnCerrar.Caption := Texto(txtClose);
  FBtnCerrar.Cancel := True;
  FBtnCerrar.SetBounds(514, 716, 90, 32);
  FBtnCerrar.OnClick := CerrarVentana;
end;

procedure TConfigForm.CrearTabCartel;
var
  L: TLabel;
begin
  L := TLabel.Create(Self);
  L.Parent := FTabCartel;
  L.Caption := Texto(txtBadgeText);
  L.SetBounds(8, 17, 110, 18);

  FEdTexto := TEdit.Create(Self);
  FEdTexto.Parent := FTabCartel;
  FEdTexto.MaxLength := 4;
  FEdTexto.Text := FAjustes.Texto;
  FEdTexto.SetBounds(122, 13, 80, 24);
  FEdTexto.OnChange := TextoCambiado;

  L := TLabel.Create(Self);
  L.Parent := FTabCartel;
  L.Caption := Texto(txtBadgeTextHint);
  L.Font.Color := RGB(110, 110, 110);
  L.SetBounds(210, 17, 120, 18);

  L := TLabel.Create(Self);
  L.Parent := FTabCartel;
  L.Caption := Texto(txtPanelColor);
  L.SetBounds(8, 51, 110, 18);

  FSwCartel := TPanel.Create(Self);
  FSwCartel.Parent := FTabCartel;
  FSwCartel.SetBounds(122, 47, 48, 26);
  FSwCartel.BevelOuter := bvNone;
  FSwCartel.Color := RgbATColor(FColor);
  FSwCartel.StyleElements := [];

  FLblCartelHex := TLabel.Create(Self);
  FLblCartelHex.Parent := FTabCartel;
  FLblCartelHex.Caption := RgbAHex(FColor);
  FLblCartelHex.Font.Name := 'Consolas';
  FLblCartelHex.Font.Size := 10;
  FLblCartelHex.Font.Style := [fsBold];
  FLblCartelHex.SetBounds(176, 51, 70, 20);

  FBtnCartelColor := TButton.Create(Self);
  FBtnCartelColor.Parent := FTabCartel;
  FBtnCartelColor.Caption := Texto(txtChange);
  FBtnCartelColor.SetBounds(250, 45, 110, 28);
  FBtnCartelColor.OnClick := CambiarColorCartel;

  L := TLabel.Create(Self);
  L.Parent := FTabCartel;
  L.Caption := Texto(txtTextColor);
  L.SetBounds(8, 85, 110, 18);

  FSwTexto := TPanel.Create(Self);
  FSwTexto.Parent := FTabCartel;
  FSwTexto.SetBounds(122, 81, 48, 26);
  FSwTexto.BevelOuter := bvNone;
  FSwTexto.Color := RgbATColor(FColorTexto);
  FSwTexto.StyleElements := [];

  FLblTextoHex := TLabel.Create(Self);
  FLblTextoHex.Parent := FTabCartel;
  FLblTextoHex.Caption := RgbAHex(FColorTexto);
  FLblTextoHex.Font.Name := 'Consolas';
  FLblTextoHex.Font.Size := 10;
  FLblTextoHex.Font.Style := [fsBold];
  FLblTextoHex.SetBounds(176, 85, 70, 20);

  FBtnTextoColor := TButton.Create(Self);
  FBtnTextoColor.Parent := FTabCartel;
  FBtnTextoColor.Caption := Texto(txtChange);
  FBtnTextoColor.SetBounds(250, 79, 110, 28);
  FBtnTextoColor.OnClick := CambiarColorTexto;

  L := TLabel.Create(Self);
  L.Parent := FTabCartel;
  L.Caption := Texto(txtSize);
  L.SetBounds(8, 119, 110, 18);

  FSeTamano := TSpinEdit.Create(Self);
  FSeTamano.Parent := FTabCartel;
  FSeTamano.MinValue := 90;
  FSeTamano.MaxValue := 280;
  FSeTamano.Increment := 10;
  FSeTamano.Value := FAjustes.Tamano;
  FSeTamano.SetBounds(122, 115, 70, 24);
  FSeTamano.OnChange := CambioTamano;

  L := TLabel.Create(Self);
  L.Parent := FTabCartel;
  L.Caption := 'px';
  L.SetBounds(198, 119, 30, 18);

  L := TLabel.Create(Self);
  L.Parent := FTabCartel;
  L.Caption := Texto(txtPanelOpacity);
  L.SetBounds(8, 153, 140, 18);

  FTbOpacidad := TTrackBar.Create(Self);
  FTbOpacidad.Parent := FTabCartel;
  FTbOpacidad.Min := 10;
  FTbOpacidad.Max := 60;
  FTbOpacidad.Frequency := 5;
  FTbOpacidad.Position := Round(FAjustes.OpacidadPanel * 100);
  FTbOpacidad.SetBounds(160, 149, 220, 30);
  FTbOpacidad.OnChange := CambioOpacidad;

  FLblOpacidad := TLabel.Create(Self);
  FLblOpacidad.Parent := FTabCartel;
  FLblOpacidad.Caption := IntToStr(FTbOpacidad.Position) + ' %';
  FLblOpacidad.Font.Style := [fsBold];
  FLblOpacidad.SetBounds(388, 155, 50, 18);

  L := TLabel.Create(Self);
  L.Parent := FTabCartel;
  L.Caption := Texto(txtTextOpacity);
  L.SetBounds(8, 187, 140, 18);

  FTbOpacidadTexto := TTrackBar.Create(Self);
  FTbOpacidadTexto.Parent := FTabCartel;
  FTbOpacidadTexto.Min := 30;
  FTbOpacidadTexto.Max := 100;
  FTbOpacidadTexto.Frequency := 5;
  FTbOpacidadTexto.Position := Round(FAjustes.OpacidadLetra * 100);
  FTbOpacidadTexto.SetBounds(160, 183, 220, 30);
  FTbOpacidadTexto.OnChange := CambioOpacidadTexto;

  FLblOpacidadTexto := TLabel.Create(Self);
  FLblOpacidadTexto.Parent := FTabCartel;
  FLblOpacidadTexto.Caption := IntToStr(FTbOpacidadTexto.Position) + ' %';
  FLblOpacidadTexto.Font.Style := [fsBold];
  FLblOpacidadTexto.SetBounds(388, 189, 50, 18);

  L := TLabel.Create(Self);
  L.Parent := FTabCartel;
  L.Caption := Texto(txtCornerRadius);
  L.SetBounds(8, 221, 150, 18);

  FTbEsquinas := TTrackBar.Create(Self);
  FTbEsquinas.Parent := FTabCartel;
  FTbEsquinas.Min := 0;
  FTbEsquinas.Max := 50;
  FTbEsquinas.Frequency := 5;
  FTbEsquinas.Position := Round(FAjustes.Esquinas * 100);
  FTbEsquinas.SetBounds(160, 217, 220, 30);
  FTbEsquinas.OnChange := CambioEsquinas;

  FLblEsquinas := TLabel.Create(Self);
  FLblEsquinas.Parent := FTabCartel;
  FLblEsquinas.Caption := IntToStr(FTbEsquinas.Position) + ' %';
  FLblEsquinas.Font.Style := [fsBold];
  FLblEsquinas.SetBounds(388, 223, 50, 18);

  L := TLabel.Create(Self);
  L.Parent := FTabCartel;
  L.Caption := Texto(txtMargins);
  L.SetBounds(8, 255, 150, 18);

  FSeMargenDer := TSpinEdit.Create(Self);
  FSeMargenDer.Parent := FTabCartel;
  FSeMargenDer.MinValue := 0;
  FSeMargenDer.MaxValue := 1000;
  FSeMargenDer.Increment := 5;
  FSeMargenDer.Value := FAjustes.MargenDerecha;
  FSeMargenDer.SetBounds(160, 251, 60, 24);
  FSeMargenDer.OnChange := CambioMargenes;

  FSeMargenInf := TSpinEdit.Create(Self);
  FSeMargenInf.Parent := FTabCartel;
  FSeMargenInf.MinValue := 0;
  FSeMargenInf.MaxValue := 1000;
  FSeMargenInf.Increment := 5;
  FSeMargenInf.Value := FAjustes.MargenInferior;
  FSeMargenInf.SetBounds(230, 251, 60, 24);
  FSeMargenInf.OnChange := CambioMargenes;

  L := TLabel.Create(Self);
  L.Parent := FTabCartel;
  L.Caption := 'px';
  L.SetBounds(298, 255, 30, 18);
end;

procedure TConfigForm.CrearTabBanda;
var
  L: TLabel;
begin
  FChkBanda := TCheckBox.Create(Self);
  FChkBanda.Parent := FTabBanda;
  FChkBanda.Caption := Texto(txtBandEnable);
  FChkBanda.SetBounds(8, 12, 520, 22);
  FChkBanda.Checked := FAjustes.BandaActiva;
  FChkBanda.OnClick := CambioBanda;

  L := TLabel.Create(Self);
  L.Parent := FTabBanda;
  L.Caption := Texto(txtBandColor);
  L.SetBounds(8, 49, 140, 18);

  FSwBanda := TPanel.Create(Self);
  FSwBanda.Parent := FTabBanda;
  FSwBanda.SetBounds(150, 45, 48, 26);
  FSwBanda.BevelOuter := bvNone;
  FSwBanda.Color := RgbATColor(FColorBanda);
  FSwBanda.StyleElements := [];

  FLblBandaHex := TLabel.Create(Self);
  FLblBandaHex.Parent := FTabBanda;
  FLblBandaHex.Caption := RgbAHex(FColorBanda);
  FLblBandaHex.Font.Name := 'Consolas';
  FLblBandaHex.Font.Size := 10;
  FLblBandaHex.Font.Style := [fsBold];
  FLblBandaHex.SetBounds(204, 49, 70, 20);

  FBtnBandaColor := TButton.Create(Self);
  FBtnBandaColor.Parent := FTabBanda;
  FBtnBandaColor.Caption := Texto(txtChange);
  FBtnBandaColor.SetBounds(278, 43, 110, 28);
  FBtnBandaColor.OnClick := CambiarColorBanda;

  L := TLabel.Create(Self);
  L.Parent := FTabBanda;
  L.Caption := Texto(txtTextColor);
  L.SetBounds(8, 83, 140, 18);

  FSwTextoBanda := TPanel.Create(Self);
  FSwTextoBanda.Parent := FTabBanda;
  FSwTextoBanda.SetBounds(150, 79, 48, 26);
  FSwTextoBanda.BevelOuter := bvNone;
  FSwTextoBanda.Color := RgbATColor(FColorTextoBanda);
  FSwTextoBanda.StyleElements := [];

  FLblTextoBandaHex := TLabel.Create(Self);
  FLblTextoBandaHex.Parent := FTabBanda;
  FLblTextoBandaHex.Caption := RgbAHex(FColorTextoBanda);
  FLblTextoBandaHex.Font.Name := 'Consolas';
  FLblTextoBandaHex.Font.Size := 10;
  FLblTextoBandaHex.Font.Style := [fsBold];
  FLblTextoBandaHex.SetBounds(204, 83, 70, 20);

  FBtnTextoBandaColor := TButton.Create(Self);
  FBtnTextoBandaColor.Parent := FTabBanda;
  FBtnTextoBandaColor.Caption := Texto(txtChange);
  FBtnTextoBandaColor.SetBounds(278, 77, 110, 28);
  FBtnTextoBandaColor.OnClick := CambiarColorTextoBanda;

  L := TLabel.Create(Self);
  L.Parent := FTabBanda;
  L.Caption := Texto(txtBandHeight);
  L.SetBounds(8, 117, 140, 18);

  FTbAlto := TTrackBar.Create(Self);
  FTbAlto.Parent := FTabBanda;
  FTbAlto.Min := 2;
  FTbAlto.Max := 20;
  FTbAlto.Frequency := 1;
  FTbAlto.Position := Round(FAjustes.BandaAlto * 100);
  FTbAlto.SetBounds(150, 113, 220, 30);
  FTbAlto.OnChange := CambioAlto;

  FLblAlto := TLabel.Create(Self);
  FLblAlto.Parent := FTabBanda;
  FLblAlto.Caption := IntToStr(FTbAlto.Position) + ' %';
  FLblAlto.Font.Style := [fsBold];
  FLblAlto.SetBounds(378, 119, 190, 18);

  L := TLabel.Create(Self);
  L.Parent := FTabBanda;
  L.Caption := Texto(txtBandText);
  L.SetBounds(8, 151, 140, 18);

  FEdTextoBanda := TEdit.Create(Self);
  FEdTextoBanda.Parent := FTabBanda;
  FEdTextoBanda.MaxLength := 20;
  FEdTextoBanda.Text := FAjustes.BandaTexto;
  FEdTextoBanda.SetBounds(150, 147, 220, 24);
  FEdTextoBanda.OnChange := CambioTextoBanda;

  L := TLabel.Create(Self);
  L.Parent := FTabBanda;
  L.Caption := Texto(txtBandTextHint);
  L.Font.Color := RGB(110, 110, 110);
  L.SetBounds(378, 151, 150, 18);

  L := TLabel.Create(Self);
  L.Parent := FTabBanda;
  L.Caption := Texto(txtBandAlignment);
  L.SetBounds(8, 185, 140, 18);

  FCbAlineacion := TComboBox.Create(Self);
  FCbAlineacion.Parent := FTabBanda;
  FCbAlineacion.Style := csDropDownList;
  FCbAlineacion.Items.Add(Texto(txtAlignRight));
  FCbAlineacion.Items.Add(Texto(txtAlignCenter));
  FCbAlineacion.Items.Add(Texto(txtAlignLeft));
  FCbAlineacion.ItemIndex := IndiceDeAlineacion(FAjustes.BandaAlineacion);
  FCbAlineacion.SetBounds(150, 181, 120, 24);
  FCbAlineacion.OnChange := CambioBanda;

  L := TLabel.Create(Self);
  L.Parent := FTabBanda;
  L.Caption := Texto(txtBandNoteMonitors);
  L.Font.Color := RGB(110, 110, 110);
  L.SetBounds(8, 221, 540, 18);

  L := TLabel.Create(Self);
  L.Parent := FTabBanda;
  L.Caption := Texto(txtBandNoteReapply);
  L.Font.Color := RGB(110, 110, 110);
  L.SetBounds(8, 245, 540, 18);
end;

function TConfigForm.AlineacionSeleccionada: string;
begin
  case FCbAlineacion.ItemIndex of
    1: Result := 'centro';
    2: Result := 'izquierda';
  else
    Result := 'derecha';
  end;
end;

function TConfigForm.AjustesDeUi: TSettings;
begin
  Result := FAjustes;
  Result.Texto := TextoUi;
  if Result.Texto = '' then
    Result.Texto := 'A';
  Result.Color := FColor;
  Result.ColorTexto := FColorTexto;
  Result.Tamano := FSeTamano.Value;
  Result.OpacidadPanel := FTbOpacidad.Position / 100;
  Result.OpacidadLetra := FTbOpacidadTexto.Position / 100;
  Result.Esquinas := FTbEsquinas.Position / 100;
  Result.MargenDerecha := FSeMargenDer.Value;
  Result.MargenInferior := FSeMargenInf.Value;
  Result.BandaActiva := FChkBanda.Checked;
  Result.BandaColor := FColorBanda;
  Result.BandaAlto := FTbAlto.Position / 100;
  Result.BandaTexto := Trim(FEdTextoBanda.Text);
  Result.BandaColorTexto := FColorTextoBanda;
  Result.BandaAlineacion := AlineacionSeleccionada;
  Result := AjustesValidos(Result);
end;

function TConfigForm.EstiloActual: TBadgeStyle;
var
  T: string;
begin
  T := TextoUi;
  if T = '' then
    T := '?';
  Result.Texto := T;
  Result.Color := FColor;
  Result.ColorTexto := FColorTexto;
  Result.OpacidadPanel := FTbOpacidad.Position / 100;
  Result.OpacidadLetra := FTbOpacidadTexto.Position / 100;
  Result.Esquinas := FTbEsquinas.Position / 100;
  Result.Fuente := FAjustes.Fuente;
  Result.Tamano := FSeTamano.Value;
end;

procedure TConfigForm.ActualizarVista;
var
  AltoPantalla: Integer;
  AnchoPantalla: Integer;
begin
  FHeader.Color := RgbATColor(FColor);

  FSwCartel.Color := RgbATColor(FColor);
  FLblCartelHex.Caption := RgbAHex(FColor);
  FSwTexto.Color := RgbATColor(FColorTexto);
  FLblTextoHex.Caption := RgbAHex(FColorTexto);
  FSwBanda.Color := RgbATColor(FColorBanda);
  FLblBandaHex.Caption := RgbAHex(FColorBanda);
  FSwTextoBanda.Color := RgbATColor(FColorTextoBanda);
  FLblTextoBandaHex.Caption := RgbAHex(FColorTextoBanda);

  FLblOpacidad.Caption := IntToStr(FTbOpacidad.Position) + ' %';
  FLblOpacidadTexto.Caption := IntToStr(FTbOpacidadTexto.Position) + ' %';
  FLblEsquinas.Caption := IntToStr(FTbEsquinas.Position) + ' %';
  if not ResolucionPrimaria(AnchoPantalla, AltoPantalla) then
    AltoPantalla := 1080;
  FLblAlto.Caption := IntToStr(FTbAlto.Position) + ' % (≈' +
    IntToStr(Round(AltoPantalla * FTbAlto.Position / 100)) + ' px)';

  Caption := Texto(txtAppTitle) + ' - ' + Texto(txtSettings) + ' - ' + TituloVentana;
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
      BandH := Round(Alto * FTbAlto.Position / 100);
      if BandH < 8 then
        BandH := 8;
      DibujarBanda(G, RF(0, 0, Ancho, BandH), FColorBanda,
        Trim(FEdTextoBanda.Text), FColorTextoBanda, AlineacionSeleccionada);
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

procedure TConfigForm.TextoCambiado(Sender: TObject);
begin
  if not FColorPersonalizado then
  begin
    if SameText(TextoUi, 'A') then
      FColor := ColorPorTexto('A')
    else if SameText(TextoUi, 'B') then
      FColor := ColorPorTexto('B');
  end;
  ActualizarVista;
end;

function TConfigForm.ElegirColor(var C: TRgb): Boolean;
var
  Dlg: TColorDialog;
begin
  Result := False;
  Dlg := TColorDialog.Create(Self);
  try
    Dlg.Color := RgbATColor(C);
    Dlg.Options := Dlg.Options + [cdFullOpen];
    if Dlg.Execute then
    begin
      C := TColorARgb(Dlg.Color);
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TConfigForm.CambiarColorCartel(Sender: TObject);
begin
  if ElegirColor(FColor) then
  begin
    FColorPersonalizado := True;
    ActualizarVista;
  end;
end;

procedure TConfigForm.CambiarColorTexto(Sender: TObject);
begin
  if ElegirColor(FColorTexto) then
    ActualizarVista;
end;

procedure TConfigForm.CambiarColorBanda(Sender: TObject);
begin
  if ElegirColor(FColorBanda) then
    ActualizarVista;
end;

procedure TConfigForm.CambiarColorTextoBanda(Sender: TObject);
begin
  if ElegirColor(FColorTextoBanda) then
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

procedure TConfigForm.CambioOpacidadTexto(Sender: TObject);
begin
  ActualizarVista;
end;

procedure TConfigForm.CambioEsquinas(Sender: TObject);
begin
  ActualizarVista;
end;

procedure TConfigForm.CambioMargenes(Sender: TObject);
begin
  FPbPreview.Invalidate;
end;

procedure TConfigForm.CambioBanda(Sender: TObject);
begin
  ActualizarVista;
end;

procedure TConfigForm.CambioAlto(Sender: TObject);
begin
  ActualizarVista;
end;

procedure TConfigForm.CambioTextoBanda(Sender: TObject);
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
  FLblInstalacion.Caption := DescripcionEstado(E);

  if E.RequiereReparacion then
  begin
    FLblInstalacion.Font.Color := RGB(170, 30, 30);
    FBtnInstalar.Caption := Texto(txtRepair);
  end
  else if not E.HostInstalado then
  begin
    FLblInstalacion.Font.Color := RGB(150, 90, 0);
    FLblInstalacion.Caption := Texto(txtNotInstalledHint);
    FBtnInstalar.Caption := Texto(txtInstall);
  end
  else if E.ActualizacionDisponible then
  begin
    FLblInstalacion.Font.Color := RGB(150, 90, 0);
    FBtnInstalar.Caption := Texto(txtUpdate);
  end
  else
  begin
    FLblInstalacion.Font.Color := RGB(20, 110, 60);
    FBtnInstalar.Caption := Texto(txtReinstall);
  end;
end;

procedure TConfigForm.MostrarEstadoInicial;
var
  E: TEstadoInstalacion;
begin
  E := EstadoInstalacion;
  if E.RequiereReparacion then
    MostrarMensaje(E.Problema + ' ' + Texto(txtPressRepair), True)
  else if E.ActualizacionDisponible then
    MostrarMensaje(TextoFmt(txtUpdateAvailableMsg,
      [E.VersionInstalada, E.VersionDisponible]), False)
  else
    MostrarMensaje(Texto(txtClicksThrough), False);
end;

procedure TConfigForm.AplicarDesdeUi(const MensajeOk: string);
var
  Mensaje: string;
begin
  if not EstadoInstalacion.HostInstalado then
  begin
    MostrarMensaje(Texto(txtNotInstalledApply), True);
    Exit;
  end;

  FBtnAplicar.Enabled := False;
  FBtnReaplicar.Enabled := False;
  Screen.Cursor := crHourGlass;
  try
    FAjustes := AjustesDeUi;
    if Aplicar(FAjustes, Mensaje) then
      MostrarMensaje(Format(MensajeOk, [TimeToStr(Now)]), False)
    else
      MostrarMensaje(TextoFmt(txtError, [Mensaje]), True);
  finally
    Screen.Cursor := crDefault;
    FBtnAplicar.Enabled := True;
    FBtnReaplicar.Enabled := True;
    RefrescarEstadoInstalacion;
  end;
end;

procedure TConfigForm.InstalarClick(Sender: TObject);
var
  E: TEstadoInstalacion;
  Mensaje: string;
  OkId, FailId: TTextId;
begin
  E := EstadoInstalacion;

  if E.HostInstalado and E.ActualizacionDisponible and
     (not E.RequiereReparacion) then
  begin
    ActualizarDesdeUi;
    Exit;
  end;

  if E.RequiereReparacion then
  begin
    OkId := txtRepairedApplied;
    FailId := txtRepairApplyFailed;
  end
  else if E.HostInstalado then
  begin
    OkId := txtReinstalledApplied;
    FailId := txtReinstallApplyFailed;
  end
  else
  begin
    OkId := txtInstalledApplied;
    FailId := txtInstallApplyFailed;
  end;

  FBtnInstalar.Enabled := False;
  Screen.Cursor := crHourGlass;
  try
    FAjustes := AjustesDeUi;
    if not Instalar(FAjustes, Mensaje) then
    begin
      MostrarMensaje(TextoFmt(txtError, [Mensaje]), True);
      Exit;
    end;
    if not Aplicar(FAjustes, Mensaje) then
    begin
      MostrarMensaje(TextoFmt(FailId, [Mensaje]), True);
      Exit;
    end;
    MostrarMensaje(TextoFmt(OkId, [TimeToStr(Now)]), False);
  finally
    Screen.Cursor := crDefault;
    FBtnInstalar.Enabled := True;
    RefrescarEstadoInstalacion;
  end;
end;

function TConfigForm.ConfirmarActualizacion(const VInstalada,
  VDisponible: string): Boolean;
var
  Dlg: TTaskDialog;
begin
  Result := False;
  Dlg := TTaskDialog.Create(Self);
  try
    Dlg.Caption := Texto(txtUpdateDialogCaption);
    Dlg.Title := Texto(txtUpdateDialogTitle);
    Dlg.Text := TextoFmt(txtUpdateDialogText, [VInstalada, VDisponible]);
    Dlg.CommonButtons := [tcbYes, tcbNo];
    Dlg.DefaultButton := tcbNo;
    if not Dlg.Execute then
      Exit;
    Result := Dlg.ModalResult = mrYes;
  finally
    Dlg.Free;
  end;
end;

procedure TConfigForm.ActualizarDesdeUi;
var
  E: TEstadoInstalacion;
  Mensaje: string;
begin
  E := EstadoInstalacion;
  if not ConfirmarActualizacion(E.VersionInstalada, E.VersionDisponible) then
    Exit;

  FBtnInstalar.Enabled := False;
  FBtnAplicar.Enabled := False;
  FBtnReaplicar.Enabled := False;
  Screen.Cursor := crHourGlass;
  try
    if not ActualizarHost(Mensaje) then
    begin
      MostrarMensaje(TextoFmt(txtError, [Mensaje]), True);
      Exit;
    end;
    FAjustes := AjustesDeUi;
    if Aplicar(FAjustes, Mensaje) then
      MostrarMensaje(TextoFmt(txtUpdatedBand,
        [VersionArchivo(RutaHostInstalado), TimeToStr(Now)]), False)
    else
      MostrarMensaje(TextoFmt(txtUpdatedNoBand, [Mensaje]), True);
  finally
    Screen.Cursor := crDefault;
    FBtnInstalar.Enabled := True;
    FBtnAplicar.Enabled := True;
    FBtnReaplicar.Enabled := True;
    RefrescarEstadoInstalacion;
  end;
end;

procedure TConfigForm.AplicarClick(Sender: TObject);
begin
  AplicarDesdeUi(Texto(txtApplied));
end;

procedure TConfigForm.ReaplicarClick(Sender: TObject);
begin
  if not FChkBanda.Checked then
  begin
    MostrarMensaje(Texto(txtBandDisabled), True);
    Exit;
  end;
  AplicarDesdeUi(Texto(txtReapplied));
end;

procedure TConfigForm.DesinstalarClick(Sender: TObject);
var
  Dlg: TTaskDialog;
  Conservar: Boolean;
  Mensaje: string;
begin
  Dlg := TTaskDialog.Create(Self);
  try
    Dlg.Caption := Texto(txtUninstallDialogCaption);
    Dlg.Title := Texto(txtUninstallDialogTitle);
    Dlg.Text := Texto(txtUninstallDialogText);
    Dlg.CommonButtons := [tcbYes, tcbNo];
    Dlg.DefaultButton := tcbNo;
    Dlg.VerificationText := Texto(txtKeepConfig);
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
      MostrarMensaje(TextoFmt(txtError, [Mensaje]), True);
  finally
    Screen.Cursor := crDefault;
    RefrescarEstadoInstalacion;
  end;
end;

procedure TConfigForm.CerrarCartelClick(Sender: TObject);
begin
  AvisarHost(MensajeSalir);
  Sleep(150);
  MostrarMensaje(Texto(txtCloseSent), False);
  RefrescarEstadoInstalacion;
end;

procedure TConfigForm.CerrarVentana(Sender: TObject);
begin
  Close;
end;

end.
