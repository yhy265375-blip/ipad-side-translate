import SwiftUI
import Translation
import ReplayKit

@main
struct SideTranslateApp: App {
    var body: some Scene {
        WindowGroup { ReaderView() }
    }
}

struct BroadcastButton: UIViewRepresentable {
    func makeUIView(context: Context) -> RPSystemBroadcastPickerView {
        let view = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 52, height: 52))
        // Derive the identifier after a sideloading tool re-signs/renames the app.
        if let plugins = Bundle.main.builtInPlugInsURL,
           let urls = try? FileManager.default.contentsOfDirectory(at: plugins,
                                      includingPropertiesForKeys: nil),
           let extensionURL = urls.first(where: { $0.pathExtension == "appex" }) {
            view.preferredExtension = Bundle(url: extensionURL)?.bundleIdentifier
        }
        view.showsMicrophoneButton = false
        return view
    }
    func updateUIView(_ uiView: RPSystemBroadcastPickerView, context: Context) {}
}

struct ReaderView: View {
    @StateObject private var model = ReaderModel()
    @State private var configuration: TranslationSession.Configuration?
    @State private var showSettings = false
    @State private var showManual = false
    @State private var manualText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Circle().fill(connectionColor).frame(width: 8, height: 8)
                    Text(model.paused ? "已暂停更新" : model.status)
                        .font(.caption).lineLimit(2)
                    Spacer()
                    Button(model.paused ? "继续" : "暂停") {
                        model.paused.toggle()
                        model.resetRegion()
                    }
                }
                .padding().background(.thinMaterial)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if model.original.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("自由笔记旁边的翻译窗口", systemImage: "rectangle.split.2x1")
                                    .font(.headline)
                                Text("将自由笔记放在屏幕左侧约 ⅔，伴读翻译放在右侧。点击下方屏幕采集按钮，在系统窗口中开始广播。")
                                Text("画面连续两次识别一致后翻译。初次使用可能需要下载英语和中文语言包。")
                                Text("这是未经真机验证的原型；采集期间保持两个 App 同时可见。")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        } else {
                            Label("中文译文", systemImage: "character.bubble")
                                .font(.headline).foregroundStyle(.tint)
                            if model.translated.isEmpty {
                                Text(model.translationStatus.isEmpty ? "准备翻译…" : model.translationStatus)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text(model.translated).font(.title3).textSelection(.enabled)
                            }
                            Divider()
                            Label("识别原文 · 长按选择后使用系统翻译", systemImage: "text.cursor")
                                .font(.subheadline)
                            Text(model.original).textSelection(.enabled)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).padding(20)
                }

                HStack {
                    BroadcastButton().frame(width: 52, height: 52)
                        .accessibilityLabel("开始或停止屏幕采集")
                    Text("屏幕采集\n只在本机处理")
                        .font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Button { showManual = true } label: {
                        Image(systemName: "text.badge.plus")
                    }.accessibilityLabel("手动输入验证翻译")
                    Button { showSettings = true } label: {
                        Image(systemName: "slider.horizontal.3")
                    }.padding(.leading, 12).accessibilityLabel("设置识别区域")
                }.padding(.horizontal).background(.thinMaterial)
            }
            .navigationTitle("伴读翻译 · 原型")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: model.revision) { _, _ in
                model.translationStatus = "正在翻译…"
                if configuration == nil {
                    configuration = .init(source: Locale.Language(identifier: "en"),
                                          target: Locale.Language(identifier: "zh-Hans"))
                } else { configuration?.invalidate() }
            }
            .translationTask(configuration) { session in
                await model.translate(using: session)
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    Form {
                        Section("自由笔记的位置") {
                            Toggle("自由笔记在左边", isOn: $model.sourceOnLeft)
                            Text("识别屏幕宽度的 \(Int(model.sourceFraction * 100))%")
                            Slider(value: $model.sourceFraction, in: 0.25...0.85, step: 0.01)
                            Text("调整到仅包含自由笔记。不要把译文窗口框进去；截图上下各留出 4% 不识别。")
                                .font(.caption)
                        }
                        Section("识别区域预览") {
                            if let image = model.preview {
                                Image(uiImage: image).resizable().scaledToFit()
                            } else { Text("开始采集后显示；预览不会保存到相册。") }
                        }
                        Section("检查采集状态") {
                            TimelineView(.periodic(from: .now, by: 1)) { context in
                                if let date = model.lastFrameDate {
                                    Text("距上次画面 \(Int(context.date.timeIntervalSince(date))) 秒")
                                } else { Text("尚未收到画面") }
                            }
                            Text("超过 8 秒未收到画面：检查系统广播是否开启，并保持本 App 可见。停止采集请点击系统录屏指示。")
                        }
                    }
                    .navigationTitle("识别区域")
                    .toolbar { Button("完成") { model.resetRegion(); showSettings = false } }
                }
            }
            .sheet(isPresented: $showManual) {
                NavigationStack {
                    VStack {
                        Text("单独验证苹果翻译，不代表屏幕采集已成功。")
                            .font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $manualText).padding()
                        Button("翻译这段文字") {
                            model.paused = true
                            model.translateManually(manualText)
                            showManual = false
                        }.buttonStyle(.borderedProminent).disabled(manualText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }.padding().navigationTitle("手动验证")
                        .toolbar { Button("取消") { showManual = false } }
                }
            }
        }
    }

    private var connectionColor: Color {
        guard let date = model.lastFrameDate else { return .gray }
        return Date().timeIntervalSince(date) < 8 ? .green : .orange
    }
}
