import Foundation
import Combine
import UIKit
import Vision
import Translation

@MainActor
final class ReaderModel: ObservableObject {
    @Published var status = "正在启动本机接收器"
    @Published var original = ""
    @Published var translated = ""
    @Published var translationStatus = ""
    @Published var revision = 0
    @Published var paused = false
    @Published var sourceOnLeft = true
    @Published var sourceFraction = 0.65
    @Published var lastFrameDate: Date?
    @Published var lastPublishedDate: Date?
    @Published var preview: UIImage?

    private let server = FrameServer()
    private let ocrQueue = DispatchQueue(label: "sidetranslate.ocr", qos: .userInitiated)
    private var processing = false
    private var candidate = ""
    private var matches = 0
    private var generation = 0

    init() {
        server.onStatus = { [weak self] message in
            Task { @MainActor in self?.status = message }
        }
        server.onFrame = { [weak self] data in
            Task { @MainActor in self?.accept(data) }
        }
        server.start()
    }

    func resetRegion() {
        generation += 1
        candidate = ""
        matches = 0
        preview = nil
        status = "区域已更新，等待画面停稳"
    }

    func translateManually(_ text: String) {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        original = value
        translated = ""
        revision += 1
    }

    func translate(using session: TranslationSession) async {
        let text = original
        let requestRevision = revision
        guard !text.isEmpty else { return }
        do {
            let response = try await session.translate(text)
            guard requestRevision == revision else { return }
            translated = response.targetText
            translationStatus = ""
        } catch {
            guard requestRevision == revision else { return }
            translationStatus = "翻译失败：\(error.localizedDescription)。请检查语言包。"
        }
    }

    private func accept(_ data: Data) {
        lastFrameDate = Date()
        guard !paused, !processing else { return }
        processing = true
        let fraction = sourceFraction
        let left = sourceOnLeft
        let capturedGeneration = generation
        ocrQueue.async { [weak self] in
            let result: (String, UIImage?, String?) = autoreleasepool {
                guard let image = UIImage(data: data), let cg = image.cgImage else {
                    return ("", nil, "无法解码采集画面")
                }
                // Crop first: the translated window must be outside this rectangle.
                let width = CGFloat(cg.width) * fraction
                let rect = CGRect(x: left ? 0 : CGFloat(cg.width) - width,
                                  y: CGFloat(cg.height) * 0.04,
                                  width: width, height: CGFloat(cg.height) * 0.92).integral
                guard let crop = cg.cropping(to: rect) else {
                    return ("", nil, "识别区域无效")
                }
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.recognitionLanguages = ["en-US"]
                request.usesLanguageCorrection = true
                do {
                    try VNImageRequestHandler(cgImage: crop).perform([request])
                    let text = (request.results ?? []).compactMap {
                        $0.topCandidates(1).first?.string
                    }.joined(separator: "\n")
                    return (String(text.prefix(16_000)), UIImage(cgImage: crop), nil)
                } catch { return ("", UIImage(cgImage: crop), error.localizedDescription) }
            }
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.processing = false
                guard capturedGeneration == self.generation, !self.paused else { return }
                self.preview = result.1
                if let error = result.2 { self.status = "识别失败：\(error)"; return }
                let text = result.0.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else {
                    self.status = "未识别到英文，请检查区域或放大文献"
                    self.candidate = ""
                    self.matches = 0
                    return
                }
                if text == self.candidate { self.matches += 1 }
                else { self.candidate = text; self.matches = 1 }
                guard self.matches >= 2 else { self.status = "等待画面停稳"; return }
                self.status = "识别中 · 页面已稳定"
                guard self.original != text else { return }
                self.original = text
                self.translated = ""
                self.lastPublishedDate = Date()
                self.revision += 1
            }
        }
    }
}
