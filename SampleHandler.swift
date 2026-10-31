import ReplayKit
import CoreImage
import ImageIO

final class SampleHandler: RPBroadcastSampleHandler {
    private let context = CIContext(options: [.cacheIntermediates: false])
    private let lock = NSLock()
    private var inFlight = false
    private var lastSample = -Double.infinity
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 3
        configuration.timeoutIntervalForResource = 4
        configuration.httpMaximumConnectionsPerHost = 1
        configuration.urlCache = nil
        return URLSession(configuration: configuration)
    }()

    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer,
                                     with sampleBufferType: RPSampleBufferType) {
        // Audio is discarded. Only one frame can be retained/posted at a time.
        guard sampleBufferType == .video else { return }
        let now = ProcessInfo.processInfo.systemUptime
        lock.lock()
        guard !inFlight, now - lastSample >= 1.5 else { lock.unlock(); return }
        inFlight = true
        lastSample = now
        lock.unlock()

        let jpeg: Data? = autoreleasepool {
            guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
            var image = CIImage(cvPixelBuffer: buffer)
            if let number = CMGetAttachment(sampleBuffer,
                    key: RPVideoSampleOrientationKey as CFString, attachmentModeOut: nil) as? NSNumber,
               let orientation = CGImagePropertyOrientation(rawValue: number.uint32Value) {
                image = image.oriented(orientation)
            }
            let scale = min(1, 2048 / max(image.extent.width, image.extent.height))
            image = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            return context.jpegRepresentation(of: image,
                colorSpace: CGColorSpaceCreateDeviceRGB(),
                options: [CIImageRepresentationOption(rawValue:
                    kCGImageDestinationLossyCompressionQuality as String): 0.75])
        }
        guard let jpeg, jpeg.count <= 2_000_000 else { releaseSlot(); return }
        var request = URLRequest(url: URL(string: "http://127.0.0.1:38471/frame")!)
        request.httpMethod = "POST"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.httpBody = jpeg
        session.dataTask(with: request) { [weak self] _, _, _ in self?.releaseSlot() }.resume()
    }

    private func releaseSlot() {
        lock.lock()
        inFlight = false
        lock.unlock()
    }

    override func broadcastFinished() {
        session.invalidateAndCancel()
    }
}
