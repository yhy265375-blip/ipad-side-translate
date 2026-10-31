# 伴读翻译：iPad 免费路线原型

目标：继续在自由笔记阅读图片型 PDF，旁边的窗口自动识别英语并翻译成中文。无需再次导入 PDF。

**当前交付是待真机验证的原型。** 已在 GitHub 私有仓库完成首次 Xcode 真机目标编译并生成未签名 IPA；尚未进行免费签名、安装或 iPad 真机测试。编译通过不能证明免费签名后的屏幕采集一定成功。

## 已写入的功能

- 系统屏幕广播按钮，由使用者手动授权开始；音频不处理。
- 每隔至少 1.5 秒取一帧；同时最多一帧正在传输，不录制视频文件。
- 主 App 接收画面后裁出屏幕左边或右边指定宽度，用苹果 Vision 识别英语。
- 连续两次识别文本相同才更新，避免滚动中反复翻译。这是低频自动更新，**不是无延迟实时翻译**；实际耗时尚未测量。
- 苹果 Translation 框架进行英译中，初次可能要求下载语言包；没有配置付费翻译 API。
- 显示译文、可选择的识别原文、区域预览、暂停开关和手动翻译验证入口。
- 原文长按选中后可使用系统提供的文字菜单；没有在自由笔记内部注入划词菜单，也没有开发专业词典。

## 如何尽量免费

1. 代码在 Windows 上保存和修改。
2. 将本目录内容放到自己的 GitHub 仓库根目录，通过 macOS runner 编译。公开仓库的标准 GitHub-hosted runners 通常可免费使用；私有仓库受账户免费额度等规则限制。使用前在自己的账户确认计费，不开启额外付费额度。
3. 用 AltStore Classic / AltServer 的 Windows 路线，尝试用免费 Apple 账户给生成的 IPA 签名并安装。不走 TestFlight，不要求先付费加入开发者计划。
4. 免费签名通常 7 天到期，需刷新；AltServer 可在电脑与 iPad 同一 Wi-Fi 或 USB 连接时尝试刷新。免费安装存在 App 数量、App ID 和扩展能力限制。

**免费侧载工具存在，不代表这个屏幕广播扩展已被验证可免费安装。** 安装时必须保留 ScreenBroadcast 扩展。若工具要求移除扩展才能安装，屏幕翻译将无法工作，应先保留错误信息排查。

苹果账户信息只在你自己的官方工具界面中输入；不需要发给本聊天。

## 构建步骤

### GitHub 云端构建

1. 创建自己的仓库，将本目录所有文件放在仓库根目录，包括 `.github/workflows/build.yml`。Windows 文件管理器中隐藏的 `.github` 文件夹也要包含。
2. 打开 GitHub 仓库的 Actions，选择 `Build unsigned iPad prototype` → `Run workflow`。
3. 工作流在 macOS 上运行 XcodeGen，再用 Xcode 为真机编译。无需 Apple 密钥或开发者证书。
4. 构建成功后下载 `SideTranslate-unsigned` artifact，解压得到 `SideTranslate-unsigned.ipa`。
5. **该 IPA 没有签名，不能直接点开安装**，需要侧载工具签名。

已创建私有仓库 https://github.com/yhy265375-blip/ipad-side-translate 并上传源码；首次构建成功：https://github.com/yhy265375-blip/ipad-side-translate/actions/runs/41221089448 。生成的主 App 和广播扩展均为真机二进制，下载文件哈希与 GitHub 显示值一致。尚未安装侧载工具或登录 Apple 账户。之后添加的修改应以对应构建记录为准。

### 借用 Mac 时

```sh
brew install xcodegen
xcodegen generate
xcodebuild -project SideTranslate.xcodeproj -scheme SideTranslate \
  -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
```

## 设计与免费权限风险

常规主 App/扩展共享数据会使用 App Groups。本原型没有声明 App Groups，也没有推送或其他付费服务权限。

