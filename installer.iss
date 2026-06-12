[Setup]
AppName=iMag Kassa
AppVersion=1.0.1
AppPublisher=iMag Kassa
DefaultDirName={autopf}\iMag Kassa
DefaultGroupName=iMag Kassa
OutputDir=C:\Users\taraz\electronic_register\installer_output
OutputBaseFilename=iMagKassa_Setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[Tasks]
Name: "desktopicon"; Description: "Рабочий стол белгішесін жасау"; GroupDescription: "Қосымша белгішелер:"; Flags: unchecked

[Files]
Source: "C:\Users\taraz\electronic_register\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Excludes: "*.msix,*.lib,*.exp"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Redist\MSVC\14.51.36231\vc_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Icons]
Name: "{group}\iMag Kassa"; Filename: "{app}\electronic_register.exe"
Name: "{autodesktop}\iMag Kassa"; Filename: "{app}\electronic_register.exe"; Tasks: desktopicon

[Run]
Filename: "{tmp}\vc_redist.x64.exe"; Parameters: "/install /quiet /norestart"; StatusMsg: "Visual C++ Runtime орнатылуда..."; Flags: waituntilterminated
Filename: "{app}\electronic_register.exe"; Description: "iMag Kassa іске қосу"; Flags: nowait postinstall skipifsilent
