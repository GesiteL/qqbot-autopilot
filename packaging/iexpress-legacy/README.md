# IExpress 打包工具链（legacy）

> **状态：legacy，仅用于 v0.1.x 维护。v0.2 起由「零 AI 安装器」取代，本目录整体删除**（历史保留在 git）。
> 新安装器负责：选择盘符、写 `安装信息.txt`、卸载入口、单实例锁。不要再往这里加功能。

## 三件套

| 文件 | 作用 | 备注 |
|---|---|---|
| `install.bat` | 安装脚本：单实例锁 → 问盘符 → 解压 payload → 写安装信息 → 启动 → 清理 | 由 IExpress 以 `cmd /c install.bat` 调用 |
| `qqbot.sed` | IExpress 打包描述：成员清单、启动命令、产物名 | `TargetName` / `SourceFiles0` 是**构建机路径**，每次打包前改成本机路径 |
| `check_stage.ps1` | 暂存目录体检：绝对路径泄漏、禁止文件、必需项 | 检验的是 **payload 暂存根**，不是 IExpress 源目录 |

## 与仓库结构的关系

仓库里的启动器在 `launcher/`，但安装后的运行时必须把两个脚本放在**安装根目录**
（`<安装目录>\启动.bat` 与 `<安装目录>\停止.bat`）——`启动.bat` 用 `%~dp0` 定位 `runtime\`，
所以暂存 payload 时要**把 `launcher\*.bat` 拷到暂存根**，不是拷成 `launcher\` 子目录。

payload 暂存根的期望布局：

```
<stage>\
├── 启动.bat
├── 停止.bat
├── runtime\            # 已装好的 Python / NapCat / AstrBot（含 secrets 与 data）
└── docs\
    ├── customer\       # 对客文档（随包）
    └── templates\      # onebot11 模板、人设
```

`docs/internal/`（安装清单、交付夜分工卡）**不随包**；`install.bat` / `7zr.exe` / `payload.7z`
是 IExpress 的成员，放在构建目录，不在 payload 里。

## 打包步骤（v0.1.x）

1. 准备 payload 暂存根（见上），按 `AGENTS.md` §3 在暂存里现场生成 token 与配置。
2. `check_stage.ps1 -Stage <stage>` 必须输出 `STAGE_CHECK_OK`。
3. 用官方 7-Zip 生成 LZMA 包：`7z a -t7z -m0=lzma payload.7z <stage>\*`。
4. 把 `payload.7z`、官方 `7zr.exe`、本目录 `install.bat` 放进构建目录；
   按本机路径改 `qqbot.sed` 的 `TargetName` 与 `SourceFiles0`。
5. `iexpress /N qqbot.sed` 生成单文件安装包；产物不入库。

## install.bat 行为（本轮改动）

1. **单实例锁**：锁文件含 PID；并发第二个实例被拒；陈旧锁按 PID 判废。
2. **Q0 盘符提问**：`请输入盘符 C/D/E/F，直接回车 = C 盘`，只接受单个字母 C–H；
   目标目录固定为 `<盘符>:\QQBot`（不再写死 C 盘）。
3. **空间提示**：目标盘可用空间 < 10 GB 时提示（不阻断）。
4. **覆盖确认**：目标目录已存在时提示，15 秒无输入默认覆盖。
5. **安装信息**：解压后在根目录写 `安装信息.txt`（安装目录 / 盘符 / 时间 / 版本 / 包大小），
   给客户和后续 AI 一个稳定的路径锚点；无密钥、无账号。
6. **启动与清理**：按内容匹配 `QQ Bot Launcher` 找到启动脚本并拉起，随后删除临时解压目录。

## 已知限制

- **本轮未重打安装包**：`install.bat` 的盘符提问与 `安装信息.txt` 只入了源码，
  现有 `安装包.exe` 内嵌的仍是旧脚本（固定 `C:\QQBot`、无安装信息）。随下一次打包生效。
- **历史 payload 缺陷**：早期打包按目录名排除 `webchat/cache`，误删 AstrBot 的
  `core.platform.sources.webchat` 代码模块，导致 AstrBot 起不来。重建 payload 时必须
  **按完整路径**排除 `secrets`、`.venv`，不要按目录名排除。
- `qqbot.sed` 的路径是 IExpress 语法要求的绝对路径，每次打包都要改；不要提交构建机真实路径。
