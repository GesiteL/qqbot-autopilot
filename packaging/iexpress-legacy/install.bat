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

rem ---------- Q0 安装位置：先问盘符，再定安装目录 ----------
rem 只装一个文件夹，不写注册表、不装服务；默认 C 盘，兼容 C-H。
set "DRIVE="
set "TARGET="
echo.
echo [Q0] 安装在哪个盘？只装一个文件夹，不写注册表、不装系统服务。
set /p "DRIVE=请输入盘符 C/D/E/F，直接回车 = C 盘: "
if not defined DRIVE set "DRIVE=C"
set "DRIVE=%DRIVE: =%"
set "DRIVE=%DRIVE::=%"
set "DRIVE=%DRIVE:\=%"
set "DRIVE=%DRIVE:/=%"
set "DRIVE=%DRIVE:QQBot=%"
set "NORM="
for %%d in (C D E F G H) do if /i "%DRIVE%"=="%%d" set "NORM=%%d"
if not defined NORM goto baddir
set "DRIVE=%NORM%"
set "TARGET=%DRIVE%:\QQBot"
echo [Q0] 安装目录：%TARGET%
echo [%TIME%] TARGET=%TARGET% >> "%LOG%"

if not exist "%DRIVE%:\" goto baddir

set "FREEGB="
for /f "delims=" %%i in ('powershell -NoProfile -Command "$v=Get-PSDrive -Name %DRIVE% -ErrorAction SilentlyContinue; if($v){[math]::Floor($v.Free/1GB)}"') do set "FREEGB=%%i"
if defined FREEGB if %FREEGB% LSS 10 echo [提示] %DRIVE% 盘剩余 %FREEGB% GB，低于建议的 10 GB，安装可能失败。

if exist "%TARGET%\" (
    echo [%TIME%] OVERWRITE_PROMPT >> "%LOG%"
    choice /C YN /N /T 15 /D Y /M "%TARGET% 已存在。覆盖安装？[Y/N]（15 秒后自动 Y） "
    if errorlevel 2 goto cancel
    echo [%TIME%] OVERWRITE_CONFIRMED >> "%LOG%"
)

echo [%TIME%] EXTRACT_BEGIN >> "%LOG%"
echo [1/4] 正在解压到 %TARGET%，约需 2 分钟，请勿关闭本窗口
echo.
"%~dp07zr.exe" x "%~dp0payload.7z" -o"%TARGET%" -y -bsp1
if errorlevel 1 goto extractfail
echo.
echo [2/4] 正在记录安装信息...
echo [%TIME%] EXTRACT_OK >> "%LOG%"

rem 安装信息.txt：给客户与 AI 一个“装在哪”的稳定锚点（无密钥、无账号）
> "%TARGET%\安装信息.txt" (
    echo QQBot 安装信息
    echo ==========================================
    echo 安装目录：%TARGET%
    echo 安装盘符：%DRIVE%
    echo 安装时间：%DATE% %TIME%
    echo 安装包版本：v0.1.0
    echo 安装包大小：174288896 字节
    echo 说明：卸载 = 删除整个安装目录；删除本文件不影响运行。
)
if not exist "%TARGET%\安装信息.txt" echo [提示] 安装信息.txt 写入失败，不影响运行。

echo [3/4] 正在启动机器人...
if not exist "%TARGET%\runtime\python\python.exe" goto startfail
powershell -NoProfile -Command "$f=Get-ChildItem -LiteralPath '%TARGET%' -Filter '*.bat' | Where-Object { (Get-Content -LiteralPath $_.FullName -Raw) -match 'QQ Bot Launcher' } | Select-Object -First 1; if($f){ Start-Process -FilePath $f.FullName -WorkingDirectory '%TARGET%' -WindowStyle Minimized; exit 0 } else { exit 1 }"
if errorlevel 1 goto startfail
echo [%TIME%] START_OK >> "%LOG%"

echo [4/4] 即将自动打开控制页面
echo.
ping -n 4 127.0.0.1 >nul

set "TD=%~dp0"
set "TD=%TD:~0,-1%"
start "" /MIN powershell -NoProfile -WindowStyle Hidden -Command "Start-Sleep -Seconds 6; Remove-Item -LiteralPath '%TD%' -Recurse -Force -ErrorAction SilentlyContinue"
call :unlock
exit /b 0

:baddir
echo [%TIME%] BAD_DRIVE=%DRIVE% >> "%LOG%"
call :unlock
echo.
echo [错误] 盘符无效：%DRIVE%
echo [提示] 请输入 C/D/E/F 这样的单个字母；直接回车 = C 盘。
pause
exit /b 1

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
echo [错误] 解压失败。请确认安装包完整、目标盘有足够空间，然后重试。
pause
exit /b 1

:startfail
echo [%TIME%] START_FAIL >> "%LOG%"
call :unlock
echo.
echo [错误] 启动失败：找不到 %TARGET%\启动.bat 或 runtime\python。
pause
exit /b 1

:unlock
if defined LOCKHELD if exist "%LOCK%" del /f /q "%LOCK%" >nul 2>&1
echo [%TIME%] LOCK_RELEASED >> "%LOG%"
exit /b 0
