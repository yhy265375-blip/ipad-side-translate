# 伴读翻译 · SideTranslate

在 iPad 上阅读自由笔记里的图片型文献时，通过系统屏幕广播识别英文，在旁边的 App 窗口显示中文。文献继续留在自由笔记中，无需再次导入。

**当前为待真机功能验收的原型。** 已完成两轮 Xcode 真机目标编译和未签名 IPA 包检查；Windows 侧载工具的账户登录已通过。安装完成、首次启动及“采集 → OCR → 翻译”全过程尚未独立核验。详见 [验证记录](VALIDATION.md)。

## 功能与限制

- SwiftUI iPad App，最低 iPadOS 18.0；英语 → 简体中文。
- ReplayKit 广播由使用者手动开启，音频不处理。
- 至少每 1.5 秒采样一次，同时最多传输一帧；连续两次 OCR 文本相同才更新。实际延迟尚未测量。
- 可调整左侧或右侧识别宽度，查看区域预览、原文和译文，手动输入文字测试翻译。
- 使用苹果 Vision 和 Translation 框架，没有付费翻译 API；初次可能需要下载语言包。
- 目标使用方式为两个 App 并排。未实现悬浮小窗、任意框选、原文覆盖翻译或自由笔记内部划词。
- 多栏、小字号、公式和术语质量待评估；没有阅读历史、导出功能或后台持续运行保证。

## 安装、续签和更新

阅读 [Windows + iPad 安装说明](INSTALLATION.md)，了解 iLoader、开发者模式、免费签名续期、覆盖更新和登录排查。

免费个人账户签名通常约 7 天有效，需重新签名。当前流程为手动连接电脑，在 iLoader 导入 IPA；没有配置自动续签。续签和更新应保持相同签名账户及 App 标识，优先覆盖安装。

## 云端构建

1. 将仓库放到自己的 GitHub 账户，保留 `.github/workflows/build.yml`。
2. 打开 **Actions → Build unsigned iPad prototype → Run workflow**。
3. macOS runner 通过 XcodeGen 生成工程，再为 `iphoneos` 编译主 App 和广播扩展。
4. 成功后下载 `SideTranslate-unsigned` artifact，解压得到 `SideTranslate-unsigned.ipa`。
5. IPA 未签名，需要侧载工具签名，不能直接点开安装。

无需向工作流提供 Apple 密钥或证书。用量规则见 [GitHub Actions 计费文档](https://docs.github.com/en/billing/concepts/product-billing/github-actions)，使用前核对账户额度和 runner 类型。artifact 当前保留 7 天，过期后可重新构建。

最近通过的源码构建：[run 41221686778](https://github.com/yhy265375-blip/ipad-side-translate/actions/runs/41221686778)，提交 `918ab64ac88e6b835c7f35e4e585111cccfd556b`。之后的文档提交没有重新改变或验证 App 行为。

Mac 本地构建：

```sh
brew install xcodegen
xcodegen generate
xcodebuild -project SideTranslate.xcodeproj -scheme SideTranslate \
  -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
```

## 数据流与隐私

```text
系统广播 → JPEG 帧 → iPad 回环接口 → 裁剪 → Vision OCR → Apple Translation → 译文窗口
```

主 App 仅在 `127.0.0.1:38471` 接收扩展发送的帧。地址位于 iPad 本机；源码没有外部画面上传、分析 SDK 或账户系统。语言包由系统处理。没有使用 App Groups，回环通信是实验性实现；免费签名后的扩展启动、ATS 策略及分屏持续通信仍需真机验证。

系统广播可能采集屏幕上的其他内容，使用时留意通知和私人信息。App 的“暂停”只暂停识别更新；停止采集需要通过系统录屏/广播指示结束广播。

## 真机验收

1. 确认主 App 能启动，系统广播菜单中出现本项目扩展。
2. 手动输入 `The experiment measures the temperature of the sample.`，确认语言包和中文翻译可用。
3. 将自由笔记与伴读翻译并排，设置识别侧和宽度，使预览仅包含原文。
4. 手动开始系统广播，保持麦克风关闭，确认最近画面时间和预览更新。
5. 停稳页面等待两次一致识别；翻页后检查原文和译文更新，记录延迟。
6. 连续阅读 10 分钟，测试批注、缩放、转向和锁屏恢复，再单独验证续签与覆盖更新。

未收到画面时先排查广播和本机通信。多栏文献可放大并只识别一栏，不要将译文包含在识别区域内。

## 文件

| 文件 | 用途 |
| --- | --- |
| `SideTranslateApp.swift` | 主界面、翻译会话、系统广播按钮 |
| `ReaderModel.swift` | 裁剪、OCR、稳定判断和翻译状态 |
| `FrameServer.swift` | iPad 本机帧接收 |
| `SampleHandler.swift` | 广播扩展、采样与 JPEG 传输 |
| `project.yml`、两个 `*Info.plist` | XcodeGen 工程与 App/扩展配置 |
| `.github/workflows/build.yml` | 未签名 IPA 云端构建 |

框架资料：[Vision](https://developer.apple.com/documentation/vision/recognizing-text-in-images)、[Translation](https://developer.apple.com/documentation/translation)、[ReplayKit](https://developer.apple.com/documentation/replaykit/rpbroadcastsamplehandler)。

