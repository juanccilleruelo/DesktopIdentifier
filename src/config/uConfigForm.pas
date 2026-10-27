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
    FTabEscritorio: TTabSheet;
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
    FChkSyncColor: TCheckBox;
    FLblBandaColor: TLabel;
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
    // Escritorio
    FRgFondo: TRadioGroup;
    FLblDesktopColor: TLabel;
    FSwDesktopColor: TPanel;
    FLblDesktopColorHex: TLabel;
    FBtnDesktopColor: TButton;
    FLblDesktopColor1: TLabel;
    FSwDesktopColor1: TPanel;
    FLblDesktopColor1Hex: TLabel;
    FBtnDesktopColor1: TButton;
    FLblDesktopColor2: TLabel;
    FSwDesktopColor2: TPanel;
    FLblDesktopColor2Hex: TLabel;
    FBtnDesktopColor2: TButton;
    FLblDesktopTextLarge: TLabel;
    FEdDesktopGrande: TEdit;
    FLblDesktopTextSmall: TLabel;
    FEdDesktopPequeno: TEdit;
    FLblDesktopFont: TLabel;
    FCbDesktopFuente: TComboBox;
    FLblDesktopFontSize: TLabel;
    FSeDesktopTamano: TSpinEdit;
    FLblDesktopHint: TLabel;
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
    FondoEscritorio: TDesktopFondo;
    FColorDesktop: TRgb;
    FColorDesktop2: TRgb;
    FColorPersonalizado: Boolean;
    FAjustes: TSettings;
    FHIconSmall: HICON;
    procedure CrearControles;
    procedure CrearTabCartel;
    procedure CrearTabBanda;
    procedure CrearTabEscritorio;
    procedure ActualizarVista;
    procedure PintarVista(Sender: TObject);
    procedure AjustarFuentesPestanas(AControl: TWinControl);
    procedure TextoCambiado(Sender: TObject);
    procedure CambiarColorCartel(Sender: TObject);
    procedure CambiarColorTexto(Sender: TObject);
    procedure CambiarColorBanda(Sender: TObject);
    procedure CambiarColorTextoBanda(Sender: TObject);
    procedure CambioSincronizarColor(Sender: TObject);
    procedure AjustarControlesColorBanda;
    procedure CambiarColorDesktop(Sender: TObject);
    procedure CambiarColorDesktop1(Sender: TObject);
    procedure CambiarColorDesktop2(Sender: TObject);
    procedure CambioFondoEscritorio(Sender: TObject);
    procedure CambioTextoEscritorio(Sender: TObject);
    procedure AjustarControlesFondoEscritorio;
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

