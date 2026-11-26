unit uGitBranch;

{ Lectura de la rama Git actual sin VCL. Normalmente lee .git/HEAD;
  para un commit detached consulta tags/ramas con git.exe si esta disponible. }

interface

function InfoRepositorio(const Ruta: string; out Directorio, Rama: string): Boolean;
function TextoRepositorio(const Ruta: string): string;

implementation

uses
  Winapi.Windows, System.SysUtils;

const
  MAX_TEXTO = 64 * 1024;

var
  UltimaRuta, UltimaRama, UltimoTexto: string;

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

function EjecutarGit(const Ruta, Argumentos: string): string;
var
  SA: TSecurityAttributes;
  SI: TStartupInfoW;
  PI: TProcessInformation;
  HRead, HWrite: THandle;
  Buf: array[0..4095] of AnsiChar;
  Leido, Codigo: DWORD;
  Raw, Trozo: RawByteString;
  Cmd: string;
begin
  Result := '';
  HRead := 0;
  HWrite := 0;
  FillChar(SA, SizeOf(SA), 0);
  SA.nLength := SizeOf(SA);
  SA.bInheritHandle := True;
  if not CreatePipe(HRead, HWrite, @SA, 0) then
    Exit;
  try
    SetHandleInformation(HRead, HANDLE_FLAG_INHERIT, 0);
    FillChar(SI, SizeOf(SI), 0);
    SI.cb := SizeOf(SI);
    SI.dwFlags := STARTF_USESTDHANDLES;
    SI.hStdInput := GetStdHandle(STD_INPUT_HANDLE);
    SI.hStdOutput := HWrite;
    SI.hStdError := HWrite;
    FillChar(PI, SizeOf(PI), 0);
    Cmd := 'git.exe -C "' +
      StringReplace(ExcludeTrailingPathDelimiter(Ruta), '"', '\"', [rfReplaceAll]) +
      '" ' + Argumentos;
    if not CreateProcessW(nil, PWideChar(Cmd), nil, nil, True,
      CREATE_NO_WINDOW, nil, nil, SI, PI) then
      Exit;

    CloseHandle(HWrite);
    HWrite := 0;

    Raw := '';
    while ReadFile(HRead, Buf[0], SizeOf(Buf), Leido, nil) and (Leido > 0) do
    begin
      SetString(Trozo, PAnsiChar(@Buf[0]), Leido);
      Raw := Raw + Trozo;
    end;

    WaitForSingleObject(PI.hProcess, 5000);
    Codigo := 1;
    GetExitCodeProcess(PI.hProcess, Codigo);
    CloseHandle(PI.hThread);
    CloseHandle(PI.hProcess);
    if Codigo = 0 then
      Result := UTF8ToString(Raw);
  finally
    if HWrite <> 0 then
      CloseHandle(HWrite);
    if HRead <> 0 then
      CloseHandle(HRead);
  end;
end;

function PrimeraLinea(const Texto: string): string;
var
  P: Integer;
begin
  Result := Texto;
  P := Pos(#10, Result);
  if P > 0 then
    Result := Copy(Result, 1, P - 1);
  P := Pos(#13, Result);
  if P > 0 then
    Result := Copy(Result, 1, P - 1);
  Result := Trim(Result);
end;

function EtiquetaDeCommit(const Ruta, Hash: string): string;
var
  Salida: string;
begin
  Result := '';
  Salida := EjecutarGit(Ruta, 'describe --tags --exact-match ' + Hash);
  Result := PrimeraLinea(Salida);
  if Result <> '' then
    Exit;
  Salida := EjecutarGit(Ruta, 'tag --points-at ' + Hash);
  Result := PrimeraLinea(Salida);
end;

function RamaQueContiene(const Ruta, Hash: string): string;
var
  Salida, Linea: string;
  P, Q: Integer;
begin
  Result := '';
  Salida := EjecutarGit(Ruta, 'branch --contains ' + Hash +
    ' --format=%(refname:short)');
  P := 1;
  while P <= Length(Salida) do
  begin
    Q := P;
    while (Q <= Length(Salida)) and (Salida[Q] <> #10) do
      Inc(Q);
    Linea := Trim(Copy(Salida, P, Q - P));
    if (Length(Linea) >= 2) and (Copy(Linea, 1, 2) = '* ') then
      Linea := Trim(Copy(Linea, 3, MaxInt));
    if Linea <> '' then
    begin
      if SameText(Linea, 'main') then
        Exit('main');
      if Result = '' then
        Result := Linea;
    end;
    P := Q + 1;
  end;
end;

function TextoRepositorio(const Ruta: string): string;
var
  Dir, Rama, RamaOriginal, Nombre, Hash, Etiqueta, RamaBase, Clave: string;
begin
  Result := '';
  if not InfoRepositorio(Ruta, Dir, Rama) then
    Exit;

  Clave := Trim(Ruta);
  if (Clave = UltimaRuta) and (Rama = UltimaRama) then
    Exit(UltimoTexto);

  RamaOriginal := Rama;
  Nombre := ExtractFileName(ExcludeTrailingPathDelimiter(Dir));
  if Nombre = '' then
    Nombre := Dir;

  if (Length(Rama) >= 11) and SameText(Copy(Rama, 1, 11), '(detached) ') then
  begin
    Hash := Trim(Copy(Rama, 12, MaxInt));
    Etiqueta := EtiquetaDeCommit(Ruta, Hash);
    if Etiqueta <> '' then
      Rama := Etiqueta
    else
    begin
      RamaBase := RamaQueContiene(Ruta, Hash);
      if RamaBase = '' then
        RamaBase := 'main';
      Rama := RamaBase + ': ' + Copy(Hash, 1, 8);
    end;
  end;

  Result := Nombre + ':  ' + Rama;
  UltimaRuta := Clave;
  UltimaRama := RamaOriginal;
  UltimoTexto := Result;
end;

end.
