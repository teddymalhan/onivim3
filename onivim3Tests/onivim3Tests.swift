import Foundation
import Testing
@testable import onivim3

struct onivim3Tests {
    @Test func messagePackRoundTripsNeovimRequestShape() throws {
        let value = MessagePackValue.array([
            .uint(0),
            .uint(1),
            .string("nvim_ui_attach"),
            .array([
                .uint(100),
                .uint(36),
                .map([
                    (.string("ext_linegrid"), .bool(true)),
                    (.string("rgb"), .bool(true))
                ])
            ])
        ])

        let encoded = MessagePackEncoder().encode(value)
        var buffer = encoded
        var decoder = MessagePackDecoder()

        let decoded = try #require(try decoder.decodeOne(from: &buffer))
        #expect(decoded == value)
        #expect(buffer.isEmpty)
    }

    @Test func messagePackDecoderWaitsForCompleteValues() throws {
        let encoded = MessagePackEncoder().encode(.array([.string("redraw"), .array([])]))
        var buffer = Data(encoded.prefix(encoded.count - 1))
        var decoder = MessagePackDecoder()

        #expect(try decoder.decodeOne(from: &buffer) == nil)

        buffer.append(encoded.last!)
        let decoded = try #require(try decoder.decodeOne(from: &buffer))
        #expect(decoded == .array([.string("redraw"), .array([])]))
    }

    @MainActor
    @Test func redrawEventsMutateGridAndModeSnapshot() {
        let session = NeovimSession()
        session.applyRedraw([
            .array([.string("grid_resize"), .uint(1), .uint(8), .uint(2)]),
            .array([
                .string("grid_line"),
                .uint(1),
                .uint(0),
                .uint(0),
                .array([
                    .array([.string("h")]),
                    .array([.string("i")]),
                    .array([.string(" "), .uint(0), .uint(6)])
                ])
            ]),
            .array([.string("grid_cursor_goto"), .uint(1), .uint(0), .uint(2)]),
            .array([.string("mode_change"), .string("insert"), .uint(1)])
        ])

        #expect(session.grid.columns == 8)
        #expect(session.grid.rows == 2)
        #expect(session.grid.lineString(row: 0) == "hi      ")
        #expect(session.grid.cursor == EditorGrid.Cursor(row: 0, column: 2))
        #expect(session.mode == "insert")
    }

    @MainActor
    @Test func embeddedNeovimAcceptsModalInputAndWritesFile() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent("modal-input.txt")
        FileManager.default.createFile(atPath: fileURL.path, contents: Data())

        let rpc = try NeovimRPC(onMessage: { _ in }, onExit: { _ in })
        defer {
            rpc.terminate()
            try? FileManager.default.removeItem(at: directory)
        }
        _ = try await rpc.requestValue(
            method: "nvim_ui_attach",
            params: [
                .uint(80),
                .uint(24),
                .map([
                    (.string("ext_linegrid"), .bool(true)),
                    (.string("rgb"), .bool(true))
                ])
            ]
        )


        _ = try await rpc.requestValue(method: "nvim_command", params: [.string("edit " + VimFilename.escape(fileURL.path))])
        _ = try await rpc.requestValue(method: "nvim_input", params: [.string("ihello<Esc>")])

        try await waitForBufferLine("hello", rpc: rpc)

        _ = try await rpc.requestValue(method: "nvim_command", params: [.string("write")])
        let persisted = try String(contentsOf: fileURL, encoding: .utf8)
        #expect(persisted == "hello\n")
    }

    @Test func vimFilenameAndInputEscapingProtectCommandBoundaries() {
        #expect(VimFilename.escape("/tmp/a b|c%#<x>.txt") == "/tmp/a\\ b\\|c\\%\\#\\<x\\>.txt")
        #expect(NeovimInput.escapeLiteralText("a < b") == "a <lt> b")
    }

    @MainActor
    private func waitForBufferLine(_ expected: String, rpc: NeovimRPC) async throws {
        for _ in 0..<100 {
            let result = try await rpc.requestValue(
                method: "nvim_buf_get_lines",
                params: [.uint(0), .uint(0), .int(-1), .bool(true)]
            )
            if result == .array([.string(expected)]) {
                return
            }
            try await Task.sleep(for: .milliseconds(20))
        }
        throw TestFailure.bufferDidNotReachExpectedText
    }

    private enum TestFailure: Error {
        case bufferDidNotReachExpectedText
    }
}
