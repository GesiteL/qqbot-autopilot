@echo off
setlocal EnableExtensions DisableDelayedExpansion
chcp 65001 >nul
set "LOG=%TEMP%\qqbot-install.log"

echo.
echo ############################################################
echo #                                                          #
echo #   请勿关闭本窗口，关闭会导致安装不完整
echo #                                                          #
echo ############################################################
echo.

echo [%TIME%] INSTALL_START >> "%LOG%"

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
exit /b 0

:cancel
echo [%TIME%] CANCELLED >> "%LOG%"
echo.
echo 已取消安装。
pause
exit /b 1

:extractfail
echo [%TIME%] EXTRACT_FAIL >> "%LOG%"
echo.
echo [错误] 解压失败。请确认安装包完整，然后重试。
pause
exit /b 1

:startfail
echo [%TIME%] START_FAIL >> "%LOG%"
echo.
echo [错误] 启动失败：找不到 C:\QQBot\启动.bat 或 runtime\python。
pause
exit /b 1
