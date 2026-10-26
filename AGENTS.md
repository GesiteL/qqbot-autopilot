# AGENTS.md — QQBot 自举安装指南

> 读者：WorkBuddy / DSH 类 agent。只按本文件执行；不要自由发挥。
> 本仓库是交付工作台；`runtime/`、`secrets/`、安装包、payload、`7zr.exe` 不入库。

## 0. 身份与契约（红线段）

- **生产根目录**：`$Root = "C:\QQBot"`。只允许写这里。
- **推演例外**：仅 `$DryRun = 1` 时可用 `$Root = "C:\QQBotRehearsal"`；推演结束立即删除，生产 agent 不得使用该模式。
- 所有服务只绑 `127.0.0.1`；禁止 `0.0.0.0`、端口映射、管理员/UAC、注册表、Windows 服务。
- token/key 只存在本机 `runtime\secrets\` 与 `C:\QQBot\key.txt`；禁止打印、发聊天、写日志/仓库/报告；报告只写 `***`。
- 固定版本与 SHA256；禁止 `latest`、第三方镜像、自动更新、跳过校验。
- 任一步失败：**停止**，打印命令、错误、已完成步骤与回滚方法，上报；禁止换方案或凑合。
- 不登录 QQ、不扫码、不填 key；人类检查点必须等人类完成。
- 不读取无关密钥；不覆盖未备份配置；不删除 `$Root` 之外的任何路径。

## 1. 环境调查（只读）

```powershell
(Get-CimInstance Win32_OperatingSystem).Caption
(Get-CimInstance Win32_OperatingSystem).OSArchitecture
([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
Get-PSDrive C,D | Select-Object Name,@{n='FreeGB';e={[math]::Round($_.Free/1GB,1)}}
node -v; python --version; uv --version; 7z
Get-NetTCPConnection -State Listen -LocalPort 3000,3001,6099,6185 -ErrorAction SilentlyContinue
```

预期：Windows 11 x64；**Administrator=False**；可用空间 ≥10GB；uv/Python 3.12/7z 可用；
3000/3001/6099/6185 无监听。系统 Node 可选（NapCat 自带 Node v22.11.0），缺失不阻塞。

缺失处置：uv 缺失→安装官方 uv（用户级）；Python 3.12.15 缺失→`uv python install 3.12.15`；
7z 缺失→使用官方 7-Zip Extra 的 `7zr.exe`；端口被占用→停止上报，禁止杀进程；UAC/管理员→停止。

## 2. 组件获取（全部 pinned，禁止 latest）

```powershell
$Repo = (Get-Location).Path
$Root = if ($DryRun -eq 1) { 'C:\QQBotRehearsal' } else { 'C:\QQBot' }
New-Item -ItemType Directory -Force "$Root\runtime","$Root\logs","$Root\docs" | Out-Null
```

**NapCat v4.18.41**（官方 GitHub Release，仅 `NapCat.Shell.Windows.Node.zip`）：
https://github.com/NapNeko/NapCatQQ/releases/download/v4.18.41/NapCat.Shell.Windows.Node.zip
SHA256 `51fbb10e7bcd56b0c2a6de86c37811e7518330e48a137ac689ab1e4d8627d3f0`；大小 124,089,498 B。
```powershell
$zip = "$env:TEMP\NapCat.Shell.Windows.Node.zip"
Invoke-WebRequest $url -OutFile $zip
if ((Get-FileHash $zip -Algorithm SHA256).Hash -ne '51FBB10E7BCD56B0C2A6DE86C37811E7518330E48A137AC689AB1E4D8627D3F0') { throw 'NapCat hash mismatch' }
7z x $zip -o"$Root\runtime\napcat" -y
```

**Python / AstrBot / 插件依赖**（全部固定）：
- Python **3.12.15**（uv 0.12.23）；AstrBot **4.29.3**
- chinese-calendar **1.11.0**、lunarcalendar **0.0.9**、json5 **0.17.3**、apilmoji **0.3.1**
  （实测运行时另含 Pillow **13.0.0**、beautifulsoup4 **4.15.0**）
```powershell
uv python install 3.12.15
$py = (uv python find 3.12.15)
Copy-Item (Split-Path $py -Parent) "$Root\runtime\python" -Recurse -Force
uv pip install --break-system-packages --python "$Root\runtime\python\python.exe" `
  --index-url https://pypi.org/simple astrbot==4.29.3 chinese-calendar==1.11.0 `
  lunarcalendar==0.0.9 json5==0.17.3 apilmoji==0.3.1 Pillow==13.0.0 beautifulsoup4==4.15.0
& "$Root\runtime\python\python.exe" -m astrbot.cli --version   # 4.29.3
```

**插件**（实测为 3 个；若交付另有第 4 个，必须另给固定 commit，禁止 latest）：
```powershell
$p = "$Root\runtime\astrbot\data\plugins"
git clone https://github.com/miaoxutao123/astrbot_plugin_LLMPerception.git "$p\astrbot_plugin_LLMPerception"
git -C "$p\astrbot_plugin_LLMPerception" checkout be48a2b3506f606cf84f8d28762d3262ddf9575b
git clone https://github.com/Zhalslar/astrbot_plugin_qzone.git "$p\astrbot_plugin_qzone"
git -C "$p\astrbot_plugin_qzone" checkout f474c50c9b517655d8475df34ad0c129b70193d4
git clone https://github.com/Zhalslar/astrbot_plugin_music.git "$p\astrbot_plugin_music"
git -C "$p\astrbot_plugin_music" checkout 9022a710aa85bd0287978384be6efa72c3eabdd1
```

**7zr 26.00**（官方 7-Zip Extra，仅打包用）：SHA256
`4bec0bc59836a890a11568b58bd12a3e7b23a683557340562da211b6088058ba`；IExpress 为 Windows 自带。
缓存加速（仅推演/预置交付）：允许复制已验证的 `runtime\`；**按完整路径**排除 `secrets`、`.venv`，
不要按目录名排除 `webchat/cache/plugin_data`（代码与数据同名，实测会删掉 AstrBot 的 webchat 模块）；
复制后必须重新生成本机 token，并核对版本。

## 3. 配置落盘（token 现场生成，禁止示例值）

```powershell
$env:QQBOT_ROOT = $Root
& "$Root\runtime\python\python.exe" -c "import os,secrets,pathlib; p=pathlib.Path(os.environ['QQBOT_ROOT'])/'runtime'/'secrets'; p.mkdir(parents=True,exist_ok=True); (p/'napcat-webui-token.txt').write_text(secrets.token_hex(32)); (p/'onebot-token.txt').write_text(secrets.token_hex(32))"
```

- 读取 `runtime\secrets\*.txt` 写入配置，**不要回显**。
- NapCat `webui.json`：`host=127.0.0.1`，token 取 `napcat-webui-token.txt`。
- OneBot：模板 `docs\onebot11-template.json`，token 占位符 `{{ONEBOT_TOKEN}}` 现场替换；禁止建 3001 服务端。
- AstrBot：dashboard 绑 `127.0.0.1`；provider 用 OpenAI 兼容 `https://api-bzj.hnfhnq.cn/v1`，模型
  `custom/【草莓按次-0.03】gemini-3.8-flash-high`，key 先占位；admin/群白名单/人设取交付配置或由人类提供，
  禁止写死任何 QQ/UIN；人设参照 `docs/人设-小满.md`。若使用已验证的 `runtime\astrbot\data` 缓存则保留其配置。

## 4. 人类检查点 A：扫码

```powershell
Start-Process cmd.exe -ArgumentList '/c',"`"$Root\runtime\napcat\napcat.bat`" > `"$Root\logs\napcat-A.log`" 2>&1" -WindowStyle Minimized
Get-NetTCPConnection -State Listen -LocalPort 6099
Select-String "$Root\logs\napcat-A.log" -Pattern '二维码解码URL|二维码已保存'
```

向人类输出：二维码图片 `$Root\runtime\napcat\napcat\cache\qrcode.png` 与日志中的 txz 解码 URL；
指示文本：**“请用手机 QQ 扫控制台/图片二维码（小号），不要用快速登录大号；D 不扫码。”**
轮询 `$Root\runtime\napcat\napcat\config\onebot11_*.json` 每 5 秒一次，最多 120 次（10 分钟）。
超时→停止并上报。**人类完成扫码前不得继续。**

## 5. 接线（零点击）

- 备份现有 `onebot11_<UIN>.json` 为 `.bak`；`<UIN>` 从轮询到的文件名取，**禁止提前写死**。
- 用 `docs\onebot11-template.json` 生成整份配置；只加 WebSocket **客户端** `ws://127.0.0.1:3001/ws`；
  `messagePostFormat=array`、`reportSelfMessage=false`；token 从 `onebot-token.txt` 注入。
- 重启两端（禁止把启动输出接管道/tail，浏览器句柄会阻塞）：
```powershell
Start-Process -FilePath "cmd.exe" -ArgumentList "/c","$Root\停止.bat" -WorkingDirectory $Root -WindowStyle Hidden
# 轮询端口全空
Start-Process -FilePath "cmd.exe" -ArgumentList "/c","$Root\启动.bat" -WorkingDirectory $Root -WindowStyle Hidden
# 轮询 3001/6185/6099 均 127.0.0.1；以 start.log READY 为准
```
- 断言 3001 出现 `ESTABLISHED`（AstrBot 服务端 + NapCat 客户端）；失败→恢复 `.bak`、重启、停止上报。

## 6. 人类检查点 B：key

- 若 `$Root\key.txt` 不存在：打印 **“请把模型 key 保存为 C:\QQBot\key.txt，保存后按回车”**，等待文件出现。
- 用 Python 以 `utf-8-sig` 读取配置并写入 `provider_sources[0].key`；**不打印 key**、不写日志/报告。
  PowerShell 5.1 的 `ConvertFrom-Json` 读取无 BOM UTF-8 中文会损坏配置，禁止使用。
```powershell
$env:QQBOT_ROOT = $Root
$env:QQBOT_KEY = ([IO.File]::ReadAllText("$Root\key.txt")).Trim()
& "$Root\runtime\python\python.exe" -c "import json,os,pathlib; p=pathlib.Path(os.environ['QQBOT_ROOT'])/'runtime'/'astrbot'/'data'/'cmd_config.json'; c=json.loads(p.read_text(encoding='utf-8-sig')); c['provider_sources'][0]['key']=[os.environ['QQBOT_KEY']]; p.write_text(json.dumps(c,ensure_ascii=False,indent=2),encoding='utf-8')"
```
- 重启 AstrBot（同上 Start-Process/poll）；确认 6185 为 `127.0.0.1` 监听。

## 7. 四联自检

自动可判定：
1. `Get-NetTCPConnection -State Listen -LocalPort 3001,6099,6185` 全部 `127.0.0.1`。
2. 3001 有 `ESTABLISHED`；AstrBot 日志/平台页显示 aiocqhttp 在线。
3. 用 `key.txt` 对 provider 发一次最小请求，断言 HTTP **200**；不回显 key/响应正文。
人工四联（打印清单给人类）：回话、识图、提醒、发动态。失败→回滚并停止。

## 8. 回滚与卸载

- 用 `Start-Process cmd.exe -ArgumentList "/c","$Root\停止.bat" -WorkingDirectory $Root -WindowStyle Hidden` 启动停止脚本；
  轮询确认 3000/3001/6099/6185 释放；不要接管道等待。
- 完全卸载 = 删除 `$Root`（默认 `C:\QQBot`）；**删除前必须人类确认**。
- 不写注册表/服务；不删除其他目录。

## 9. 干跑（仅推演）

```powershell
$Repo = (Get-Location).Path
$DryRun = 1; $Root = 'C:\QQBotRehearsal'
New-Item -ItemType Directory -Force "$Root\runtime","$Root\logs","$Root\docs" | Out-Null
robocopy "$Repo\runtime\python" "$Root\runtime\python" /E /NFL /NDL /NJH /NJS /NP
robocopy "$Repo\runtime\napcat" "$Root\runtime\napcat" /E /NFL /NDL /NJH /NJS /NP
robocopy "$Repo\runtime\astrbot" "$Root\runtime\astrbot" /E /XD "$Repo\runtime\astrbot\.venv" "$Repo\runtime\secrets" /NFL /NDL /NJH /NJS /NP
# 不要按目录名排除 webchat/cache：会误删代码目录
Copy-Item "$Repo\docs\*" "$Root\docs" -Recurse -Force
Copy-Item "$Repo\启动.bat","$Repo\停止.bat" "$Root" -Force
# 按第 3 节重新生成本机 token；更新 webui.json 与 AstrBot platform token
$t = Get-Content "$Repo\docs\onebot11-template.json" -Raw
$tok = (Get-Content "$Root\runtime\secrets\onebot-token.txt" -Raw).Trim()
[IO.File]::WriteAllText("$Root\runtime\napcat\napcat\config\onebot11_TEST_UIN.json", ($t.Replace('{{ONEBOT_TOKEN}}',$tok)))
[IO.File]::WriteAllText("$Root\key.txt", '<REHEARSAL_FAKE_KEY>')
# 用第 5/6 节 Start-Process 启停并轮询；3001 ESTABLISHED 与 LLM 200 标记为“人类/真机待验”
# 结束后：Start-Process 停止.bat → 轮询端口 → Remove-Item $Root -Recurse -Force
```
干跑不得使用真实 QQ 登录、真实 key、真实 UIN；不得把假值写入仓库或报告。
