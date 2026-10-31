import Foundation
import Network

/// Device-local transport; no App Group entitlement or external server.
final class FrameServer {
    private let queue = DispatchQueue(label: "sidetranslate.loopback")
    private var listener: NWListener?
    private var connections: [UUID: NWConnection] = [:]
    var onFrame: ((Data) -> Void)?
    var onStatus: ((String) -> Void)?

    func start() {
        queue.async { [weak self] in self?.startOnQueue() }
    }

    private func startOnQueue() {
        guard listener == nil else { return }
        do {
            let parameters = NWParameters.tcp
            parameters.requiredLocalEndpoint = .hostPort(host: "127.0.0.1", port: 38471)
            let listener = try NWListener(using: parameters)
            self.listener = listener
            listener.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready: self?.onStatus?("已就绪，等待屏幕采集")
                case .failed(let error): self?.onStatus?("接收器失败：\(error.localizedDescription)")
                default: break
                }
            }
            listener.newConnectionHandler = { [weak self] connection in
                guard let self else { connection.cancel(); return }
                let id = UUID()
                self.connections[id] = connection
                connection.start(queue: self.queue)
                self.receive(connection, id: id, accumulated: Data())
                // Bound lifetime even for an incomplete HTTP request.
                self.queue.asyncAfter(deadline: .now() + 8) { [weak self] in
                    self?.close(id)
                }
            }
            listener.start(queue: queue)
        } catch { onStatus?("无法启动接收器：\(error.localizedDescription)") }
    }

    private func close(_ id: UUID) {
        connections.removeValue(forKey: id)?.cancel()
    }

    private func receive(_ connection: NWConnection, id: UUID, accumulated: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) {
            [weak self] chunk, _, complete, error in
            guard let self, self.connections[id] != nil else { return }
            var data = accumulated
            if let chunk { data.append(chunk) }
            guard data.count <= 2_100_000, error == nil else { self.close(id); return }
            let separator = Data([13, 10, 13, 10])
            if let headerRange = data.range(of: separator) {
                guard headerRange.lowerBound <= 8192,
                      let headers = String(data: data[..<headerRange.lowerBound], encoding: .utf8)
                else { self.close(id); return }
                let lines = headers.components(separatedBy: "\r\n")
                guard lines.first == "POST /frame HTTP/1.1",
                      let lengthLine = lines.first(where: { $0.lowercased().hasPrefix("content-length:") }),
                      let length = Int(lengthLine.dropFirst("content-length:".count)
                        .trimmingCharacters(in: .whitespaces)),
                      (1...2_000_000).contains(length)
                else { self.close(id); return }
                let start = headerRange.upperBound
                if data.count >= start + length {
                    self.onFrame?(data.subdata(in: start..<(start + length)))
                    let reply = Data("HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\nOK".utf8)
                    connection.send(content: reply, completion: .contentProcessed { [weak self] _ in
                        self?.close(id)
                    })
                    return
                }
            } else if data.count > 8192 { self.close(id); return }
            guard !complete else { self.close(id); return }
            self.receive(connection, id: id, accumulated: data)
        }
    }
}
