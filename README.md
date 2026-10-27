# qqbot-autopilot

[![version](https://img.shields.io/badge/version-v0.1.0-blue)](CHANGELOG.md) [![license](https://img.shields.io/badge/license-MIT-green)](LICENSE)

给 AI 看的 QQ 机器人自举安装套件：一条指令，从空机器装到能聊天。  
NapCat 协议端 + AstrBot 大脑 + 空间/点歌/感知插件，版本与 SHA256 全部锁定，零管理员、零注册表、零系统服务。  
人类只做三件事：扫一次码、贴一次 Key、回答几个问题。

## 两个入口

- **AI 自装**：把仓库交给 WorkBuddy / DSH 类 agent，让它先读 `AGENTS.md`，按 §1–§9 自行安装，直到“四联自检”通过。
- **AI 教人类**：不想让 agent 动手，就把 `docs/AI教学手册-第一册-安装.md`（配置阶段用第二册）整篇粘贴给你的 AI，让它一步一步教你。

两条路终点相同：服务只监听 `127.0.0.1`，机器人在群里回话、会发空间说说。

## 已验证组件（官方来源）

- **NapCatQQ v4.18.41**：https://github.com/NapNeko/NapCatQQ/releases
  （Windows 使用 `NapCat.Shell.Windows.Node.zip`，自带 Node 运行时）
- **AstrBot 4.29.3**：https://github.com/AstrBotDevs/AstrBot ｜ https://pypi.org/project/astrbot/
- **Python 3.12.15 / uv 0.12.23**：https://github.com/astral-sh/uv
- **7-Zip 26.x**：https://www.7-zip.org/（仅使用官方 `7z.exe` / `7zr.exe`）
- **IExpress**：Windows 系统自带，无第三方 SFX 模块
- 插件（固定 commit 见 `docs/manifest.txt`）：
  - https://github.com/miaoxutao123/astrbot_plugin_LLMPerception
  - https://github.com/Zhalslar/astrbot_plugin_qzone
  - https://github.com/Zhalslar/astrbot_plugin_music

## 目录

- `启动.bat` / `停止.bat`：本机启动、双开防护、健康检查与停止。
- `docs/`：客户手册、AI 教学手册、OneBot 模板、安装清单、运维手册 `docs/MAINTENANCE.md`。
- `pack/iexpress/`：IExpress 安装脚本与 SED；`pack/tools/check_stage.ps1` 为打包前检查。
- `runtime/`、`.tmp/`、安装包、`payload.7z`、`7zr.exe`、`secrets/` 均被忽略，不入库。

## 复现与打包（Windows 11 x64，零管理员）

1. 安装官方 7-Zip；准备 Python 3.12（推荐 uv 管理的 CPython 3.12.15）。
2. 从 NapCat Releases 下载 `NapCat.Shell.Windows.Node.zip`，解压到 `runtime/napcat/`。
3. 在 `runtime/python/` 安装 AstrBot 4.29.3 及插件依赖；把插件源码放入
   `runtime/astrbot/data/plugins/`，按 `AGENTS.md` 在目标机现场生成配置与本机 token。
4. 将 `runtime/`、`docs/`、`启动.bat`、`停止.bat` 暂存；用官方 7-Zip 生成 LZMA `payload.7z`；
   按 `pack/iexpress/qqbot.sed` 调整 SourceFiles 路径，把 `payload.7z`、官方 `7zr.exe`、
   `pack/iexpress/install.bat` 交给 IExpress 生成单文件安装包（产物不入库）。
5. 安装后仅监听 `127.0.0.1:3001/6099/6185`；验收按 `docs/` 的 AI 手册与四联自检执行。

## 运维

长期在线交给 `docs/MAINTENANCE.md`：每周巡检七项、自修白名单、辅助用户守则、红线与报障格式。
建议配成定时任务，每周一早上 8 点跑一次。

## 安全与免责

- 仓库不含任何真实 Key、token、Cookie、QQ/UIN；本地配置与 `runtime/secrets/` 不入库。
- 所有服务仅绑定 `127.0.0.1`；不要映射到公网。token 泄露时应立即轮换。
- 本项目为独立交付套件，与腾讯、NapCat、AstrBot 官方无隶属关系；
  请遵守 QQ 平台规则及第三方组件许可。软件按现状提供，使用风险自负。
- 已知限制（无头执行器进程回收、中转站额度、单实例锁）见 `CHANGELOG.md`。

## License

MIT，见 `LICENSE`。
