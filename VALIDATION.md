# 验证记录

日期：2026-11-01。环境：Windows，未连接 iPad 开发会话，未发现本机 Swift/Xcode 编译器。

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

## 尚未完成

- GitHub Actions 首次编译、SDK 兼容性检查、IPA 生成。
- AltStore 免费签名、扩展保留、iPadOS 26.6.1 安装及启动。
- ATS 是否允许该配置下的回环通信；广播扩展与主 App 间通信。
- 自由笔记实际画面采集、横竖屏方向、分屏区域对齐。
- OCR 准确率、多栏阅读顺序、英语语言包和中文翻译质量。
- 自动更新延迟、采集持续性、内存、耗电、发热和 7 天刷新。

结论：源码原型可供构建和进一步验证；**没有“已编译通过”“已安装”或“已实测可用”的结论。**