type
  TControlAccess = class(TControl);

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
  if FAjustes.BandaColorSincronizado then
    FColorBanda := FColor;
  FColorTextoBanda := FAjustes.BandaColorTexto;
  FondoEscritorio := FAjustes.DesktopFondo;
  FColorDesktop := FAjustes.DesktopColor;
  FColorDesktop2 := FAjustes.DesktopColor2;
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
  FPages.Font.Name := 'Segoe UI';
  FPages.Font.Size := 10;
  FPages.Font.Style := [fsBold];

  FTabCartel := TTabSheet.Create(Self);
  FTabCartel.PageControl := FPages;
  FTabCartel.Caption := Texto(txtTabBadge);

  FTabBanda := TTabSheet.Create(Self);
  FTabBanda.PageControl := FPages;
  FTabBanda.Caption := Texto(txtTabBand);

  FTabEscritorio := TTabSheet.Create(Self);
  FTabEscritorio.PageControl := FPages;
  FTabEscritorio.Caption := Texto(txtTabDesktop);

  CrearTabCartel;
  CrearTabBanda;
  CrearTabEscritorio;

  AjustarFuentesPestanas(FPages);
  AjustarControlesColorBanda;
  AjustarControlesFondoEscritorio;

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
  FEdTexto.MaxLength := 0;
  FEdTexto.Text := FAjustes.Texto;
  FEdTexto.SetBounds(122, 13, 80, 24);
  FEdTexto.OnChange := TextoCambiado;

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
  FLblCartelHex.ParentFont := False;
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
  FLblTextoHex.ParentFont := False;
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
  FLblOpacidad.ParentFont := False;
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
  FLblOpacidadTexto.ParentFont := False;
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
  FLblEsquinas.ParentFont := False;
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

  FChkSyncColor := TCheckBox.Create(Self);
  FChkSyncColor.Parent := FTabBanda;
  FChkSyncColor.Caption := Texto(txtSyncColor);
  FChkSyncColor.SetBounds(8, 42, 540, 22);
  FChkSyncColor.Checked := FAjustes.BandaColorSincronizado;
  FChkSyncColor.OnClick := CambioSincronizarColor;

  FLblBandaColor := TLabel.Create(Self);
  FLblBandaColor.Parent := FTabBanda;
  FLblBandaColor.Caption := Texto(txtBandColor);
  FLblBandaColor.SetBounds(8, 79, 140, 18);

  FSwBanda := TPanel.Create(Self);
  FSwBanda.Parent := FTabBanda;
  FSwBanda.SetBounds(150, 75, 48, 26);
  FSwBanda.BevelOuter := bvNone;
  FSwBanda.Color := RgbATColor(FColorBanda);
  FSwBanda.StyleElements := [];

  FLblBandaHex := TLabel.Create(Self);
  FLblBandaHex.Parent := FTabBanda;
  FLblBandaHex.Caption := RgbAHex(FColorBanda);
  FLblBandaHex.Font.Name := 'Consolas';
  FLblBandaHex.ParentFont := False;
  FLblBandaHex.Font.Size := 10;
  FLblBandaHex.Font.Style := [fsBold];
  FLblBandaHex.SetBounds(204, 79, 70, 20);

  FBtnBandaColor := TButton.Create(Self);
  FBtnBandaColor.Parent := FTabBanda;
  FBtnBandaColor.Caption := Texto(txtChange);
  FBtnBandaColor.SetBounds(278, 73, 110, 28);
  FBtnBandaColor.OnClick := CambiarColorBanda;

  L := TLabel.Create(Self);
  L.Parent := FTabBanda;
  L.Caption := Texto(txtTextColor);
  L.SetBounds(8, 113, 140, 18);

  FSwTextoBanda := TPanel.Create(Self);
  FSwTextoBanda.Parent := FTabBanda;
  FSwTextoBanda.SetBounds(150, 109, 48, 26);
  FSwTextoBanda.BevelOuter := bvNone;
  FSwTextoBanda.Color := RgbATColor(FColorTextoBanda);
  FSwTextoBanda.StyleElements := [];

  FLblTextoBandaHex := TLabel.Create(Self);
  FLblTextoBandaHex.Parent := FTabBanda;
  FLblTextoBandaHex.Caption := RgbAHex(FColorTextoBanda);
  FLblTextoBandaHex.Font.Name := 'Consolas';
  FLblTextoBandaHex.ParentFont := False;
  FLblTextoBandaHex.Font.Size := 10;
  FLblTextoBandaHex.Font.Style := [fsBold];
  FLblTextoBandaHex.SetBounds(204, 113, 70, 20);

  FBtnTextoBandaColor := TButton.Create(Self);
  FBtnTextoBandaColor.Parent := FTabBanda;
  FBtnTextoBandaColor.Caption := Texto(txtChange);
  FBtnTextoBandaColor.SetBounds(278, 107, 110, 28);
  FBtnTextoBandaColor.OnClick := CambiarColorTextoBanda;

  L := TLabel.Create(Self);
  L.Parent := FTabBanda;
  L.Caption := Texto(txtBandHeight);
  L.SetBounds(8, 147, 140, 18);

  FTbAlto := TTrackBar.Create(Self);
  FTbAlto.Parent := FTabBanda;
  FTbAlto.Min := 2;
  FTbAlto.Max := 20;
  FTbAlto.Frequency := 1;
  FTbAlto.Position := Round(FAjustes.BandaAlto * 100);
  FTbAlto.SetBounds(150, 143, 220, 30);
  FTbAlto.OnChange := CambioAlto;

  FLblAlto := TLabel.Create(Self);
  FLblAlto.Parent := FTabBanda;
  FLblAlto.Caption := IntToStr(FTbAlto.Position) + ' %';
  FLblAlto.Font.Style := [fsBold];
  FLblAlto.ParentFont := False;
  FLblAlto.SetBounds(378, 149, 190, 18);

  L := TLabel.Create(Self);
  L.Parent := FTabBanda;
  L.Caption := Texto(txtBandText);
  L.SetBounds(8, 181, 140, 18);

  FEdTextoBanda := TEdit.Create(Self);
  FEdTextoBanda.Parent := FTabBanda;
  FEdTextoBanda.MaxLength := 0;
  FEdTextoBanda.Text := FAjustes.BandaTexto;
  FEdTextoBanda.SetBounds(150, 177, 220, 24);
  FEdTextoBanda.OnChange := CambioTextoBanda;

  L := TLabel.Create(Self);
  L.Parent := FTabBanda;
  L.Caption := Texto(txtBandAlignment);
  L.SetBounds(8, 215, 140, 18);

  FCbAlineacion := TComboBox.Create(Self);
  FCbAlineacion.Parent := FTabBanda;
  FCbAlineacion.Style := csDropDownList;
  FCbAlineacion.Items.Add(Texto(txtAlignRight));
  FCbAlineacion.Items.Add(Texto(txtAlignCenter));
  FCbAlineacion.Items.Add(Texto(txtAlignLeft));
  FCbAlineacion.ItemIndex := IndiceDeAlineacion(FAjustes.BandaAlineacion);
  FCbAlineacion.SetBounds(150, 211, 120, 24);
  FCbAlineacion.OnChange := CambioBanda;

  L := TLabel.Create(Self);
  L.Parent := FTabBanda;
  L.Caption := Texto(txtBandNoteMonitors);
  L.Font.Color := RGB(110, 110, 110);
  L.SetBounds(8, 251, 540, 18);

  L := TLabel.Create(Self);
  L.Parent := FTabBanda;
  L.Caption := Texto(txtBandNoteReapply);
  L.Font.Color := RGB(110, 110, 110);
  L.SetBounds(8, 275, 540, 18);
