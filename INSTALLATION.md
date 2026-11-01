# Windows + iPad 安装与维护

使用 GitHub macOS runner 构建，再用 Windows 工具签名安装。必须保留屏幕广播扩展。当前验证范围见 [VALIDATION.md](VALIDATION.md)。

## 获取安装包

在 Actions 运行 `Build unsigned iPad prototype`。成功后下载 `SideTranslate-unsigned` artifact，解压出 IPA。artifact 当前保留 7 天，过期可重新构建。

IPA 没有签名，不能直接在 iPad 点开安装。不要把签名证书、账户密码、验证码或已签名私人包提交到仓库。

## 连接设备

1. 安装苹果官方 iTunes 所需设备驱动，确认 Apple Mobile Device Service 正常运行。
2. 用支持数据传输的数据线连接并解锁 iPad，由本人确认“信任此电脑”。
3. 确认 iTunes 能看到设备。资源管理器出现照片/MTP 设备，不代表侧载驱动正常。

此前安装 iCloud 是为尝试 AltServer 路线准备；这不代表所有 iCloud 版本都与 AltServer 兼容，也不代表 iLoader 必须额外安装 iCloud。

## iLoader 导入 IPA

从 [官方仓库](https://github.com/nab138/iloader)的 [Releases](https://github.com/nab138/iloader/releases) 获取工具。本次使用 [2.4.1](https://github.com/nab138/iloader/releases/tag/v2.4.1)。它是第三方工具，来源或哈希核对不等于安全审计。

1. 打开 iLoader，确认 iPad 已连接并选中。
2. 本人输入 Apple 账户并完成双重认证，不向他人发送密码或验证码。
3. 点击 **Import IPA**，选择 `SideTranslate-unsigned.ipa`，按提示签名安装。
4. 保留广播扩展。若工具要求删除扩展才能安装，记录具体错误后排查。
5. 在 iPad 主屏幕或 App 资源库查找“伴读翻译”。

只需导入本项目，无需另装 SideStore 或 LiveContainer。本项目没有配置自动续签。

### 登录错误 -23782

AltServer 可能显示 `A Mac with macOS version 10.13 or later is required to sign in with this Apple Account. (-23782)`。如果苹果官网能登录，应排查客户端认证兼容性，不要反复猜密码，也不要把绑定邮箱当作已证实的解决办法。参考 [AltStore 问题记录](https://github.com/altstoreio/AltStore/issues/1852)。

iLoader 2.4.1 的认证实现使用 Mac/macOS 客户端身份，见 [相关源码提交](https://github.com/nab138/iloader/commit/d319ce7)。因此自己发起的认证可能显示“Mac 正在登录”；提示位置通常按 IP 估算。确认与自己刚发起的操作一致才批准，无法对应则拒绝并检查账户。参考 [苹果双重认证说明](https://support.apple.com/zh-cn/102606)。

## 开发者模式

开发签名 App 通常需要：**设置 → 隐私与安全性 → 开发者模式**，按系统要求重新启动并由本人确认。若提示开发者不受信任，再按提示到 **设置 → 通用 → VPN 与设备管理** 查看自己的开发者项目。

开启后会保持启用，无需每次操作；关闭后开发签名 App 将无法正常运行。它允许运行开发软件并扩大开发调试能力，应只运行可信程序。参考 [苹果 Developer Mode 说明](https://developer.apple.com/videos/play/wwdc2022/110344/)。

## 免费签名续期

免费个人账户签名通常约 7 天有效，以工具显示的到期时间为准。续签本身不要求购买开发者计划，仍受苹果的 App 数量、标识和权限限制。

手动流程：连接 iPad → 打开 iLoader → 使用原签名账户 → **Import IPA** 导入同一 IPA，重新签名并覆盖安装。过期后也优先尝试原账户覆盖安装，避免先删除造成数据丢失。本项目尚未完成跨到期时间的续签实测。参考 [免费签名限制](https://faq.altstore.io/altstore-classic/your-altstore)。

## 更新优化后覆盖安装

构建新 IPA，再由同一签名账户导入。保持主 App、扩展 Bundle ID 与签名团队一致，不要随意随机化标识。原始工程标识：

```text
local.sidetranslate.reader
local.sidetranslate.reader.broadcast
```

满足系统更新条件时通常可覆盖安装并保留数据。更换团队或标识可能被视为另一个 App 或拒绝更新，参考 [苹果安装排错文档](https://developer.apple.com/library/archive/technotes/tn2319/)。

本原型尚无阅读历史持久化；以后增加存储功能时仍需备份并验证数据迁移，不能保证所有未来版本自动保留数据。

## 安装后测试

按 [README 真机验收步骤](README.md#真机验收)，先测手动文字翻译，再测广播、画面接收、裁剪、OCR 和译文更新。

反馈故障时提供系统版本、App 版本、失败步骤和脱敏后的完整错误。不要附密码、验证码、设备序列号或私人画面。

