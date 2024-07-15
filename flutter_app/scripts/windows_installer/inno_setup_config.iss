[Setup]
AppName=thu_downloader
AppVersion={#AppVersion}
AppPublisher=Xinag-cd
WizardStyle=modern
Compression=lzma2
SolidCompression=yes
DefaultDirName={autopf}\thu_downloader\
DefaultGroupName=thu_downloader
SetupIconFile=logo.ico
UninstallDisplayIcon={app}\thu_downloader.exe
UninstallDisplayName=thu_downloader
VersionInfoVersion={#AppVersion}
UsePreviousAppDir=no

[Files]
Source: "thu_downloader.exe";DestDir: "{app}";DestName: "thu_downloader.exe"
Source: "*.dll";DestDir: "{app}";
Source: "data\*";DestDir: "{app}\data\"; Flags: recursesubdirs

[Icons]
Name: "{userdesktop}\thu_downloader"; Filename: "{app}\thu_downloader.exe"
Name: "{group}\thu_downloader"; Filename: "{app}\thu_downloader.exe"
