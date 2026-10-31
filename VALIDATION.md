# 验证记录

日期：2026-11-01。环境：Windows + GitHub macOS 云端构建，未连接 iPad 开发会话，本机没有 Swift/Xcode 编译器。

## 本地可完成的检查

- 两个 Info.plist 均通过 Python plistlib 解析。
- 主 App 与扩展的 Bundle ID 保持父子关系，扩展声明屏幕广播处理入口。
- 再次审阅时修正广播处理模式键：`RPBroadcastProcessMode` 位于 `NSExtension` 直属字典，参考 WebRTC 的广播扩展示例。为 ObservableObject / Published 显式导入 Combine。
- XcodeGen 工程声明主 App 嵌入 ScreenBroadcast 扩展。
- 工作流使用 macOS runner，为 iphoneos 构建，不要求签名密钥。
- 源码未声明 App Groups 权限，未配置外部翻译服务或凭据。
- 本机传输地址固定为 127.0.0.1，接收器绑定回环地址。
- 采样节流、单帧传输限制、OCR 串行处理、过期翻译结果丢弃均已写入源码；未进行运行时验证。

以上仅为配置检查和源码审阅，不能代替编译或功能验收。

## 首次云端构建与包检查

- 私有仓库：`yhy265375-blip/ipad-side-translate`。
- 构建：https://github.com/yhy265375-blip/ipad-side-translate/actions/runs/41221089448 。提交 `afc15cd7104e61fb6839abe93f848b478c70e95d`，状态 Success。
- Xcode 16.4（包内 DTXcode=1640），最低系统 18.0；主 App 476008 字节、广播扩展 98360 字节，均为 Mach-O 二进制。
- artifact ZIP SHA256 与 GitHub 显示值一致：`e88cf66fbc69915b8ca1c81862b4ebf4bfc9922a26cf2ef55c36fc41aa80574f`。
- 首次未签名 IPA SHA256：`5da4c691dda96f499906da4640798f7be43c42733cfbc9992ea635a0aa3cd3e6`。
- 包含主 App、广播扩展和正确的处理模式配置，ZIP CRC 检查通过；没有嵌入签名或 provisioning profile，需签名后才能安装。
- 后续补充显式 SwiftUI scene manifest；最终包应以该修改后的构建及哈希为准。

## 尚未完成

- scene manifest 修改后的重新编译与最终包检查。
- AltStore 免费签名、扩展保留、iPadOS 26.6.1 安装及启动。
- ATS 是否允许该配置下的回环通信；广播扩展与主 App 间通信。
- 自由笔记实际画面采集、横竖屏方向、分屏区域对齐。
- OCR 准确率、多栏阅读顺序、英语语言包和中文翻译质量。
- 自动更新延迟、采集持续性、内存、耗电、发热和 7 天刷新。

结论：首轮已编译并生成未签名 IPA；**没有“已安装”或“已实测可用”的结论。**
