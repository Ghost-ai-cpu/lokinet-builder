; Script generated by the Inno Script Studio Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define MyAppName "loki-network"
#define MyAppVersion "0.0.3"
#define MyAppPublisher "Loki Project"
#define MyAppURL "https://loki.project"
#define MyAppExeName "lokinet.exe"
; change this to avoid compiler errors  -despair
#define DevPath "D:\dev\llarpd-builder\"
#include <idp.iss>

; inno setup script �2018 rick v for loki project
; all rights reserved? not sure which licence we're 
; under. lokinet appears to be under the zlib licence
; unless we've pivoted to the GPL for whatever reason.
; -despair

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{11335EAC-0385-4C78-A3AA-67731326B653}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
;AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={pf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
LicenseFile={#DevPath}deps\llarp\LICENSE
OutputDir={#DevPath}win32-setup
OutputBaseFilename=lokinet-win32
Compression=lzma
SolidCompression=yes
VersionInfoVersion=0.0.3
VersionInfoCompany=Loki Project
VersionInfoDescription=lokinet installer for win32
VersionInfoTextVersion=0.0.3
VersionInfoProductName=loki-network
VersionInfoProductVersion=0.0.3
VersionInfoProductTextVersion=0.0.3
InternalCompressLevel=ultra64
MinVersion=0,5.0
; uncomment if you are shipping the 64-bit build
;ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 0,6.1

[Files]
Source: "{#DevPath}build\lokinet.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#DevPath}daemon.ini"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#DevPath}build\dns.exe"; DestDir: "{app}"; Flags: ignoreversion
; comment these for 64-bit builds
Source: "{#DevPath}build\libgcc_s_sjlj-1.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#DevPath}build\libstdc++-6.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#DevPath}build\libwinpthread-1.dll"; DestDir: "{app}"; Flags: ignoreversion
; end
; uncomment these for 64-bit builds
;Source: "{#DevPath}build\libgcc_s_seh-1.dll"; DestDir: "{app}"; Flags: ignoreversion
;Source: "{#DevPath}build\libstdc++-6.dll"; DestDir: "{app}"; Flags: ignoreversion
;Source: "{#DevPath}build\libwinpthread-1.dll"; DestDir: "{app}"; Flags: ignoreversion
; end
Source: "{#DevPath}build\llarpc.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#DevPath}build\rcutil.exe"; DestDir: "{app}"; Flags: ignoreversion
; delet this after finishing setup, we only need it to extract the drivers
Source: "{#DevPath}win32-setup\7z.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall
; Copy the correct tuntap driver for the selected platform
Source: "{tmp}\tuntapv9.7z"; DestDir: "{app}"; Flags: ignoreversion external; OnlyBelowVersion: 0, 6.0
Source: "{tmp}\tuntapv9_n6.7z"; DestDir: "{app}"; Flags: ignoreversion external; MinVersion: 0,6.0

; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[UninstallDelete]
Type: filesandordirs; Name: "{app}\tap-windows*"

[UninstallRun]
Filename: "{app}\tap-windows-9.21.2\remove.bat"; WorkingDir: "{app}\tap-windows-9.21.2"; MinVersion: 0,6.0; Flags: runascurrentuser
Filename: "{app}\tap-windows-9.9.2\remove.bat"; WorkingDir: "{app}\tap-windows-9.9.2"; OnlyBelowVersion: 0,6.0; Flags: runascurrentuser

[Code]
procedure InitializeWizard();
var
  Version: TWindowsVersion;
  S: String;
begin
  GetWindowsVersionEx(Version);
  if Version.NTPlatform and
     (Version.Major < 6) and
     (Version.Minor = 0) then
  begin
    // Windows 2000, XP, .NET Svr 2003
    // these have a horribly crippled WinInet that issues Triple-DES as its most secure
    // cipher suite
    idpAddFile('http://www.rvx86.net/files/tuntapv9.7z', ExpandConstant('{tmp}\tuntapv9.7z'));
  end
  else
  begin
    // current versions of windows :-)
    idpAddFile('https://github.com/despair86/lokinet-builder/raw/master/contrib/tuntapv9-ndis/tap-windows-9.21.2.7z', ExpandConstant('{tmp}\tuntapv9_n6.7z'));
  end;
    idpDownloadAfter(wpReady);
end;

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:ProgramOnTheWeb,{#MyAppName}}"; Filename: "{#MyAppURL}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: quicklaunchicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
; wait until either one of these terminates
Filename: "{tmp}\7z.exe"; Description: "extract TUN/TAP-v9 driver"; WorkingDir: "{app}"; Parameters: "x tuntapv9.7z"; OnlyBelowVersion: 0, 6.0; StatusMsg: "Extracting driver..."; Flags: runascurrentuser
Filename: "{tmp}\7z.exe"; Description: "extract TUN/TAP-v9 driver"; WorkingDir: "{app}"; Parameters: "x tuntapv9_n6.7z"; MinVersion: 0, 6.0; StatusMsg: "Extracting driver..."; Flags: runascurrentuser 
; then ask to install driver
Filename: "{app}\tap-windows-9.9.2\install.bat"; Description: "Install TUN/TAP-v9 driver"; WorkingDir: "{app}\tap-windows-9.9.2"; OnlyBelowVersion: 0, 6.0; StatusMsg: "Installing driver..."; Flags: runascurrentuser postinstall
Filename: "{app}\tap-windows-9.21.2\install.bat"; Description: "Install TUN/TAP-v9 driver"; WorkingDir: "{app}\tap-windows-9.21.2"; MinVersion: 0, 6.0; StatusMsg: "Installing driver..."; Flags: runascurrentuser postinstall 
