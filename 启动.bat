@echo off
setlocal EnableExtensions DisableDelayedExpansion
chcp 65001 >nul
cd /d "%~dp0"
set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
if not exist "%~dp0docs" mkdir "%~dp0docs"

call :log "START requested"

echo ============================================================
echo  QQ Bot Launcher - NapCat + AstrBot
echo  Root: %ROOT%
echo ============================================================

set "PROC=NONE"
for /f "delims=" %%i in ('powershell -NoProfile -Command "$r=$env:ROOT; $a=@(Get-CimInstance Win32_Process); $n=0; foreach($x in $a){ $hit=$false; if($x.ExecutablePath){ if($x.ExecutablePath.StartsWith($r+'\runtime\napcat\',[StringComparison]::OrdinalIgnoreCase) -or $x.ExecutablePath.StartsWith($r+'\runtime\astrbot\',[StringComparison]::OrdinalIgnoreCase) -or $x.ExecutablePath.StartsWith($r+'\runtime\python\',[StringComparison]::OrdinalIgnoreCase)){ $hit=$true } }; if((-not $hit) -and $x.CommandLine -and ($x.Name -eq 'python.exe' -or $x.Name -eq 'pythonw.exe' -or $x.Name -eq 'node.exe' -or $x.Name -eq 'astrbot.exe')){ if($x.CommandLine.IndexOf($r+'\runtime\napcat\',[StringComparison]::OrdinalIgnoreCase) -ge 0 -or $x.CommandLine.IndexOf($r+'\runtime\astrbot\',[StringComparison]::OrdinalIgnoreCase) -ge 0 -or $x.CommandLine.IndexOf($r+'\runtime\python\',[StringComparison]::OrdinalIgnoreCase) -ge 0){ $hit=$true } }; if($hit){ $n++ } }; if($n -gt 0){'FOUND='+$n}else{'NONE'}"') do set "PROC=%%i"

set "PORTS=FREE"
for /f "delims=" %%i in ('powershell -NoProfile -Command "$r=@(); foreach($p in 3000,3001,6099,6185){ $c=Get-NetTCPConnection -State Listen -LocalPort $p -ErrorAction SilentlyContinue; if($c){ $r+=$p } }; if($r.Count -gt 0){'BUSY='+($r -join ',')}else{'FREE'}"') do set "PORTS=%%i"

if not "%PROC%"=="NONE" goto refuse
if not "%PORTS%"=="FREE" goto refuse

echo [..] Starting NapCat ...
start "" /MIN /D "%~dp0runtime\napcat" cmd /c napcat.bat

echo [..] Starting AstrBot ...
set "ASTRBOT_ROOT=%~dp0runtime\astrbot"
start "" /MIN /D "%~dp0runtime\astrbot" "%~dp0runtime\python\python.exe" -m astrbot.cli run

echo [..] Waiting up to 60s for 127.0.0.1:6099, :6185, :3001 ...
powershell -NoProfile -Command "function L($p){ $x=Get-NetTCPConnection -State Listen -LocalPort $p -ErrorAction SilentlyContinue; foreach($y in $x){ if($y.LocalAddress -eq '127.0.0.1'){ return $true } }; return $false }; $d=(Get-Date).AddSeconds(60); while((Get-Date) -lt $d){ if((L 6099) -and (L 6185) -and (L 3001)){ exit 0 }; Start-Sleep -Seconds 2 }; exit 1"
if errorlevel 1 goto timeout

call :log "READY 6099/6185/3001 on 127.0.0.1"
echo [OK] All services are ready.
start "" "http://127.0.0.1:6185"
start "" "http://127.0.0.1:6099"
exit /b 0

:refuse
call :log "REFUSE double-start proc=%PROC% port=%PORTS%"
echo [REFUSE] Another instance is already running (process=%PROC%, port=%PORTS%).
echo [REFUSE] No new process was started.
echo [REFUSE] Opening existing WebUIs: http://127.0.0.1:6185 and http://127.0.0.1:6099
start "" "http://127.0.0.1:6185"
start "" "http://127.0.0.1:6099"
exit /b 0

:timeout
call :log "TIMEOUT 60s cleanup"
echo [ERROR] Services did not become ready within 60 seconds.
echo [ERROR] Stopping processes started by this attempt ...
powershell -NoProfile -Command "$r=$env:ROOT; $a=@(Get-CimInstance Win32_Process); foreach($x in $a){ $hit=$false; if($x.ExecutablePath){ if($x.ExecutablePath.StartsWith($r+'\runtime\napcat\',[StringComparison]::OrdinalIgnoreCase) -or $x.ExecutablePath.StartsWith($r+'\runtime\astrbot\',[StringComparison]::OrdinalIgnoreCase) -or $x.ExecutablePath.StartsWith($r+'\runtime\python\',[StringComparison]::OrdinalIgnoreCase)){ $hit=$true } }; if((-not $hit) -and $x.CommandLine -and ($x.Name -eq 'python.exe' -or $x.Name -eq 'pythonw.exe' -or $x.Name -eq 'node.exe' -or $x.Name -eq 'astrbot.exe')){ if($x.CommandLine.IndexOf($r+'\runtime\napcat\',[StringComparison]::OrdinalIgnoreCase) -ge 0 -or $x.CommandLine.IndexOf($r+'\runtime\astrbot\',[StringComparison]::OrdinalIgnoreCase) -ge 0 -or $x.CommandLine.IndexOf($r+'\runtime\python\',[StringComparison]::OrdinalIgnoreCase) -ge 0){ $hit=$true } }; if($hit){ Stop-Process -Id $x.ProcessId -Force -ErrorAction SilentlyContinue } }"
echo [ERROR] See docs\start.log for details.
exit /b 1

:log
set "LOGMSG=%~1"
powershell -NoProfile -Command "Add-Content -LiteralPath (Join-Path $env:ROOT 'docs\start.log') -Value ((Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + ' ' + $env:LOGMSG) -Encoding ASCII"
exit /b