end;

procedure TConfigForm.CrearTabEscritorio;
var
  L: TLabel;
begin
  FRgFondo := TRadioGroup.Create(Self);
  FRgFondo.Parent := FTabEscritorio;
  FRgFondo.Caption := Texto(txtBackground);
  FRgFondo.Columns := 3;
  FRgFondo.Items.Add(Texto(txtBackgroundOriginal));
  FRgFondo.Items.Add(Texto(txtBackgroundSolid));
  FRgFondo.Items.Add(Texto(txtBackgroundGradient));
  FRgFondo.ItemIndex := Ord(FAjustes.DesktopFondo);
  FRgFondo.SetBounds(8, 6, 540, 50);
  FRgFondo.OnClick := CambioFondoEscritorio;

  FLblDesktopColor := TLabel.Create(Self);
  FLblDesktopColor.Parent := FTabEscritorio;
  FLblDesktopColor.Caption := Texto(txtDesktopSolidColor);
  FLblDesktopColor.SetBounds(8, 62, 140, 18);

  FSwDesktopColor := TPanel.Create(Self);
  FSwDesktopColor.Parent := FTabEscritorio;
  FSwDesktopColor.SetBounds(150, 58, 48, 26);
  FSwDesktopColor.BevelOuter := bvNone;
  FSwDesktopColor.Color := RgbATColor(FColorDesktop);
  FSwDesktopColor.StyleElements := [];

  FLblDesktopColorHex := TLabel.Create(Self);
  FLblDesktopColorHex.Parent := FTabEscritorio;
  FLblDesktopColorHex.Caption := RgbAHex(FColorDesktop);
  FLblDesktopColorHex.Font.Name := 'Consolas';
  FLblDesktopColorHex.Font.Size := 10;
  FLblDesktopColorHex.Font.Style := [fsBold];
  FLblDesktopColorHex.ParentFont := False;
  FLblDesktopColorHex.SetBounds(204, 62, 70, 20);

  FBtnDesktopColor := TButton.Create(Self);
  FBtnDesktopColor.Parent := FTabEscritorio;
  FBtnDesktopColor.Caption := Texto(txtChange);
  FBtnDesktopColor.SetBounds(278, 56, 110, 28);
  FBtnDesktopColor.OnClick := CambiarColorDesktop;

  FLblDesktopColor1 := TLabel.Create(Self);
  FLblDesktopColor1.Parent := FTabEscritorio;
  FLblDesktopColor1.Caption := Texto(txtDesktopGradientColor1);
  FLblDesktopColor1.SetBounds(8, 96, 140, 18);

  FSwDesktopColor1 := TPanel.Create(Self);
  FSwDesktopColor1.Parent := FTabEscritorio;
  FSwDesktopColor1.SetBounds(150, 92, 48, 26);
  FSwDesktopColor1.BevelOuter := bvNone;
  FSwDesktopColor1.Color := RgbATColor(FColorDesktop);
  FSwDesktopColor1.StyleElements := [];

  FLblDesktopColor1Hex := TLabel.Create(Self);
  FLblDesktopColor1Hex.Parent := FTabEscritorio;
  FLblDesktopColor1Hex.Caption := RgbAHex(FColorDesktop);
  FLblDesktopColor1Hex.Font.Name := 'Consolas';
  FLblDesktopColor1Hex.Font.Size := 10;
  FLblDesktopColor1Hex.Font.Style := [fsBold];
  FLblDesktopColor1Hex.ParentFont := False;
  FLblDesktopColor1Hex.SetBounds(204, 96, 70, 20);

  FBtnDesktopColor1 := TButton.Create(Self);
  FBtnDesktopColor1.Parent := FTabEscritorio;
  FBtnDesktopColor1.Caption := Texto(txtChange);
  FBtnDesktopColor1.SetBounds(278, 90, 110, 28);
  FBtnDesktopColor1.OnClick := CambiarColorDesktop1;

  FLblDesktopColor2 := TLabel.Create(Self);
  FLblDesktopColor2.Parent := FTabEscritorio;
  FLblDesktopColor2.Caption := Texto(txtDesktopGradientColor2);
  FLblDesktopColor2.SetBounds(8, 130, 140, 18);

  FSwDesktopColor2 := TPanel.Create(Self);
  FSwDesktopColor2.Parent := FTabEscritorio;
  FSwDesktopColor2.SetBounds(150, 126, 48, 26);
  FSwDesktopColor2.BevelOuter := bvNone;
  FSwDesktopColor2.Color := RgbATColor(FColorDesktop2);
  FSwDesktopColor2.StyleElements := [];

  FLblDesktopColor2Hex := TLabel.Create(Self);
  FLblDesktopColor2Hex.Parent := FTabEscritorio;
  FLblDesktopColor2Hex.Caption := RgbAHex(FColorDesktop2);
  FLblDesktopColor2Hex.Font.Name := 'Consolas';
  FLblDesktopColor2Hex.Font.Size := 10;
  FLblDesktopColor2Hex.Font.Style := [fsBold];
  FLblDesktopColor2Hex.ParentFont := False;
  FLblDesktopColor2Hex.SetBounds(204, 130, 70, 20);

  FBtnDesktopColor2 := TButton.Create(Self);
  FBtnDesktopColor2.Parent := FTabEscritorio;
  FBtnDesktopColor2.Caption := Texto(txtChange);
  FBtnDesktopColor2.SetBounds(278, 124, 110, 28);
  FBtnDesktopColor2.OnClick := CambiarColorDesktop2;

  FLblDesktopTextLarge := TLabel.Create(Self);
  FLblDesktopTextLarge.Parent := FTabEscritorio;
  FLblDesktopTextLarge.Caption := Texto(txtDesktopTextLarge);
  FLblDesktopTextLarge.SetBounds(8, 166, 140, 18);

  FEdDesktopGrande := TEdit.Create(Self);
  FEdDesktopGrande.Parent := FTabEscritorio;
  FEdDesktopGrande.MaxLength := 0;
  FEdDesktopGrande.Text := FAjustes.DesktopTextoGrande;
  FEdDesktopGrande.SetBounds(150, 162, 380, 24);
  FEdDesktopGrande.OnChange := CambioTextoEscritorio;

  FLblDesktopTextSmall := TLabel.Create(Self);
  FLblDesktopTextSmall.Parent := FTabEscritorio;
  FLblDesktopTextSmall.Caption := Texto(txtDesktopTextSmall);
  FLblDesktopTextSmall.SetBounds(8, 200, 140, 18);

  FEdDesktopPequeno := TEdit.Create(Self);
  FEdDesktopPequeno.Parent := FTabEscritorio;
  FEdDesktopPequeno.MaxLength := 0;
  FEdDesktopPequeno.Text := FAjustes.DesktopTextoPequeno;
  FEdDesktopPequeno.SetBounds(150, 196, 380, 24);
  FEdDesktopPequeno.OnChange := CambioTextoEscritorio;

  FLblDesktopFont := TLabel.Create(Self);
  FLblDesktopFont.Parent := FTabEscritorio;
  FLblDesktopFont.Caption := Texto(txtDesktopFont);
  FLblDesktopFont.SetBounds(8, 238, 140, 18);

  FCbDesktopFuente := TComboBox.Create(Self);
  FCbDesktopFuente.Parent := FTabEscritorio;
  FCbDesktopFuente.Style := csDropDown;
  FCbDesktopFuente.Items.Assign(Screen.Fonts);
  FCbDesktopFuente.Sorted := True;
  FCbDesktopFuente.Text := FAjustes.DesktopFuente;
  FCbDesktopFuente.SetBounds(150, 234, 200, 24);
  FCbDesktopFuente.OnChange := CambioTextoEscritorio;

  FLblDesktopFontSize := TLabel.Create(Self);
  FLblDesktopFontSize.Parent := FTabEscritorio;
  FLblDesktopFontSize.Caption := Texto(txtDesktopFontSize);
  FLblDesktopFontSize.SetBounds(370, 238, 80, 18);

  FSeDesktopTamano := TSpinEdit.Create(Self);
  FSeDesktopTamano.Parent := FTabEscritorio;
  FSeDesktopTamano.MinValue := 24;
  FSeDesktopTamano.MaxValue := 200;
  FSeDesktopTamano.Increment := 2;
  FSeDesktopTamano.Value := FAjustes.DesktopTamano;
  FSeDesktopTamano.SetBounds(450, 234, 60, 24);
  FSeDesktopTamano.OnChange := CambioTextoEscritorio;

  L := TLabel.Create(Self);
  L.Parent := FTabEscritorio;
  L.Caption := 'px';
  L.SetBounds(516, 238, 30, 18);

  FLblDesktopHint := TLabel.Create(Self);
  FLblDesktopHint.Parent := FTabEscritorio;
  FLblDesktopHint.Caption := Texto(txtDesktopHint);
  FLblDesktopHint.Font.Color := RGB(110, 110, 110);
  FLblDesktopHint.AutoSize := False;
  FLblDesktopHint.WordWrap := True;
  FLblDesktopHint.SetBounds(8, 276, 540, 34);
