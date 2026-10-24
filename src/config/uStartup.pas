unit uStartup;

{ Alta y baja del programa de inicio en HKCU\...\Run (por usuario, sin admin). }

interface

function InicioRegistrado: Boolean;
function RutaInicioRegistrada: string;
procedure RegistrarInicio(const RutaExe: string);
procedure DesregistrarInicio;

implementation

uses
  Winapi.Windows, System.Win.Registry, System.SysUtils, uPaths;

procedure LimpiarStartupApproved;
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create(KEY_READ or KEY_WRITE);
  try
    try
      Reg.RootKey := HKEY_CURRENT_USER;
      if Reg.OpenKey(ClaveStartupApproved, False) then
        if Reg.ValueExists(ValorRun) then
          Reg.DeleteValue(ValorRun);
    except
      // si no se puede, no es critico
    end;
  finally
    Reg.Free;
  end;
end;

function InicioRegistrado: Boolean;
var
  Reg: TRegistry;
begin
  Result := False;
  Reg := TRegistry.Create(KEY_READ);
  try
    try
      Reg.RootKey := HKEY_CURRENT_USER;
      if Reg.OpenKeyReadOnly(ClaveRun) then
        Result := Reg.ValueExists(ValorRun);
    except
      Result := False;
    end;
  finally
    Reg.Free;
  end;
end;

function RutaInicioRegistrada: string;
var
  Reg: TRegistry;
  S: string;
begin
  Result := '';
  Reg := TRegistry.Create(KEY_READ);
  try
    try
      Reg.RootKey := HKEY_CURRENT_USER;
      if Reg.OpenKeyReadOnly(ClaveRun) then
      begin
        S := Reg.ReadString(ValorRun);
        if (Length(S) >= 2) and (S[1] = '"') and (S[Length(S)] = '"') then
          S := Copy(S, 2, Length(S) - 2);
        Result := S;
      end;
    except
      Result := '';
    end;
  finally
    Reg.Free;
  end;
end;

procedure RegistrarInicio(const RutaExe: string);
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create(KEY_READ or KEY_WRITE);
  try
    try
      Reg.RootKey := HKEY_CURRENT_USER;
      if Reg.OpenKey(ClaveRun, True) then
        Reg.WriteString(ValorRun, '"' + RutaExe + '"');
    except
      // se comprueba despues con InicioRegistrado
    end;
  finally
    Reg.Free;
  end;
  LimpiarStartupApproved;
end;

procedure DesregistrarInicio;
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create(KEY_READ or KEY_WRITE);
  try
    try
      Reg.RootKey := HKEY_CURRENT_USER;
      if Reg.OpenKey(ClaveRun, False) then
        if Reg.ValueExists(ValorRun) then
          Reg.DeleteValue(ValorRun);
    except
      // nada que hacer
    end;
  finally
    Reg.Free;
  end;
  LimpiarStartupApproved;
end;

end.
