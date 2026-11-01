# 验证记录

更新日期：2026-11-01。开发环境为 Windows + GitHub macOS runner。

## 已有证据

- 两个 Info.plist 可解析，主 App 与扩展 Bundle ID 保持父子关系。
- `RPBroadcastProcessMode` 位于 `NSExtension` 直属字典；工程嵌入屏幕广播扩展。
- 使用 iPad 回环通信，没有 App Groups 或外部翻译服务凭据。节流、单帧限制、串行 OCR、过期结果丢弃已写入，运行时行为待测。
- Windows iTunes 已识别连接的 iPad；iLoader 2.4.1 界面曾明确显示登录成功。这仅证明侧载工具账户登录通过。

## 云端编译与包检查

| 项目 | 首轮 | 场景配置修订后 |
| --- | --- | --- |
| Actions | [41221089448](https://github.com/yhy265375-blip/ipad-side-translate/actions/runs/41221089448) | [41221686778](https://github.com/yhy265375-blip/ipad-side-translate/actions/runs/41221686778) |
| 提交 | `afc15cd7104e61fb6839abe93f848b478c70e95d` | `918ab64ac88e6b835c7f35e4e585111cccfd556b` |
| 结果 | Success | Success |

最近一轮使用 Xcode 16.4，最低系统 18.0。包内主 App 与广播扩展均为真机 Mach-O 二进制，分别为 476008 字节和 98360 字节；IPA 为 112334 字节。ZIP CRC、广播处理配置与显式 SwiftUI scene manifest 已检查；没有嵌入签名或 provisioning profile。

最近一轮 artifact ZIP SHA256（与 GitHub 显示值一致）：

```text
c42dea4b34dc8f798d5a42b7bd80a14f5c5c09901d9571951c8fbdddc7b5bf63
```

未签名 IPA SHA256：

```text
eeb5a97910bad29ac83786414f01e58533c3f6866932755120823589a760902c
```

本次文档整理没有修改 Swift、工程配置或工作流，未重复编译相同源码。

## 安装排查

AltServer 曾返回 `-23782`，提示该账户登录需要 macOS 10.13 或更高版本。苹果账户官网能登录，不能据此认定密码错误或手机号无效。随后改用 iLoader 2.4.1，账户登录通过。

尚未取得足以独立核验 App 完成签名安装、首次启动或屏幕翻译成功的证据。工具登录成功不能等同于 App 功能验收。

## 待真机验证

- 免费签名安装、广播扩展保留、开发者模式下首次启动。
- ATS 配置下的回环通信、广播扩展启动和分屏持续采集。
- 自由笔记画面、方向与识别区域对齐。
- OCR 准确率、多栏顺序、语言包和学术翻译质量。
- 延迟、内存、耗电、发热、锁屏恢复和长时间阅读。
- 免费签名续期、覆盖更新和数据保留。

结论：已编译并检查未签名安装包，真机功能仍待验收。

