# qqbot-autopilot

[![version](https://img.shields.io/badge/version-v0.1.0-blue)](CHANGELOG.md) [![license](https://img.shields.io/badge/license-MIT-green)](LICENSE)

给 AI 看的 QQ 机器人自举套件：一条指令，从空机器装到能聊天。
NapCat 协议端 + AstrBot 大脑 + 感知/空间/点歌插件，版本与 SHA256 全部锁定；
零管理员、零注册表、零系统服务，所有服务只监听 `127.0.0.1`。

## 双轨定位

同一个仓库，两种交付方式，终点相同。**买家是 AI，不是人**——人只负责按下开始。

| 轨道 | 给谁 | 入口 | 人类要做的事 |
|---|---|---|---|
| **A 成品交付** | 不懂技术的客户 | `安装包.exe`（单文件，双击即装） | 扫一次码、填一次 Key |
| **B 源码自举（BYOA）** | 有自己 agent 的开发者 / 交付方 | `AGENTS.md` | 把仓库交给 agent，回答几个问题 |

**BYOA = Bring Your Own Agent**：不绑定厂商与客户端。WorkBuddy、DSH、Claude Code、Codex CLI
都可以——仓库只提供协议（`AGENTS.md`）和人读文档，agent 负责环境调查、下载校验、配置落盘、
接线与四联自检。模型 Key 也由使用者自备（不随包分发、不入库）；只有人类能做的那三件事
（扫码、给 Key、定白名单）留成检查点，agent 不越位。

轨道 A 与轨道 B 产出同一套运行时：同样锁版本、同样只监听本机、同样用 `启动.bat` / `停止.bat` 起停。

## 伴侣增强

这不是"问答机器人"，是住在电脑里的一个朋友。增强点都在运行时里，装完即生效：

- **有人设**：默认「小满」（`docs/templates/人设-小满.md`）——短句、不卖萌、不编造经历，
  深夜更短，拒绝时给替代方案而不说教；可在 AstrBot 后台换成主人自己写的人格。
- **有时间感**：LLMPerception 把时间、星期、法定节假日与调休注入上下文，
  它知道今天是中秋还是周三，也知道现在是深夜。
- **不用 @ 也接话**：白名单群里免 @ 回话，像群友而不是客服；私聊按需开启。
- **会看图**：群里发图它能读懂内容并接话（多模态模型）。
- **会记事**：说"三分钟后提醒我"，到点它会回来找你。
- **有自己的生活**：qzone 插件每天 1–3 条生活说说，能点赞、能评论，不是只会回复。
- **会点歌**：music 插件按歌名/关键词点歌。
- **有边界**：群白名单 + 管理员 + 仅本机监听；Key 只落本机配置，不回显、不外发。

增强的边界同样明确：不主动私聊陌生人、不跨群共享上下文、不碰安装目录以外的文件。

## 已验证组件（官方来源，全部固定）

| 组件 | 固定版本 | 官方地址 | 校验 |
|---|---|---|---|
| NapCatQQ | v4.18.41 | [Releases](https://github.com/NapNeko/NapCatQQ/releases/download/v4.18.41/NapCat.Shell.Windows.Node.zip) | SHA256 `51fbb10e…7d3f0`；124,089,498 B |
| AstrBot | 4.29.3 | [PyPI](https://pypi.org/project/astrbot/) ｜ [GitHub](https://github.com/AstrBotDevs/AstrBot) | 版本号固定，`astrbot.cli --version` 复核 |
| Python | 3.12.15 | [astral-sh/uv](https://github.com/astral-sh/uv) | `uv python install 3.12.15` |
| uv | 0.12.23 | 同上 | `uv self update 0.12.23` |
| 7-Zip | 26.00（`7zr.exe`） | [7-zip.org](https://www.7-zip.org/) | SHA256 `4bec0bc5…58ba` |
| IExpress | Windows 自带 | — | 仅 legacy 打包用，v0.2 移除 |

插件（固定 commit，禁止 `latest`）：

| 插件 | 仓库 | Commit |
|---|---|---|
| LLMPerception | https://github.com/miaoxutao123/astrbot_plugin_LLMPerception | `be48a2b3` |
| qzone | https://github.com/Zhalslar/astrbot_plugin_qzone | `f474c50c` |
| music | https://github.com/Zhalslar/astrbot_plugin_music | `9022a710` |

完整哈希、体积与实测记录见 `docs/internal/manifest.txt`；下载地址表与离线预置规则见 `AGENTS.md` §2。

## 目录

```
qqbot-autopilot/
├── README.md                      # 人读：定位、组件、打包
├── AGENTS.md                      # agent 自举协议（环境→组件→配置→检查点→自检）
├── MAINTENANCE.md                 # 运维协议：每周巡检、自修白名单、红线
├── CHANGELOG.md                   # 版本变化与已知限制
├── LICENSE / .gitignore
├── launcher/                      # 启动.bat / 停止.bat（安装后位于安装根目录）
├── packaging/
│   └── iexpress-legacy/           # IExpress 三件套 + README（v0.2 删除）
└── docs/
    ├── customer/                  # 对客：使用说明、填 Key、两册 AI 教学手册、post-login
    ├── internal/                  # 内部：安装清单、交付夜分工卡
    └── templates/                 # 模板：onebot11 配置、人设-小满
```

仓库不含 `runtime/`、`secrets/`、安装包、`payload.7z`、`7zr.exe`、`packages/`——它们由交付方在本地生成或预置。

## 装法一：成品安装包（轨道 A）

1. 双击 `安装包.exe`；SmartScreen 提示时「更多信息 → 仍要运行」。
2. 当前版本直接装到 `C:\QQBot`，**不问盘符**（选盘是下一版本特性）。
3. 解压约 2 分钟，自动拉起两端并打开 `127.0.0.1:6185` 与 `127.0.0.1:6099`。
4. 下一版本会在根目录写 `安装信息.txt`；当前版本排障直接看 `C:\QQBot`。

装完后由《AI 教学手册》第二册接管扫码、接线与填 Key；客户自助说明见 `docs/customer/README-客户.md`。

> 版本提示：已构建的 `安装包.exe` 为 013 构建（固定 `C:\QQBot`、无 `安装信息.txt`）；
> 盘符提问与安装信息从**下一次打包**起生效，详见 `CHANGELOG.md` 与 `packaging/iexpress-legacy/README.md`。

## 装法二：源码自举（轨道 B / BYOA）

1. 把仓库放到目标机任意目录，交给你的 agent。
2. 让它先读 `AGENTS.md`，按 §1–§9 执行；组件获取预算 60 分钟，其余阶段 10 分钟红线。
3. agent 会在三个检查点停下来等人：扫码（A）、模型 Key（B）、管理员与白名单（C）。
4. 四联自检通过即交付；失败按 §9 回滚。

`packages/` 预置协议：交付方可在仓库根预置已校验的组件包（不入库），agent 优先离线取包并复核
SHA256，缺包再回官方源下载——弱网和离线机器不必赌 GitHub 可达性。

## 打包（legacy，v0.2 由零 AI 安装器取代）

1. 安装官方 7-Zip；准备 Python 3.12（推荐 uv 管理的 CPython 3.12.15）。
2. 从 NapCat Releases 下载 `NapCat.Shell.Windows.Node.zip`，解压到 `runtime/napcat/`。
3. 在 `runtime/python/` 安装 AstrBot 4.29.3 及插件依赖；插件源码放入
   `runtime/astrbot/data/plugins/`，按 `AGENTS.md` 在目标机现场生成配置与本机 token。
4. 暂存 payload：`runtime/`、`docs/customer/`、`docs/templates/`、`launcher/*.bat`（放到暂存根），
   用官方 7-Zip 生成 LZMA `payload.7z`；`docs/internal/` 不随包。
5. 按 `packaging/iexpress-legacy/qqbot.sed` 调整 SourceFiles，把 `payload.7z`、官方 `7zr.exe`、
   `install.bat` 交给 IExpress 生成单文件安装包（产物不入库）。
6. 用 `packaging/iexpress-legacy/check_stage.ps1` 检查暂存目录：绝对路径泄漏、禁止文件、必需项。

安装后仅监听 `127.0.0.1:3001/6099/6185`；验收按 AI 手册与四联自检执行。

## 运维

长期在线交给根目录的 `MAINTENANCE.md`：每周巡检七项、自修白名单、辅助用户守则、红线与报障格式。
建议配成定时任务，每周一早上 8 点跑一次。

## 安全与免责

- 仓库不含任何真实 Key、token、Cookie、QQ/UIN；本地配置与 `runtime/secrets/` 不入库。
- 所有服务仅绑定 `127.0.0.1`；不要映射到公网。token 泄露时应立即轮换。
- 使用 QQ 小号，不用主号；个人号协议存在平台风控风险，交付前请向客户说明。
- 本项目为独立交付套件，与腾讯、NapCat、AstrBot 官方无隶属关系；
  请遵守 QQ 平台规则及第三方组件许可。软件按现状提供，使用风险自负。
- 已知限制（无头执行器进程回收、中转站额度、单实例锁、payload 缺陷）见 `CHANGELOG.md`。

## License

MIT，见 `LICENSE`。
