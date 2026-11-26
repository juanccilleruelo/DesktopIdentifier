unit uGitBranch;

{ Lectura de la rama Git actual sin ejecutar git.exe ni usar VCL.
  La usan el configurador (vista previa) y el host (texto del cartel). }

interface

function InfoRepositorio(const Ruta: string; out Directorio, Rama: string): Boolean;
function TextoRepositorio(const Ruta: string): string;

implementation

uses
  Winapi.Windows, System.SysUtils;

const
  MAX_TEXTO = 64 * 1024;

function LeerArchivo(const Ruta: string): string;
var
  H: THandle;
  Tam: DWORD;
  Leido: DWORD;
  Datos: TBytes;
  Raw: RawByteString;
begin
  Result := '';
  H := CreateFileW(PWideChar(Ruta), GENERIC_READ,
    FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE, nil,
    OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if H = INVALID_HANDLE_VALUE then
    Exit;
  try
    Tam := GetFileSize(H, nil);
    if (Tam = INVALID_FILE_SIZE) or (Tam > MAX_TEXTO) then
      Exit;
    if Tam = 0 then
      Exit;
    SetLength(Datos, Tam);
    if not ReadFile(H, Datos[0], Tam, Leido, nil) then
      Exit;
    if Leido = 0 then
      Exit;
    SetLength(Datos, Leido);
    SetString(Raw, PAnsiChar(@Datos[0]), Leido);
    Result := UTF8ToString(Raw);
    if (Length(Result) > 0) and (Result[1] = #$FEFF) then
      Delete(Result, 1, 1);
  finally
    CloseHandle(H);
  end;
end;

function EsRutaAbsoluta(const Ruta: string): Boolean;
begin
  Result := ((Length(Ruta) >= 2) and (Ruta[2] = ':')) or
            ((Length(Ruta) >= 2) and (Ruta[1] = '\') and (Ruta[2] = '\'));
end;

function InfoRepositorio(const Ruta: string; out Directorio, Rama: string): Boolean;
var
  Base, Dir, Padre, Git, Head, Contenido, GitDir, H, Ref: string;
begin
  Result := False;
  Directorio := '';
  Rama := '';

  Base := Trim(Ruta);
  if Base = '' then
    Exit;
  Base := ExpandFileName(Base);
  if FileExists(Base) then
    Base := ExtractFileDir(Base);
  Dir := ExcludeTrailingPathDelimiter(Base);
  if Dir = '' then
    Exit;

  while Dir <> '' do
  begin
    Git := IncludeTrailingPathDelimiter(Dir) + '.git';
    Head := '';
    if DirectoryExists(Git) then
      Head := IncludeTrailingPathDelimiter(Git) + 'HEAD'
    else if FileExists(Git) then
    begin
      Contenido := Trim(LeerArchivo(Git));
      if (Length(Contenido) > 7) and
         SameText(Copy(Contenido, 1, 7), 'gitdir:') then
      begin
        GitDir := Trim(Copy(Contenido, 8, MaxInt));
        if GitDir <> '' then
        begin
          if not EsRutaAbsoluta(GitDir) then
            GitDir := ExpandFileName(IncludeTrailingPathDelimiter(Dir) + GitDir);
          Head := IncludeTrailingPathDelimiter(GitDir) + 'HEAD';
        end;
      end;
    end;

    if Head <> '' then
    begin
      H := Trim(LeerArchivo(Head));
      if H = '' then
        Rama := '(sin rama)'
      else if (Length(H) >= 4) and SameText(Copy(H, 1, 4), 'ref:') then
      begin
        Ref := Trim(Copy(H, 5, MaxInt));
        if (Length(Ref) >= 11) and SameText(Copy(Ref, 1, 11), 'refs/heads/') then
          Rama := Copy(Ref, 12, MaxInt)
        else
          Rama := Ref;
        if Rama = '' then
          Rama := '(sin rama)';
      end
      else
        Rama := '(detached) ' + Copy(H, 1, 8);

      Directorio := Dir;
      Result := True;
      Exit;
    end;

    Padre := ExtractFileDir(Dir);
    if (Padre = '') or SameText(Padre, Dir) then
      Break;
    Dir := Padre;
  end;
end;

function TextoRepositorio(const Ruta: string): string;
var
  Dir, Rama, Nombre: string;
begin
  Result := '';
  if not InfoRepositorio(Ruta, Dir, Rama) then
    Exit;
  Nombre := ExtractFileName(ExcludeTrailingPathDelimiter(Dir));
  if Nombre = '' then
    Nombre := Dir;
  Result := Nombre + ':  ' + Rama;
end;

end.