实验性替代方式：主 App 仅在 `127.0.0.1:38471` 接收，屏幕扩展将 JPEG 帧通过本机 HTTP 发送给主 App；主 App 裁剪、OCR 和翻译。这个地址位于 iPad 本机，不是 Windows 地址，也不是互联网服务。App 不对外监听、不把画面发送给远端服务器；未加入遥测、账户或分析 SDK。

**本机 HTTP 通信、ATS 网络策略、免费签名后扩展能否启动，以及分屏时两进程能否持续工作，都是待验证事项。** 不应把规避 App Groups 的设计等同于已解决免费签名限制。若本机通信失败，不自动退回上传画面到第三方，也不静默改用需要付费的服务。

## 真机使用与验收顺序

1. **安装关**：免费侧载后主 App 能启动，系统广播菜单中能看到“伴读屏幕识别”。
2. **翻译关**：点击底部文字按钮，输入 `The experiment measures the temperature of the sample.`，下载语言包并确认能看到中文。该步骤仅验证翻译，不验证采集。
3. **布局关**：横屏并排，自由笔记在左侧约 65%，伴读翻译在右侧。也支持交换左右。不要把翻译 App 放到自由笔记上方覆盖，否则遮住的内容无法识别。
4. **采集关**：点击底部系统广播按钮，选择本扩展并开始广播。将麦克风保持关闭。
5. **通信关**：设置中应显示最近收到画面的秒数，区域预览应与自由笔记一致。未收到画面先排查广播和本机通信，不把此问题归因于 OCR。
6. **裁剪关**：拖动识别宽度，直到预览只含自由笔记内容。不要包含译文窗口，否则会发生重复识别和反馈。原型为左右矩形区域，上下各排除 4%；不支持任意框选。
7. **稳定关**：停在一页，等待至少两次一致识别，再观察原文和译文；翻页后确认更新。记录实际延迟。多栏排版、公式和小字号可能识别或排序错误，应先放大并使用单栏区域。
8. **持久关**：持续阅读 10 分钟，测试书写批注、放大缩小、横竖屏、锁屏恢复。核实采集是否中断、内存、耗电和发热。本原型没有后台运行保证。
9. **刷新关**：在免费签名到期前刷新，再次确认广播扩展保留且能工作。

不使用时，通过系统录屏/广播指示停止广播。App 的“暂停”只暂停识别更新，**不会停止系统屏幕采集**。

## 当前限制

- 已有未签名 IPA 和云端编译记录；尚无免费签名、安装或真机功能测试结果。未签名包不能直接安装。
- 本版仅英语 → 简体中文。使用苹果基础翻译，学术术语质量尚未评估。
- 仅分屏窗口，未实现悬浮小窗、任意屏幕框选或贴着原文显示中文。
- 需要主 App 与自由笔记同时可见，切到后台不保证持续识别。
- 要连续两次 OCR 完全一致才更新；复杂内容可能迟迟无法稳定。
- 不保存文献和阅读历史，不提供导出，不重新排版复杂文献。
- 不含专业词典；识别原文可以选中文字，不代表自由笔记中的图片变成可选文字。

## 资料

- 苹果文字识别：https://developer.apple.com/documentation/vision/recognizing-text-in-images
- 苹果翻译框架：https://developer.apple.com/documentation/translation
- ReplayKit：https://developer.apple.com/documentation/replaykit/rpbroadcastsamplehandler
- Xcode 要求：https://developer.apple.com/xcode/system-requirements
- GitHub macOS runner：https://docs.github.com/en/actions/reference/runners/github-hosted-runners
- GitHub Actions 计费：https://docs.github.com/en/billing/concepts/product-billing/github-actions
- AltStore Windows 安装：https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows
- AltStore 7 天限制：https://faq.altstore.io/altstore-classic/your-altstore
- AltStore 扩展 App ID：https://faq.altstore.io/altstore-classic/app-ids
