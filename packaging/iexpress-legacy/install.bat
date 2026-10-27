@echo off
setlocal EnableExtensions DisableDelayedExpansion
chcp 65001 >nul
set "LOG=%TEMP%\qqbot-install.log"
set "LOCK=%TEMP%\qqbot-install.lock"

echo.
echo ############################################################
echo #                                                          #
echo #   请勿关闭本窗口，关闭会导致安装不完整
echo #                                                          #
echo ############################################################
echo.

echo [%TIME%] INSTALL_START >> "%LOG%"

rem ---------- A2 单实例锁：同一时间只允许一个安装进程 ----------
rem 自身 PID：临时改控制台标题，用 tasklist 反查（不依赖 PowerShell，约 1 秒）
set "TAG=QQBOTLOCK_%RANDOM%%RANDOM%%RANDOM%"
title %TAG%
set "MYPID="
for /f "tokens=2 delims=," %%a in ('tasklist /v /fi "imagename eq cmd.exe" /fo csv /nh ^| findstr /c:"%TAG%"') do set "MYPID=%%~a"
title QQ Bot Setup
if not defined MYPID (
    echo [%TIME%] LOCK_SKIP no-pid >> "%LOG%"
    goto lock_done
)

if not exist "%LOCK%" goto lock_new
set "LOCKPID="
set /p LOCKPID=<"%LOCK%" 2>nul
if not defined LOCKPID goto lock_stale
set "ALIVE="
for /f "tokens=1,2 delims=," %%x in ('tasklist /fi "PID eq %LOCKPID%" /fo csv /nh 2^>nul') do if /i "%%~x"=="cmd.exe" if "%%~y"=="%LOCKPID%" set "ALIVE=1"
if defined ALIVE goto lock_busy

:lock_stale
echo [%TIME%] LOCK_STALE pid=%LOCKPID% >> "%LOG%"
del /f /q "%LOCK%" >nul 2>&1

:lock_new
>"%LOCK%" echo %MYPID%
ping -n 2 127.0.0.1 >nul
set "LOCKPID="
set /p LOCKPID=<"%LOCK%" 2>nul
if not "%LOCKPID%"=="%MYPID%" goto lock_lost
echo [%TIME%] LOCK_OK pid=%MYPID% >> "%LOG%"
set "LOCKHELD=1"
goto lock_done

:lock_busy
echo [%TIME%] LOCK_BUSY pid=%LOCKPID% >> "%LOG%"
echo.
echo [提示] 安装程序已经在运行（PID %LOCKPID%），本次不再重复安装。
echo [提示] 请回到已经打开的安装窗口；如确认没有安装在进行，删除下面的文件后重试：
echo        %LOCK%
echo.
ping -n 9 127.0.0.1 >nul
exit /b 1

:lock_lost
echo [%TIME%] LOCK_LOST >> "%LOG%"
echo.
echo [提示] 另一个安装程序已经启动，本窗口退出。
echo.
ping -n 9 127.0.0.1 >nul
exit /b 1

:lock_done

if exist "C:\QQBot\" (
    echo [%TIME%] OVERWRITE_PROMPT >> "%LOG%"
    choice /C YN /N /T 15 /D Y /M "C:\QQBot already exists. Overwrite? [Y/N] (auto Y in 15s) "
    if errorlevel 2 goto cancel
    echo [%TIME%] OVERWRITE_CONFIRMED >> "%LOG%"
)

echo [%TIME%] EXTRACT_BEGIN >> "%LOG%"
echo [1/3] 正在解压，约需 2 分钟，请勿关闭本窗口
echo.
"%~dp07zr.exe" x "%~dp0payload.7z" -o"C:\QQBot" -y -bsp1
if errorlevel 1 goto extractfail
echo.
echo [2/3] 正在启动机器人...
echo [%TIME%] EXTRACT_OK >> "%LOG%"

if not exist "C:\QQBot\runtime\python\python.exe" goto startfail
powershell -NoProfile -Command "$f=Get-ChildItem -LiteralPath 'C:\QQBot' -Filter '*.bat' | Where-Object { (Get-Content -LiteralPath $_.FullName -Raw) -match 'QQ Bot Launcher' } | Select-Object -First 1; if($f){ Start-Process -FilePath $f.FullName -WorkingDirectory 'C:\QQBot' -WindowStyle Minimized; exit 0 } else { exit 1 }"
if errorlevel 1 goto startfail
echo [%TIME%] START_OK >> "%LOG%"

echo [3/3] 即将自动打开控制页面
echo.
ping -n 4 127.0.0.1 >nul

set "TD=%~dp0"
set "TD=%TD:~0,-1%"
start "" /MIN powershell -NoProfile -WindowStyle Hidden -Command "Start-Sleep -Seconds 6; Remove-Item -LiteralPath '%TD%' -Recurse -Force -ErrorAction SilentlyContinue"
call :unlock
exit /b 0

:cancel
echo [%TIME%] CANCELLED >> "%LOG%"
call :unlock
echo.
echo 已取消安装。
pause
exit /b 1

:extractfail
echo [%TIME%] EXTRACT_FAIL >> "%LOG%"
call :unlock
echo.
echo [错误] 解压失败。请确认安装包完整，然后重试。
pause
exit /b 1

:startfail
echo [%TIME%] START_FAIL >> "%LOG%"
call :unlock
echo.
echo [错误] 启动失败：找不到 C:\QQBot\启动.bat 或 runtime\python。
pause
exit /b 1

:unlock
if defined LOCKHELD if exist "%LOCK%" del /f /q "%LOCK%" >nul 2>&1
echo [%TIME%] LOCK_RELEASED >> "%LOG%"
exit /b 0
