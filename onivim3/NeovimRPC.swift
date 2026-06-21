import Foundation

@MainActor
final class NeovimRPC {
    enum LaunchError: LocalizedError {
        case executableNotFound

        var errorDescription: String? {
            switch self {
            case .executableNotFound:
                return "Neovim executable not found. Set ONIVIM_NVIM_PATH or install nvim for the development override."
            }
        }
    }

    enum RPCError: LocalizedError {
        case responseError(MessagePackValue)
        case terminated(String)

        var errorDescription: String? {
            switch self {
            case .responseError(let value):
                return "Neovim RPC returned error: \(value)"
            case .terminated(let reason):
                return reason
            }
        }
    }

    enum Exit: Equatable {
        case clean
        case failed(String)
    }

    private let process: Process
    private let input: Pipe
    private let output: Pipe
    private let errorPipe: Pipe
    private let encoder = MessagePackEncoder()
    private var decoder = MessagePackDecoder()
    private var readBuffer = Data()
    private var nextMessageID: Int64 = 1
    private var responseContinuations: [Int64: CheckedContinuation<MessagePackValue, Error>] = [:]
    private let onMessage: (MessagePackValue) -> Void
    private let onExit: (Exit) -> Void

    init(
        onMessage: @escaping (MessagePackValue) -> Void,
        onExit: @escaping (Exit) -> Void
    ) throws {
        guard let executableURL = Self.resolveExecutableURL() else {
            throw LaunchError.executableNotFound
        }

        self.onMessage = onMessage
        self.onExit = onExit
        self.process = Process()
        self.input = Pipe()
        self.output = Pipe()
        self.errorPipe = Pipe()

        process.executableURL = executableURL
        process.arguments = ["--embed", "--clean", "-n", "--cmd", "set noswapfile"]
        process.standardInput = input
        process.standardOutput = output
        process.standardError = errorPipe
        process.terminationHandler = { [weak self] process in
            let status = process.terminationStatus
            Task { @MainActor [weak self] in
                self?.handleTermination(status: status)
            }
        }

        output.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            Task { @MainActor [weak self] in
                self?.receive(data)
            }
        }

        try process.run()
    }

    func request(method: String, params: [MessagePackValue]) {
        sendRequest(method: method, params: params, continuation: nil)
    }

    func requestValue(method: String, params: [MessagePackValue]) async throws -> MessagePackValue {
        try await withCheckedThrowingContinuation { continuation in
            sendRequest(method: method, params: params, continuation: continuation)
        }
    }

    private func sendRequest(
        method: String,
        params: [MessagePackValue],
        continuation: CheckedContinuation<MessagePackValue, Error>?
    ) {
        let messageID = nextMessageID
        nextMessageID += 1
        if let continuation {
            responseContinuations[messageID] = continuation
        }
        let message: MessagePackValue = .array([
            .uint(0),
            .uint(UInt64(messageID)),
            .string(method),
            .array(params)
        ])
        write(message)
    }

    func terminate() {
        output.fileHandleForReading.readabilityHandler = nil
        errorPipe.fileHandleForReading.readabilityHandler = nil
        process.terminationHandler = nil
        if process.isRunning {
            process.terminate()
        }
    }

    private func write(_ message: MessagePackValue) {
        let data = encoder.encode(message)
        input.fileHandleForWriting.write(data)
    }

    private func receive(_ data: Data) {
        readBuffer.append(data)
        do {
            while let message = try decoder.decodeOne(from: &readBuffer) {
                handleMessage(message)
            }
        } catch {
            fail("Neovim RPC decode failed: \(error)")
        }
    }

    private func handleMessage(_ message: MessagePackValue) {
        guard case .array(let fields) = message,
              let type = fields.first?.intValue else {
            onMessage(message)
            return
        }

        if type == 1, fields.count >= 4, let messageID = fields[1].intValue {
            let continuation = responseContinuations.removeValue(forKey: Int64(messageID))
            if fields[2] != .nilValue {
                continuation?.resume(throwing: RPCError.responseError(fields[2]))
            } else {
                continuation?.resume(returning: fields[3])
            }
        } else {
            onMessage(message)
        }
    }

    private func handleTermination(status: Int32) {
        let continuations = responseContinuations.values
        responseContinuations.removeAll()
        for continuation in continuations {
            continuation.resume(throwing: RPCError.terminated("Neovim exited with status \(status)"))
        }
        onExit(status == 0 ? .clean : .failed("Neovim exited with status \(status)"))
    }

    private func fail(_ reason: String) {
        let continuations = responseContinuations.values
        responseContinuations.removeAll()
        for continuation in continuations {
            continuation.resume(throwing: RPCError.terminated(reason))
        }
        onExit(.failed(reason))
    }

    private static func resolveExecutableURL() -> URL? {
        let environment = ProcessInfo.processInfo.environment
        if let override = environment["ONIVIM_NVIM_PATH"], !override.isEmpty {
            return URL(fileURLWithPath: override)
        }

        if let bundled = Bundle.main.url(forResource: "nvim", withExtension: nil, subdirectory: "Neovim/bin") {
            return bundled
        }

        #if DEBUG
        let candidates = [
            "/opt/homebrew/bin/nvim",
            "/usr/local/bin/nvim",
            "/usr/bin/nvim"
        ]
        for candidate in candidates where FileManager.default.isExecutableFile(atPath: candidate) {
            return URL(fileURLWithPath: candidate)
        }
        #endif

        return nil
    }
}
