import Foundation
import Testing
@testable import onivim3

@Suite(.serialized)
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
            .array([
                .string("grid_resize"),
                .array([.uint(1), .uint(8), .uint(2)])
            ]),
            .array([
                .string("grid_line"),
                .array([
                    .uint(1),
                    .uint(0),
                    .uint(0),
                    .array([
                        .array([.string("h")]),
                        .array([.string("i")]),
                        .array([.string(" "), .uint(0), .uint(6)])
                    ])
                ])
            ]),
            .array([
                .string("grid_cursor_goto"),
                .array([.uint(1), .uint(0), .uint(2)])
            ]),
            .array([
                .string("mode_change"),
                .array([.string("insert"), .uint(1)])
            ]),
            .array([
                .string("flush")
            ])
        ])

        #expect(session.grid.columns == 8)
        #expect(session.grid.rows == 2)
        #expect(session.grid.lineString(row: 0) == "hi      ")
        #expect(session.grid.cursor == EditorGrid.Cursor(row: 0, column: 2))
        #expect(session.mode == "insert")
    }

    @MainActor
    @Test func redrawBatchesDoNotPublishIntermediateGridBeforeFlush() {
        let session = NeovimSession()
        session.applyRedraw([
            .array([
                .string("grid_resize"),
                .array([.uint(1), .uint(8), .uint(2)])
            ]),
            .array([
                .string("grid_line"),
                .array([
                    .uint(1),
                    .uint(1),
                    .uint(0),
                    .array([
                        .array([.string("b"), .uint(0), .uint(8)])
                    ])
                ])
            ])
        ])

        #expect(session.grid.columns == 100)
        #expect(session.grid.rows == 36)
        #expect(session.grid.lineString(row: 1).trimmingCharacters(in: .whitespaces).isEmpty)

        session.applyRedraw([
            .array([
                .string("grid_line"),
                .array([
                    .uint(1),
                    .uint(0),
                    .uint(0),
                    .array([
                        .array([.string("a"), .uint(0), .uint(8)])
                    ])
                ])
            ]),
            .array([
                .string("flush")
            ])
        ])

        #expect(session.grid.columns == 8)
        #expect(session.grid.rows == 2)
        #expect(session.grid.lineString(row: 0) == "aaaaaaaa")
        #expect(session.grid.lineString(row: 1) == "bbbbbbbb")
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

    @MainActor
    @Test func sessionOpenEditSaveQuitReopenPersistsFile() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent("session acceptance.txt")
        FileManager.default.createFile(atPath: fileURL.path, contents: Data())

        let session = NeovimSession()
        defer {
            session.stop()
            try? FileManager.default.removeItem(at: directory)
        }

        try await session.openFile(fileURL)
        _ = try await session.sendInputAndWait("ihello<Esc>")
        try await waitForBufferLine("hello", session: session)
        try await session.save()

        let persisted = try String(contentsOf: fileURL, encoding: .utf8)
        #expect(persisted == "hello\n")
        #expect(session.openedFileURL == fileURL)
        #expect(session.status == "Saved \(fileURL.lastPathComponent)")

        session.stop()

        let reopenedSession = NeovimSession()
        defer { reopenedSession.stop() }

        try await reopenedSession.openFile(fileURL)
        try await waitForBufferLine("hello", session: reopenedSession)
        #expect(reopenedSession.openedFileURL == fileURL)
    }

    @MainActor
    @Test func sessionOpensStartupFileArgumentAndSavesEdits() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent("startup file.txt")
        FileManager.default.createFile(atPath: fileURL.path, contents: Data("seed\n".utf8))

        let startupFile = try #require(StartupFile.fromLaunchArguments([
            "/Applications/onivim3.app/Contents/MacOS/onivim3",
            fileURL.path
        ]))

        let session = NeovimSession()
        defer {
            session.stop()
            try? FileManager.default.removeItem(at: directory)
        }

        try await session.openFile(startupFile)
        try await waitForBufferLines(["seed"], session: session)
        _ = try await session.sendInputAndWait("A cli<Esc>")
        try await waitForBufferLines(["seed cli"], session: session)
        try await session.save()

        let persisted = try String(contentsOf: fileURL, encoding: .utf8)
        #expect(persisted == "seed cli\n")
    }

    @MainActor
    @Test func sessionSupportsMinimalVimMotions() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent("minimal-motions.txt")
        FileManager.default.createFile(atPath: fileURL.path, contents: Data("abc\ndef\n".utf8))

        let session = NeovimSession()
        defer {
            session.stop()
            try? FileManager.default.removeItem(at: directory)
        }

        try await session.openFile(fileURL)
        try await waitForBufferLines(["abc", "def"], session: session)
        try await waitForCursor(EditorGrid.Cursor(row: 0, column: 0), session: session)

        _ = try await session.sendInputAndWait("j")
        try await waitForCursor(EditorGrid.Cursor(row: 1, column: 0), session: session)

        _ = try await session.sendInputAndWait("l")
        try await waitForCursor(EditorGrid.Cursor(row: 1, column: 1), session: session)

        _ = try await session.sendInputAndWait("h")
        try await waitForCursor(EditorGrid.Cursor(row: 1, column: 0), session: session)

        _ = try await session.sendInputAndWait("k")
        try await waitForCursor(EditorGrid.Cursor(row: 0, column: 0), session: session)
    }

    @MainActor
    @Test func sessionSupportsMinimalVimEditingWriteAndQuit() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent("minimal-editing.txt")
        FileManager.default.createFile(atPath: fileURL.path, contents: Data())

        let session = NeovimSession()
        defer {
            session.stop()
            try? FileManager.default.removeItem(at: directory)
        }

        try await session.openFile(fileURL)

        _ = try await session.sendInputAndWait("iabc<Esc>")
        try await waitForBufferLines(["abc"], session: session)

        _ = try await session.sendInputAndWait("a!<Esc>")
        try await waitForBufferLines(["abc!"], session: session)

        _ = try await session.sendInputAndWait("hx")
        try await waitForBufferLines(["ab!"], session: session)

        _ = try await session.sendInputAndWait("u")
        try await waitForBufferLines(["abc!"], session: session)

        _ = try await session.sendInputAndWait("dd")
        try await waitForBufferLines([""], session: session)

        _ = try await session.sendInputAndWait("u")
        try await waitForBufferLines(["abc!"], session: session)

        session.sendInput(":w<CR>")
        try await waitForFileContents("abc!\n", at: fileURL)

        session.sendInput(":q<CR>")
        try await waitForStopped(session)
        #expect(session.status == "Neovim stopped")
    }

    @Test func startupFileLaunchIntentChoosesFirstExistingFileArgument() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let folderURL = directory.appendingPathComponent("workspace", isDirectory: true)
        let fileURL = directory.appendingPathComponent("launch target.txt")
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: fileURL.path, contents: Data("hello\n".utf8))

        let startupFile = StartupFile.fromLaunchArguments([
            "/Applications/onivim3.app/Contents/MacOS/onivim3",
            "-ApplePersistenceIgnoreState",
            "YES",
            folderURL.path,
            fileURL.path
        ])

        #expect(startupFile == fileURL)
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

    @MainActor
    private func waitForBufferLine(_ expected: String, session: NeovimSession) async throws {
        for _ in 0..<100 {
            if try await session.currentBufferLines() == [expected] {
                return
            }
            try await Task.sleep(for: .milliseconds(20))
        }
        throw TestFailure.bufferDidNotReachExpectedText
    }

    @MainActor
    private func waitForBufferLines(_ expected: [String], session: NeovimSession) async throws {
        for _ in 0..<100 {
            if try await session.currentBufferLines() == expected {
                return
            }
            try await Task.sleep(for: .milliseconds(20))
        }
        throw TestFailure.bufferDidNotReachExpectedText
    }

    @MainActor
    private func waitForCursor(_ expected: EditorGrid.Cursor, session: NeovimSession) async throws {
        for _ in 0..<100 {
            if try await session.currentCursor() == expected {
                return
            }
            try await Task.sleep(for: .milliseconds(20))
        }
        throw TestFailure.cursorDidNotReachExpectedPosition
    }

    @MainActor
    private func waitForStopped(_ session: NeovimSession) async throws {
        for _ in 0..<100 {
            if session.state == .stopped {
                return
            }
            try await Task.sleep(for: .milliseconds(20))
        }
        throw TestFailure.sessionDidNotStop
    }

    private func waitForFileContents(_ expected: String, at fileURL: URL) async throws {
        for _ in 0..<100 {
            if (try? String(contentsOf: fileURL, encoding: .utf8)) == expected {
                return
            }
            try await Task.sleep(for: .milliseconds(20))
        }
        throw TestFailure.fileDidNotReachExpectedContents
    }

    private enum TestFailure: Error {
        case bufferDidNotReachExpectedText
        case cursorDidNotReachExpectedPosition
        case fileDidNotReachExpectedContents
        case sessionDidNotStop
    }
}
