# QQBOT Delivery Workbook (NapCat + AstrBot)

本项目是 QQ 机器人交付工作台：NapCat 作为协议端，AstrBot 作为 AI 大脑，
配套三个插件与本地打包/验收脚本。仓库只保留源码、文档与打包源文件；
运行时、密钥、安装包、payload、7zr 均不入库。

> 如果你是 AI Agent，请首先阅读 AGENTS.md

> 仓库性质与名称由维护者在上传前填写；本仓库不包含任何 remote 配置。

## 已测试组件（官方来源）

- **NapCatQQ v4.18.41**：https://github.com/NapNeko/NapCatQQ/releases
  （Windows 使用 `NapCat.Shell.Windows.Node.zip`，自带 Node 运行时）
- **AstrBot 4.29.3**：https://github.com/AstrBotDevs/AstrBot ｜ https://pypi.org/project/astrbot/
- **uv 0.12.23**：https://github.com/astral-sh/uv
- **7-Zip 26.x**：https://www.7-zip.org/（仅使用官方 `7z.exe` / `7zr.exe`）
- **IExpress**：Windows 系统自带，无第三方 SFX 模块
- 插件（固定 commit 见 `docs/manifest.txt`）：
  - https://github.com/miaoxutao123/astrbot_plugin_LLMPerception
  - https://github.com/Zhalslar/astrbot_plugin_qzone
  - https://github.com/Zhalslar/astrbot_plugin_music

## 目录

- `启动.bat` / `停止.bat`：本机启动、双开防护、健康检查与停止。
- `docs/`：客户手册、交付夜零点击 runbook、分工卡、OneBot 模板、安装清单。
- `pack/iexpress/`：IExpress 安装脚本与 SED；`pack/tools/check_stage.ps1` 打包前检查。
- `runtime/`、`.tmp/`、`安装包.exe`、`payload.7z`、`7zr.exe`、`secrets/` 均被忽略。

## 复现步骤（Windows 11 x64，零管理员）

1. 安装官方 7-Zip；准备 Python 3.12（推荐 uv 管理的 CPython 3.12.15）。
2. 从 NapCat Releases 下载 `NapCat.Shell.Windows.Node.zip`，解压到 `runtime/napcat/`。
3. 在 `runtime/python/` 安装 AstrBot 4.29.3 及插件依赖；把插件源码放入
   `runtime/astrbot/data/plugins/`，按项目文档生成配置与本机 token。
4. 将 `runtime/`、`docs/`、`启动.bat`、`停止.bat` 暂存；用官方 7-Zip 生成
   LZMA `payload.7z`；按 `pack/iexpress/qqbot.sed` 调整 SourceFiles 路径，
   将 `payload.7z`、官方 `7zr.exe`、`pack/iexpress/install.bat` 交给 IExpress
   生成 `安装包.exe`（产物不入库）。
5. 启动后仅监听 `127.0.0.1:3001/6099/6185`；**人类准备 = 扫一次码、回答 AI 几个问题**，验收按 `docs/` 执行。

## 安全与免责

- 仓库不含任何真实 Key、token、Cookie、QQ/UIN；本地配置与 `runtime/secrets/` 不入库。
- 所有服务仅绑定 `127.0.0.1`；不要映射到公网。token 泄露时应立即轮换。
- 本项目为独立交付工作台，与腾讯、NapCat、AstrBot 官方无隶属关系；
  请遵守 QQ 平台规则及第三方组件许可。软件按现状提供，使用风险自负。
- 自动化引导限制：agent 直启（`node.exe`/`python.exe`）可拉起服务并生成二维码，但在无头/沙箱执行器下
  服务进程可能被回收，无法持续存活待扫码；此场景「启动一步」由用户在桌面双击 `启动.bat` 完成。

## 不会装？交给你的 AI

不会装？把 `docs/AI教学手册` 粘贴给你的 AI 让它教你。

## License

MIT，见 `LICENSE`。
