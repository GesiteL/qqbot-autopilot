# 交付夜零点击补配（8 步，用户当手）

> 本版不改 NapCat「网络配置」页面，只做文件替换。
> 角色：客户=手机小号持有人；用户=电脑前按 D 口令操作；D=远程只读检查/生成配置，不点击、不扫码、不看密码。
> 红线：只用小号扫码，禁止快速登录/扫大号；UIN 以登录后页面为准，禁止提前写死；token 只在客户机本地替换，禁止发聊天或截图。

## 1. 启动
用户双击 `C:\QQBot\启动.bat`。若 60 秒未就绪，查看 `C:\QQBot\docs\start.log`。D 确认 6099/6185/3001 均为 `127.0.0.1` 监听。

## 2. 打开 NapCat WebUI
浏览器打开 `http://127.0.0.1:6099`。登录 token 从 `C:\QQBot\runtime\secrets\napcat-webui-token.txt` 复制（64 位，不要带换行）。

## 3. 小号扫码
二维码只显示在当前 6099 页面：
- 只让客户的**小号**手机扫码；
- 出现快速登录头像时，点“切换账号/扫码登录”，**绝不点大号头像**；
- D 不看二维码、不保存密码。扫错账号立即退出登录，重扫小号。

## 4. 取现有 OneBot 配置
打开 `C:\QQBot\runtime\napcat\napcat\config\`，找 `onebot11_<UIN>.json`（`<UIN>` = 刚登录小号的数字，禁止提前写死）。
- 有：记事本打开，Ctrl+A、Ctrl+C 发 D；发之前把文件名里的数字和 token/password 值改成 `***`。
- 没有：告诉 D“不存在”。

## 5. D 生成完整配置
D 返回一段从 `{` 开始、到 `}` 结束的完整 JSON（按 `docs\onebot11-template.json`，仅保留结构）：
- 只加 WebSocket **客户端**，地址 `ws://127.0.0.1:3001/ws`；
- `messagePostFormat=array`、`reportSelfMessage=false`；
- token 用占位符 `{{ONEBOT_TOKEN}}`，真 token 不发给 D；
- **禁止**再建 3001 的 WebSocket 服务端（会与 AstrBot 冲突）。
用户不要自行改 JSON 字段。

## 6. 备份 + 整文件替换
- 有原文件：先复制一份 `onebot11_<UIN>.json.bak`。
- 没有原文件：在 config 目录新建文本文档，改名为 `onebot11_<UIN>.json`（确认扩展名是 `.json`）。
- 用记事本打开 `onebot11_<UIN>.json`，Ctrl+A 全选，Ctrl+V 粘贴 D 返回的**整段**，保存。
- 把 `{{ONEBOT_TOKEN}}` 替换为 `C:\QQBot\runtime\secrets\onebot-token.txt` 里的 **64 位 token**（不要带引号、空格、换行）。
- 替换后的文件不要发回 D、不要截图。

## 7. 重启两端
双击 `C:\QQBot\停止.bat`，再双击 `C:\QQBot\启动.bat`，等 6099/6185/3001 就绪。

## 8. 验证与收口
- `netstat -ano | findstr "3001"` 看到 NapCat 与 AstrBot 的 `ESTABLISHED`；
- 3001 的 `LISTENING` 属于 AstrBot/python，不是 NapCat；
- 四端口无 `0.0.0.0`；AstrBot 面板「平台」显示 aiocqhttp 在线。
- 客户按《客户手册-填key.md》填 Key；D 记录结果并进入 008 段二四联验收。

## 回滚
- 恢复 `onebot11_<UIN>.json.bak`，重启两端。
- token 轮换：同时更新 `runtime\secrets\onebot-token.txt` 与 JSON 的 token，重启两端。
- 禁止把 token、二维码、UIN 写进报告、聊天或截图。

---

出问题找谁：________________（微信 / 电话，交付时填写）

免责声明：本软件按现状提供，请仅在合法合规范围内使用；因使用不当或 QQ、模型服务等第三方原因造成的问题，交付方不承担赔偿责任。