end;

procedure TConfigForm.AjustarFuentesPestanas(AControl: TWinControl);
var
  I: Integer;
  C: TControl;
begin
  for I := 0 to AControl.ControlCount - 1 do
  begin
    C := AControl.Controls[I];
    if C is TTabSheet then
      AjustarFuentesPestanas(TWinControl(C))
    else
    begin
      if (C <> FLblCartelHex) and (C <> FLblTextoHex) and
         (C <> FLblBandaHex) and (C <> FLblTextoBandaHex) and
         (C <> FLblDesktopColorHex) and (C <> FLblDesktopColor1Hex) and
         (C <> FLblDesktopColor2Hex) and
         (C <> FLblOpacidad) and (C <> FLblOpacidadTexto) and
         (C <> FLblEsquinas) and (C <> FLblAlto) then
      begin
        TControlAccess(C).ParentFont := False;
        TControlAccess(C).Font.Assign(Self.Font);
      end;
      if C is TWinControl then
        AjustarFuentesPestanas(TWinControl(C));
    end;
  end;
end;

procedure TConfigForm.AjustarControlesColorBanda;
var
  Habilitado: Boolean;
begin
  Habilitado := not FChkSyncColor.Checked;
  FLblBandaColor.Enabled := Habilitado;
  FSwBanda.Enabled := Habilitado;
  FLblBandaHex.Enabled := Habilitado;
  FBtnBandaColor.Enabled := Habilitado;
