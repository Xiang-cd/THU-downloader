[Setup]
AppName=THU Downloader
AppVersion={#AppVersion}
AppPublisher=Xiang-cd
WizardStyle=modern
Compression=lzma2
SolidCompression=yes
AppPublisherURL=https://github.com/Xiang-cd/THU-downloader
AppSupportURL=https://github.com/Xiang-cd/THU-downloader/issues
AppUpdatesURL=https://github.com/Xiang-cd/THU-downloader/releases
DefaultDirName={autopf}\THU Downloader
DefaultGroupName=THU Downloader
LicenseFile=
OutputDir=Output
OutputBaseFilename=thu_downloader-installer
SetupIconFile=logo.ico
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "thu_downloader.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{group}\THU Downloader"; Filename: "{app}\thu_downloader.exe"
Name: "{group}\{cm:UninstallProgram,THU Downloader}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\THU Downloader"; Filename: "{app}\thu_downloader.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\thu_downloader.exe"; Description: "{cm:LaunchProgram,THU Downloader}"; Flags: nowait postinstall skipifsilent