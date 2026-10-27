unit uHostWindow;

{ Ventana del cartel sin VCL: ventana Win32 por capas, DIB premultiplicado,
  UpdateLayeredWindow y temporizador. Solo pinta el cartel. }

interface

uses
  Winapi.Windows;

function IniciarHost: Boolean;

implementation

uses
  Winapi.Messages, Winapi.MultiMon, System.SysUtils, System.Math, System.Types,
  Winapi.GDIPAPI, Winapi.GDIPOBJ,
  uPaths, uSettings, uUtils, uBadgeRender, Languages;

const
  TIMER_REPOSICIONAR   = 1;
  INTERVALO_REPOSICION = 3000;
  WM_DPICHANGED_MSG    = $02E0;

var
  FVentana: HWND = 0;
  FTimer: UINT_PTR = 0;
  FAjustes: TSettings;
  FMensajeRecarga: Cardinal = 0;
  FMensajeSalir: Cardinal = 0;
  GMonitores: array[0..15] of HMONITOR;
  GMonCount: Integer = 0;

function WndProc(hWnd: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall; forward;
procedure Reposicionar(Forzar: Boolean); forward;
procedure AplicarCapa(Ancho, Alto: Integer); forward;

function EnumMonitoresProc(hMon: HMONITOR; hdc: HDC; lprc: PRect;
  Datos: LPARAM): BOOL; stdcall;
begin
  if GMonCount <= High(GMonitores) then
    GMonitores[GMonCount] := hMon;
  Inc(GMonCount);
  Result := True;
end;

procedure InvalidarMonitores;
begin
  GMonCount := 0;
end;

function MonitorDeIndice(Indice: Integer): HMONITOR;
var
  I: Integer;
begin
  if Indice <= 0 then
    Exit(MonitorFromPoint(Point(0, 0), MONITOR_DEFAULTTOPRIMARY));

  if GMonCount = 0 then
    EnumDisplayMonitors(0, nil, @EnumMonitoresProc, 0);
  if GMonCount = 0 then
    Exit(MonitorFromPoint(Point(0, 0), MONITOR_DEFAULTTOPRIMARY));

  I := Indice;
  if I >= GMonCount then
    I := 0;
  if I = 0 then
    Result := MonitorFromPoint(Point(0, 0), MONITOR_DEFAULTTOPRIMARY)
  else
    Result := GMonitores[I];
end;

procedure AsegurarEstilos;
var
  Estilo: Integer;
begin
  if FVentana = 0 then
    Exit;
  Estilo := GetWindowLong(FVentana, GWL_EXSTYLE);
  Estilo := Estilo or WS_EX_LAYERED or WS_EX_TRANSPARENT or
    WS_EX_TOOLWINDOW or WS_EX_NOACTIVATE;
  SetWindowLong(FVentana, GWL_EXSTYLE, Estilo);
end;

{ Deja el working set al minimo tras pintar: el cartel pasa la mayor parte del
  tiempo sin hacer nada y no necesita tener GDI+ y las DLLs residentes. }
procedure RecortarMemoria;
begin
  SetProcessWorkingSetSize(GetCurrentProcess, SIZE_T(-1), SIZE_T(-1));
end;

procedure Reposicionar(Forzar: Boolean);
var
  Mon: HMONITOR;
  Info: TMonitorInfo;
  Dpi: Cardinal;
  Escala: Single;
  X, Y: Integer;
  Ancho, Alto: Integer;
  WR: TRect;
  Cambio: Boolean;
begin
  if FVentana = 0 then
    Exit;

  Mon := MonitorDeIndice(FAjustes.Pantalla);
  if Mon = 0 then
    Exit;
  Info.cbSize := SizeOf(Info);
  if not GetMonitorInfo(Mon, @Info) then
    Exit;

  Dpi := DpiDeMonitor(Mon);
  if Dpi = 0 then
    Dpi := DpiDeVentana(FVentana);
  Escala := Dpi / 96;

  Alto := Round(FAjustes.Tamano * Escala);
  if Alto < 24 then
    Alto := 24;
  Ancho := AnchoDistintivo(FAjustes.Texto, FAjustes.Fuente, Alto);
  if Ancho < Alto then
    Ancho := Alto;

  X := Info.rcWork.Right - Round(FAjustes.MargenDerecha * Escala) - Ancho;
  Y := Info.rcWork.Bottom - Round(FAjustes.MargenInferior * Escala) - Alto;

  Cambio := Forzar;
  if not Cambio then
  begin
    if GetWindowRect(FVentana, WR) then
      Cambio := (WR.Left <> X) or (WR.Top <> Y) or
        ((WR.Right - WR.Left) <> Ancho) or ((WR.Bottom - WR.Top) <> Alto)
    else
      Cambio := True;
  end;

  if Cambio then
  begin
    SetWindowPos(FVentana, HWND_TOPMOST, X, Y, Ancho, Alto, SWP_NOACTIVATE);
    AplicarCapa(Ancho, Alto);
  end
  else
    SetWindowPos(FVentana, HWND_TOPMOST, 0, 0, 0, 0,
      SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE);
end;

procedure AplicarCapa(Ancho, Alto: Integer);
var
  Estilo: TBadgeStyle;
  Bmp: TGPBitmap;
  G: TGPGraphics;
  Data: TBitmapData;
  Bmi: TBitmapInfo;
  Bits: Pointer;
  Hbm, OldObj: HGDIOBJ;
  HdcScreen, HdcMem: HDC;
  Blend: TBlendFunction;
  PtSrc, PtDst: TPoint;
  Sz: TSize;
  WR: TRect;
  SrcRow, DstRow: PByte;
  S, D: PByte;
  X, Y, A: Integer;
begin
  if (FVentana = 0) or (Ancho < 1) or (Alto < 1) then
    Exit;

  AsegurarEstilos;

  Estilo.Texto := FAjustes.Texto;
  Estilo.Color := FAjustes.Color;
  Estilo.ColorTexto := FAjustes.ColorTexto;
  Estilo.OpacidadPanel := FAjustes.OpacidadPanel;
  Estilo.OpacidadLetra := FAjustes.OpacidadLetra;
  Estilo.Esquinas := FAjustes.Esquinas;
  Estilo.Fuente := FAjustes.Fuente;
  Estilo.Tamano := Alto;

  Bmp := TGPBitmap.Create(Ancho, Alto, PixelFormat32bppARGB);
  try
    G := TGPGraphics.Create(Bmp);
    try
      G.SetSmoothingMode(SmoothingModeAntiAlias);
      G.SetPixelOffsetMode(PixelOffsetModeHighQuality);
      G.SetTextRenderingHint(TextRenderingHintAntiAliasGridFit);
      G.Clear(MakeColor(0, 0, 0, 0));
      DibujarDistintivo(G, RF(0, 0, Ancho, Alto), Estilo);
    finally
      G.Free;
    end;

    FillChar(Bmi, SizeOf(Bmi), 0);
    Bmi.bmiHeader.biSize := SizeOf(TBitmapInfoHeader);
    Bmi.bmiHeader.biWidth := Ancho;
    Bmi.bmiHeader.biHeight := -Alto;
    Bmi.bmiHeader.biPlanes := 1;
    Bmi.bmiHeader.biBitCount := 32;
    Bmi.bmiHeader.biCompression := BI_RGB;

    Bits := nil;
    HdcScreen := GetDC(0);
    try
      Hbm := CreateDIBSection(HdcScreen, Bmi, DIB_RGB_COLORS, Bits, 0, 0);
      if (Hbm = 0) or (Bits = nil) then
        Exit;

      try
        Bmp.LockBits(MakeRect(0, 0, Ancho, Alto), ImageLockModeRead,
          PixelFormat32bppARGB, Data);
        try
          SrcRow := PByte(Data.Scan0);
          if Data.Stride < 0 then
            Inc(SrcRow, NativeInt(Alto - 1) * (-Data.Stride));
          DstRow := PByte(Bits);
          for Y := 0 to Alto - 1 do
          begin
            S := SrcRow;
            D := DstRow;
            for X := 0 to Ancho - 1 do
            begin
              // UpdateLayeredWindow espera alfa premultiplicado.
              A := S[3];
              if A = 255 then
              begin
                D[0] := S[0];
                D[1] := S[1];
                D[2] := S[2];
                D[3] := 255;
              end
              else if A = 0 then
                PCardinal(D)^ := 0
              else
              begin
                D[0] := Byte((Integer(S[0]) * A) div 255);
                D[1] := Byte((Integer(S[1]) * A) div 255);
                D[2] := Byte((Integer(S[2]) * A) div 255);
                D[3] := Byte(A);
              end;
              Inc(S, 4);
              Inc(D, 4);
            end;
            Inc(SrcRow, Data.Stride);
            Inc(DstRow, Ancho * 4);
          end;
        finally
          Bmp.UnlockBits(Data);
        end;

        HdcMem := CreateCompatibleDC(HdcScreen);
        try
          OldObj := SelectObject(HdcMem, Hbm);
          try
            if GetWindowRect(FVentana, WR) then
            begin
              PtDst.X := WR.Left;
              PtDst.Y := WR.Top;
            end
            else
            begin
              PtDst.X := 0;
              PtDst.Y := 0;
            end;
            PtSrc.X := 0;
            PtSrc.Y := 0;
            Sz.cx := Ancho;
            Sz.cy := Alto;

            Blend.BlendOp := AC_SRC_OVER;
            Blend.BlendFlags := 0;
            Blend.SourceConstantAlpha := 255;
            Blend.AlphaFormat := AC_SRC_ALPHA;

            UpdateLayeredWindow(FVentana, HdcScreen, @PtDst, @Sz, HdcMem,
              @PtSrc, 0, @Blend, ULW_ALPHA);
          finally
            SelectObject(HdcMem, OldObj);
          end;
        finally
          DeleteDC(HdcMem);
        end;
      finally
        DeleteObject(Hbm);
      end;
    finally
      ReleaseDC(0, HdcScreen);
    end;
  finally
    Bmp.Free;
  end;

  RecortarMemoria;
end;

function WndProc(hWnd: HWND; Msg: UINT; wParam: WPARAM;
  lParam: LPARAM): LRESULT; stdcall;
begin
  if (FMensajeRecarga <> 0) and (Msg = FMensajeRecarga) then
  begin
    FAjustes := CargarAjustes(RutaIniInstalada);
    Reposicionar(True);
    Exit(0);
  end;

  if (FMensajeSalir <> 0) and (Msg = FMensajeSalir) then
  begin
    DestroyWindow(hWnd);
    Exit(0);
  end;

  case Msg of
    WM_TIMER:
      if wParam = TIMER_REPOSICIONAR then
      begin
        Reposicionar(False);
        Exit(0);
      end;
    WM_DISPLAYCHANGE:
      begin
        InvalidarMonitores;
        Reposicionar(True);
        Exit(0);
      end;
    WM_DPICHANGED_MSG:
      begin
        Reposicionar(True);
        Exit(0);
      end;
    WM_SETTINGCHANGE:
      begin
        Reposicionar(True);
        Exit(0);
      end;
    WM_CLOSE:
      begin
        DestroyWindow(hWnd);
        Exit(0);
      end;
    WM_DESTROY:
      begin
        if FTimer <> 0 then
          KillTimer(hWnd, FTimer);
        FTimer := 0;
        FVentana := 0;
        PostQuitMessage(0);
        Exit(0);
      end;
  end;

  Result := DefWindowProc(hWnd, Msg, wParam, lParam);
end;

function IniciarHost: Boolean;
var
  WC: WNDCLASSEX;
  HInst: THandle;
begin
  Result := False;

  FAjustes := CargarAjustes(RutaIniInstalada);
  FMensajeRecarga := RegisterWindowMessage(PChar(MensajeRecarga));
  FMensajeSalir := RegisterWindowMessage(PChar(MensajeSalir));

  HInst := GetModuleHandle(nil);
  ZeroMemory(@WC, SizeOf(WC));
  WC.cbSize := SizeOf(WC);
  WC.style := 0;
  WC.lpfnWndProc := @WndProc;
  WC.hInstance := HInst;
  WC.hCursor := 0;
  WC.hbrBackground := 0;
  WC.lpszClassName := PChar(ClaseVentanaHost);
  if RegisterClassEx(WC) = 0 then
  begin
    if GetLastError <> ERROR_CLASS_ALREADY_EXISTS then
      Exit;
  end;

  FVentana := CreateWindowEx(
    WS_EX_LAYERED or WS_EX_TRANSPARENT or WS_EX_TOOLWINDOW or WS_EX_NOACTIVATE,
    PChar(ClaseVentanaHost), PChar(Texto(txtHostWindowTitle)), WS_POPUP,
    0, 0, 1, 1, 0, 0, HInst, nil);
  if FVentana = 0 then
    Exit;

  AsegurarEstilos;
  Reposicionar(True);
  ShowWindow(FVentana, SW_SHOWNOACTIVATE);
  FTimer := SetTimer(FVentana, TIMER_REPOSICIONAR, INTERVALO_REPOSICION, nil);
  RecortarMemoria;
  Result := True;
end;

end.
