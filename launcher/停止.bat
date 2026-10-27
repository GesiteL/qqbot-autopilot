@echo off
setlocal EnableExtensions DisableDelayedExpansion
chcp 65001 >nul
cd /d "%~dp0"
set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
if not exist "%~dp0docs" mkdir "%~dp0docs"

call :log "STOP requested"
echo [..] Stopping NapCat / AstrBot ...

set "FOUND=0"
for /f "delims=" %%i in ('powershell -NoProfile -Command "$r=$env:ROOT; $a=@(Get-CimInstance Win32_Process); $ids=@(); foreach($x in $a){ $hit=$false; if($x.ExecutablePath){ if($x.ExecutablePath.StartsWith($r+'\runtime\napcat\',[StringComparison]::OrdinalIgnoreCase) -or $x.ExecutablePath.StartsWith($r+'\runtime\astrbot\',[StringComparison]::OrdinalIgnoreCase) -or $x.ExecutablePath.StartsWith($r+'\runtime\python\',[StringComparison]::OrdinalIgnoreCase)){ $hit=$true } }; if((-not $hit) -and $x.CommandLine -and ($x.Name -eq 'python.exe' -or $x.Name -eq 'pythonw.exe' -or $x.Name -eq 'node.exe' -or $x.Name -eq 'astrbot.exe')){ if($x.CommandLine.IndexOf($r+'\runtime\napcat\',[StringComparison]::OrdinalIgnoreCase) -ge 0 -or $x.CommandLine.IndexOf($r+'\runtime\astrbot\',[StringComparison]::OrdinalIgnoreCase) -ge 0 -or $x.CommandLine.IndexOf($r+'\runtime\python\',[StringComparison]::OrdinalIgnoreCase) -ge 0){ $hit=$true } }; if($hit){ $ids+=$x.ProcessId } }; foreach($id in $ids){ $p=Get-Process -Id $id -ErrorAction SilentlyContinue; if($p){ $null=$p.CloseMainWindow() } }; if($ids.Count -gt 0){ Start-Sleep -Seconds 3 }; foreach($id in $ids){ Stop-Process -Id $id -Force -ErrorAction SilentlyContinue }; [string]$ids.Count"') do set "FOUND=%%i"

echo [..] Processes handled: %FOUND%
echo [..] Waiting up to 15s for ports 3000/3001/6099/6185 ...
powershell -NoProfile -Command "function L($p){ $x=Get-NetTCPConnection -State Listen -LocalPort $p -ErrorAction SilentlyContinue; if($x){ return $true }; return $false }; $d=(Get-Date).AddSeconds(15); while((Get-Date) -lt $d){ if((-not (L 3000)) -and (-not (L 3001)) -and (-not (L 6099)) -and (-not (L 6185))){ exit 0 }; Start-Sleep -Seconds 1 }; exit 1"
if errorlevel 1 goto fail

call :log "STOP pids=%FOUND% ports=free"
echo [OK] All services stopped. Ports 3000/3001/6099/6185 are free.
exit /b 0

:fail
call :log "STOP FAIL pids=%FOUND% ports=busy"
echo [ERROR] Some ports are still busy: 3000/3001/6099/6185
echo [ERROR] Check Task Manager and retry.
exit /b 1

:log
set "LOGMSG=%~1"
powershell -NoProfile -Command "Add-Content -LiteralPath (Join-Path $env:ROOT 'docs\start.log') -Value ((Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + ' ' + $env:LOGMSG) -Encoding ASCII"
exit /b
