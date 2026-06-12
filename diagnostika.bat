@echo off
setlocal
set "OUT=%~dp0diag.txt"
echo === iMag Kassa DIAGNOSTIKA === > "%OUT%"
echo %date% %time% >> "%OUT%"
echo. >> "%OUT%"

echo [1] Windows versiyasy: >> "%OUT%"
ver >> "%OUT%"
echo. >> "%OUT%"

echo [2] Smart App Control kuyi (1=qosulu, 2=bagalau, 0=oshirulu): >> "%OUT%"
powershell -NoProfile -Command "try { (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy' -ErrorAction Stop).VerifiedAndReputablePolicyState } catch { 'belgisiz' }" >> "%OUT%"
echo. >> "%OUT%"

echo [3] VC++ runtime faildary: >> "%OUT%"
if exist "%SystemRoot%\System32\msvcp140.dll" (echo msvcp140.dll BAR >> "%OUT%") else (echo msvcp140.dll ZHOQ >> "%OUT%")
if exist "%SystemRoot%\System32\vcruntime140.dll" (echo vcruntime140.dll BAR >> "%OUT%") else (echo vcruntime140.dll ZHOQ >> "%OUT%")
if exist "%SystemRoot%\System32\vcruntime140_1.dll" (echo vcruntime140_1.dll BAR >> "%OUT%") else (echo vcruntime140_1.dll ZHOQ >> "%OUT%")
echo. >> "%OUT%"

echo [4] Ornatylgan exe: >> "%OUT%"
set "APP="
if exist "C:\Program Files\iMag Kassa\electronic_register.exe" set "APP=C:\Program Files\iMag Kassa\electronic_register.exe"
if exist "C:\Program Files (x86)\iMag Kassa\electronic_register.exe" set "APP=C:\Program Files (x86)\iMag Kassa\electronic_register.exe"
if not defined APP echo EXE TABYLMADY >> "%OUT%"
if defined APP echo "%APP%" >> "%OUT%"
echo. >> "%OUT%"

echo [5] Iske qosu synagy (10 sekund kutemiz)... >> "%OUT%"
if defined APP start "" "%APP%"
timeout /t 10 /nobreak > nul
tasklist /fi "imagename eq electronic_register.exe" >> "%OUT%"
echo. >> "%OUT%"

echo [6] startup.log mazmuny: >> "%OUT%"
if exist "%LOCALAPPDATA%\MagKassa\startup.log" (type "%LOCALAPPDATA%\MagKassa\startup.log" >> "%OUT%") else (echo LOG ZHOQ - exe murde iske qosylmagan >> "%OUT%")
echo. >> "%OUT%"

echo [7] App Control / Smart App Control bloktary: >> "%OUT%"
powershell -NoProfile -Command "try { Get-WinEvent -LogName 'Microsoft-Windows-CodeIntegrity/Operational' -MaxEvents 300 -ErrorAction Stop | Where-Object { $_.Id -in 3033,3034,3077,3089 } | Select-Object -First 8 | ForEach-Object { ('--- ' + $_.TimeCreated + '  Id=' + $_.Id); $_.Message } } catch { 'oqylmady: ' + $_.Exception.Message }" >> "%OUT%"
echo. >> "%OUT%"

echo [8] Qosymshanyn qulau zhazbalary (Application Error): >> "%OUT%"
powershell -NoProfile -Command "try { Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000,1001,1002} -MaxEvents 8 -ErrorAction Stop | ForEach-Object { ('--- ' + $_.TimeCreated); $_.Message } } catch { 'zhazba tabylmady' }" >> "%OUT%"
echo. >> "%OUT%"

echo [9] Defender karantini: >> "%OUT%"
powershell -NoProfile -Command "try { Get-MpThreatDetection -ErrorAction Stop | Select-Object -First 5 | ForEach-Object { $_.InitialDetectionTime; $_.Resources } } catch { 'zhazba tabylmady' }" >> "%OUT%"
echo. >> "%OUT%"

echo [10] Juyelik uaqyt (sertifikat ushin manyzdy): >> "%OUT%"
powershell -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd HH:mm:ss'" >> "%OUT%"
echo. >> "%OUT%"

echo [11] DNS: res.cloudinary.com >> "%OUT%"
powershell -NoProfile -Command "try { (Resolve-DnsName 'res.cloudinary.com' -ErrorAction Stop | Select-Object -First 3 | ForEach-Object { $_.Type.ToString() + ' ' + $_.IPAddress }) -join '; ' } catch { 'QATE: ' + $_.Exception.Message }" >> "%OUT%"
echo. >> "%OUT%"

echo [12] Cloudinary-den suret zhukteu synagy: >> "%OUT%"
powershell -NoProfile -Command "try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $r = Invoke-WebRequest -Uri 'https://res.cloudinary.com/demo/image/upload/sample.jpg' -UseBasicParsing -TimeoutSec 20; 'OK: status=' + $r.StatusCode + ', kolemi=' + $r.Content.Length + ' bayt' } catch { 'QATE: ' + $_.Exception.Message }" >> "%OUT%"
echo. >> "%OUT%"

echo [13] Google (salystyru ushin): >> "%OUT%"
powershell -NoProfile -Command "try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $r = Invoke-WebRequest -Uri 'https://firestore.googleapis.com' -UseBasicParsing -TimeoutSec 20; 'OK: status=' + $r.StatusCode } catch { if ($_.Exception.Response) { 'OK: server zhauap berdi (' + [int]$_.Exception.Response.StatusCode + ')' } else { 'QATE: ' + $_.Exception.Message } }" >> "%OUT%"
echo. >> "%OUT%"

echo === BITTI === >> "%OUT%"
notepad "%OUT%"