end;

procedure TConfigForm.CambioSincronizarColor(Sender: TObject);
begin
  if FChkSyncColor.Checked then
    FColorBanda := FColor;
  AjustarControlesColorBanda;
  ActualizarVista;
end;

procedure TConfigForm.CambiarColorDesktop(Sender: TObject);
begin
  if FondoEscritorio <> dfSolido then
    Exit;
  if ElegirColor(FColorDesktop) then
    ActualizarVista;
end;

procedure TConfigForm.CambiarColorDesktop1(Sender: TObject);
begin
  if FondoEscritorio <> dfDegradado then
    Exit;
  if ElegirColor(FColorDesktop) then
    ActualizarVista;
end;

procedure TConfigForm.CambiarColorDesktop2(Sender: TObject);
begin
  if FondoEscritorio <> dfDegradado then
    Exit;
  if ElegirColor(FColorDesktop2) then
    ActualizarVista;
end;

procedure TConfigForm.CambioFondoEscritorio(Sender: TObject);
begin
  FondoEscritorio := TDesktopFondo(FRgFondo.ItemIndex);
  AjustarControlesFondoEscritorio;
  ActualizarVista;
end;

procedure TConfigForm.CambioTextoEscritorio(Sender: TObject);
begin
  FPbPreview.Invalidate;
