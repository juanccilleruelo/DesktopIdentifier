; Desktop Identifier installer (Inno Setup 6)

#define AppName "Desktop Identifier"
#define AppVersion "1.1.0.0"
#define AppExe "DesktopIdentifier.exe"
#define HostExe "DesktopIdentifierHost.exe"
#define AppId "{{DA80272E-79ED-4F45-ABA7-5315C5CD27A1}"

[Setup]
AppId={#AppId}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher=Desktop Identifier
AppCopyright=Copyright (C) 2026 Desktop Identifier
DefaultDirName={localappdata}\Programs\Desktop Identifier
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=..\dist
OutputBaseFilename=DesktopIdentifier-Setup
SetupIconFile=..\src\config\DesktopIdentifier.ico
UninstallDisplayIcon={app}\{#AppExe}
UninstallDisplayName={#AppName}
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes
RestartApplications=no
UsePreviousAppDir=yes
MinVersion=10.0
VersionInfoVersion={#AppVersion}
VersionInfoProductName={#AppName}
VersionInfoCompany=Desktop Identifier
VersionInfoDescription={#AppName} Setup

[Languages]
Name: "en"; MessagesFile: "compiler:Default.isl"
Name: "es"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "fr"; MessagesFile: "compiler:Languages\French.isl"
Name: "it"; MessagesFile: "compiler:Languages\Italian.isl"
Name: "de"; MessagesFile: "compiler:Languages\German.isl"

[CustomMessages]
en.InstallHostStatus=Installing the startup program...
en.InstallHostError=The startup program could not be installed. You can repair it from the configurator.
en.LaunchApp=Launch Desktop Identifier
en.StartMenuComment=Configure the badge and band
es.InstallHostStatus=Instalando el programa de inicio...
es.InstallHostError=No se pudo instalar el programa de inicio. Puedes repararlo desde el configurador.
es.LaunchApp=Abrir Desktop Identifier
es.StartMenuComment=Configurar el cartel y la banda
fr.InstallHostStatus=Installation du programme de démarrage...
fr.InstallHostError=Le programme de démarrage n’a pas pu être installé. Vous pouvez le réparer depuis le configurateur.
fr.LaunchApp=Lancer Desktop Identifier
fr.StartMenuComment=Configurer le badge et la bande
it.InstallHostStatus=Installazione del programma di avvio...
it.InstallHostError=Impossibile installare il programma di avvio. Puoi ripararlo dal configuratore.
it.LaunchApp=Avvia Desktop Identifier
it.StartMenuComment=Configura badge e banda
de.InstallHostStatus=Startprogramm wird installiert...
de.InstallHostError=Das Startprogramm konnte nicht installiert werden. Sie können es im Konfigurator reparieren.
de.LaunchApp=Desktop Identifier starten
de.StartMenuComment=Kennzeichen und Band konfigurieren

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\bin\{#AppExe}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\bin\{#HostExe}"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExe}"; WorkingDir: "{app}"; Comment: "{cm:StartMenuComment}"; IconFilename: "{app}\{#AppExe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExe}"; Description: "{cm:LaunchApp}"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "{app}\{#AppExe}"; Parameters: "/uninstall /discard"; Flags: runhidden waituntilterminated skipifdoesntexist; RunOnceId: "RemoveHost"

[UninstallDelete]
Type: filesandordirs; Name: "{localappdata}\DesktopIdentifier"

[Registry]
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: none; ValueName: "DesktopIdentifier"; Flags: uninsdeletevalue

[Code]
function InstallHost: Boolean;
var
  ResultCode: Integer;
begin
  ResultCode := -1;
  if not WizardSilent then
    WizardForm.StatusLabel.Caption := ExpandConstant('{cm:InstallHostStatus}');

  Result := Exec(ExpandConstant('{app}\{#AppExe}'), '/install',
    ExpandConstant('{app}'), SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Result := Result and (ResultCode = 0);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    if not InstallHost then
    begin
      if WizardSilent then
        Log('Desktop Identifier: host installation failed.')
      else
        MsgBox(ExpandConstant('{cm:InstallHostError}'), mbError, MB_OK);
    end;
  end;
end;