end;

procedure TConfigForm.AjustarControlesFondoEscritorio;
var
  Solido, Degradado: Boolean;
begin
  Solido := FondoEscritorio = dfSolido;
  Degradado := FondoEscritorio = dfDegradado;

  FLblDesktopColor.Enabled := Solido;
  FSwDesktopColor.Enabled := Solido;
  FLblDesktopColorHex.Enabled := Solido;
  FBtnDesktopColor.Enabled := Solido;

  FLblDesktopColor1.Enabled := Degradado;
  FSwDesktopColor1.Enabled := Degradado;
  FLblDesktopColor1Hex.Enabled := Degradado;
  FBtnDesktopColor1.Enabled := Degradado;

  FLblDesktopColor2.Enabled := Degradado;
  FSwDesktopColor2.Enabled := Degradado;
  FLblDesktopColor2Hex.Enabled := Degradado;
  FBtnDesktopColor2.Enabled := Degradado;
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
  Result.BandaColorSincronizado := FChkSyncColor.Checked;
  if FChkSyncColor.Checked then
    Result.BandaColor := FColor
  else
    Result.BandaColor := FColorBanda;
  Result.BandaAlto := FTbAlto.Position / 100;
  Result.BandaTexto := Trim(FEdTextoBanda.Text);
  Result.BandaColorTexto := FColorTextoBanda;
  Result.BandaAlineacion := AlineacionSeleccionada;
  Result.DesktopFondo := FondoEscritorio;
  Result.DesktopColor := FColorDesktop;
  Result.DesktopColor2 := FColorDesktop2;
  Result.DesktopTextoGrande := Trim(FEdDesktopGrande.Text);
  Result.DesktopTextoPequeno := Trim(FEdDesktopPequeno.Text);
  Result.DesktopFuente := Trim(FCbDesktopFuente.Text);
  Result.DesktopTamano := FSeDesktopTamano.Value;
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
  if FChkSyncColor.Checked then
    FColorBanda := FColor;

  FHeader.Color := RgbATColor(FColor);

  FSwCartel.Color := RgbATColor(FColor);
  FLblCartelHex.Caption := RgbAHex(FColor);
  FSwTexto.Color := RgbATColor(FColorTexto);
  FLblTextoHex.Caption := RgbAHex(FColorTexto);
  FSwBanda.Color := RgbATColor(FColorBanda);
  FLblBandaHex.Caption := RgbAHex(FColorBanda);
  FSwTextoBanda.Color := RgbATColor(FColorTextoBanda);
  FLblTextoBandaHex.Caption := RgbAHex(FColorTextoBanda);
  FSwDesktopColor.Color := RgbATColor(FColorDesktop);
  FLblDesktopColorHex.Caption := RgbAHex(FColorDesktop);
  FSwDesktopColor1.Color := RgbATColor(FColorDesktop);
  FLblDesktopColor1Hex.Caption := RgbAHex(FColorDesktop);
  FSwDesktopColor2.Color := RgbATColor(FColorDesktop2);
  FLblDesktopColor2Hex.Caption := RgbAHex(FColorDesktop2);

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
  Ancho, Alto, BandH, Bt, Bw, Bx, By: Integer;
  Escala: Single;
  Br: TGPLinearGradientBrush;
  Pincel: TGPSolidBrush;
  Src: TGPImage;
  Ruta: string;
  Dw, Dh, Dx, Dy, TamanoTexto: Integer;
  Dibujado: Boolean;
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

    Dibujado := False;
    if FondoEscritorio = dfOriginal then
    begin
      Ruta := DirectorioInstalacion + ArchivoFondoOriginal;
      if FileExists(Ruta) then
      begin
        try
          Src := TGPImage.Create(WideString(Ruta));
          try
            Escala := Max(Double(Ancho) / Src.GetWidth, Double(Alto) / Src.GetHeight);
            Dw := Ceil(Src.GetWidth * Escala);
            Dh := Ceil(Src.GetHeight * Escala);
            Dx := (Ancho - Dw) div 2;
            Dy := (Alto - Dh) div 2;
            G.DrawImage(Src, Dx, Dy, Dw, Dh);
            Dibujado := True;
          finally
            Src.Free;
          end;
        except
          Dibujado := False;
        end;
      end;
    end;

    if not Dibujado then
    begin
      if FondoEscritorio = dfSolido then
      begin
        Pincel := TGPSolidBrush.Create(ArgbDe(FColorDesktop, 255));
        try
          G.FillRectangle(Pincel, RF(0, 0, Ancho, Alto));
        finally
          Pincel.Free;
        end;
      end
      else if FondoEscritorio = dfDegradado then
      begin
        Br := TGPLinearGradientBrush.Create(RF(0, 0, Ancho, Alto),
          ArgbDe(FColorDesktop, 255), ArgbDe(FColorDesktop2, 255), 90);
        try
          G.FillRectangle(Br, RF(0, 0, Ancho, Alto));
        finally
          Br.Free;
        end;
      end
      else
      begin
        Br := TGPLinearGradientBrush.Create(RF(0, 0, Ancho, Alto),
          MakeColor(255, 30, 32, 42), MakeColor(255, 72, 76, 96), 35);
        try
          G.FillRectangle(Br, RF(0, 0, Ancho, Alto));
        finally
          Br.Free;
        end;
      end;
    end;

    TamanoTexto := Round(FSeDesktopTamano.Value * Alto / 1080);
    if TamanoTexto < 8 then
      TamanoTexto := 8;
    DibujarTextoEscritorio(G, RF(0, 0, Ancho, Alto), FEdDesktopGrande.Text,
      FEdDesktopPequeno.Text, FCbDesktopFuente.Text, TamanoTexto);

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
    Bw := AnchoDistintivo(Estilo.Texto, Estilo.Fuente, Bt);
    if Bw > Ancho - 28 then
    begin
      Escala := (Ancho - 28) / Bw;
      Bt := Round(Bt * Escala);
      if Bt < 20 then
        Bt := 20;
      Bw := Ancho - 28;
    end;
    Bx := Ancho - Bw - 14;
    By := Alto - Bt - 12;

    G.SetSmoothingMode(SmoothingModeAntiAlias);
    DibujarDistintivo(G, RF(Bx, By, Bw, Bt), Estilo);
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
  if FChkSyncColor.Checked then
    Exit;
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
