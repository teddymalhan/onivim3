import Foundation
import Observation

@Observable
@MainActor
final class NeovimSession {
    enum State: Equatable {
        case stopped
        case starting
        case running
        case failed(String)
    }
    enum SessionError: LocalizedError {
        case notRunning(String)

        var errorDescription: String? {
            switch self {
            case .notRunning(let reason):
                return reason
            }
        }
    }


    private(set) var state: State = .stopped
    private(set) var mode: String = "normal"
    private(set) var status: String = "Neovim not started"
    private(set) var grid = EditorGrid.blank(columns: 100, rows: 36)
    private(set) var openedFileURL: URL?

    private var rpc: NeovimRPC?
    private var pendingColumns = 100
    private var pendingRows = 36
    private var pendingRedrawGrid: EditorGrid?

    func startIfNeeded() {
        guard state == .stopped else { return }
        state = .starting
        status = "Starting Neovim"

        do {
            let rpc = try NeovimRPC(onMessage: { [weak self] message in
                self?.handleMessage(message)
            }, onExit: { [weak self] exit in
                self?.handleExit(exit)
            })
            self.rpc = rpc
            state = .running
            status = "Neovim running"
            attachUI(columns: pendingColumns, rows: pendingRows)
        } catch {
            state = .failed(error.localizedDescription)
            status = error.localizedDescription
        }
    }

    func stop() {
        rpc?.request(method: "nvim_command", params: [.string("qa!")])
        rpc?.terminate()
        rpc = nil
        state = .stopped
        status = "Neovim stopped"
    }

    func resize(columns: Int, rows: Int) {
        let columns = max(20, columns)
        let rows = max(5, rows)
        pendingColumns = columns
        pendingRows = rows
        if grid.columns != columns || grid.rows != rows {
            grid.resize(columns: columns, rows: rows)
        }
        guard state == .running else { return }
        rpc?.request(method: "nvim_ui_try_resize", params: [.uint(UInt64(columns)), .uint(UInt64(rows))])
    }

    func openFile(_ url: URL) async throws {
        let rpc = try runningRPC()
        do {
            _ = try await rpc.requestValue(method: "nvim_command", params: [.string("edit " + VimFilename.escape(url.path))])
            openedFileURL = url
            status = "Opened \(url.lastPathComponent)"
        } catch {
            status = "Open failed: \(error.localizedDescription)"
            throw error
        }
    }

    func save() async throws {
        let rpc = try runningRPC()
        do {
            _ = try await rpc.requestValue(method: "nvim_command", params: [.string("write")])
            status = "Saved \(openedFileURL?.lastPathComponent ?? "buffer")"
        } catch {
            status = "Save failed: \(error.localizedDescription)"
            throw error
        }
    }

    func sendInput(_ input: String) {
        startIfNeeded()
        guard !input.isEmpty else { return }
        rpc?.request(method: "nvim_input", params: [.string(input)])
    }

    @discardableResult
    func sendInputAndWait(_ input: String) async throws -> MessagePackValue {
        guard !input.isEmpty else { return .uint(0) }
        let rpc = try runningRPC()
        return try await rpc.requestValue(method: "nvim_input", params: [.string(input)])
    }

    func sendLiteralText(_ text: String) {
        sendInput(NeovimInput.escapeLiteralText(text))
    }

    func currentBufferLines() async throws -> [String] {
        let rpc = try runningRPC()
        let result = try await rpc.requestValue(
            method: "nvim_buf_get_lines",
            params: [.uint(0), .uint(0), .int(-1), .bool(true)]
        )
        guard case .array(let lines) = result else { return [] }
        return lines.compactMap(\.stringValue)
    }

    func currentCursor() async throws -> EditorGrid.Cursor {
        let rpc = try runningRPC()
        let result = try await rpc.requestValue(method: "nvim_win_get_cursor", params: [.uint(0)])
        guard case .array(let values) = result,
              values.count >= 2,
              let oneBasedRow = values[0].intValue,
              let column = values[1].intValue else {
            return EditorGrid.Cursor(row: 0, column: 0)
        }
        return EditorGrid.Cursor(row: max(0, oneBasedRow - 1), column: max(0, column))
    }

    private func runningRPC() throws -> NeovimRPC {
        startIfNeeded()
        guard let rpc, state == .running else {
            throw SessionError.notRunning(status)
        }
        return rpc
    }

    private func attachUI(columns: Int, rows: Int) {
        rpc?.request(
            method: "nvim_ui_attach",
            params: [
                .uint(UInt64(columns)),
                .uint(UInt64(rows)),
                .map([
                    (.string("ext_linegrid"), .bool(true)),
                    (.string("rgb"), .bool(true)),
                    (.string("ext_multigrid"), .bool(false))
                ])
            ]
        )
    }

    private func handleMessage(_ message: MessagePackValue) {
        guard case .array(let fields) = message,
              fields.count >= 3,
              fields[0].intValue == 2,
              fields[1].stringValue == "redraw",
              let batches = fields[2].arrayValue else { return }
        applyRedraw(batches)
    }

    private func handleExit(_ exit: NeovimRPC.Exit) {
        rpc = nil
        switch exit {
        case .clean:
            state = .stopped
            status = "Neovim stopped"
        case .failed(let reason):
            state = .failed(reason)
            status = reason
        }
    }

    func applyRedraw(_ events: [MessagePackValue]) {
        var nextGrid = pendingRedrawGrid ?? grid
        var didFlush = false
        for event in events {
            guard case .array(let parts) = event,
                  let name = parts.first?.stringValue else { continue }
            let calls = parts.dropFirst().compactMap(\.arrayValue)
            switch name {
            case "grid_resize":
                for call in calls { applyGridResize(call, to: &nextGrid) }
            case "grid_clear":
                if calls.isEmpty {
                    nextGrid.clear()
                } else {
                    for _ in calls { nextGrid.clear() }
                }
            case "grid_line":
                for call in calls { applyGridLine(call, to: &nextGrid) }
            case "grid_cursor_goto":
                for call in calls { applyGridCursor(call, to: &nextGrid) }
            case "grid_scroll":
                for call in calls { applyGridScroll(call, to: &nextGrid) }
            case "mode_change":
                for call in calls { applyModeChange(call) }
            case "flush":
                didFlush = true
            default:
                continue
            }
        }

        if didFlush {
            grid = nextGrid
            pendingRedrawGrid = nil
        } else {
            pendingRedrawGrid = nextGrid
        }
    }

    private func applyGridResize(_ call: [MessagePackValue], to grid: inout EditorGrid) {
        guard call.count >= 3,
              let columns = call[1].intValue,
              let rows = call[2].intValue else { return }
        grid.resize(columns: columns, rows: rows)
    }

    private func applyGridLine(_ call: [MessagePackValue], to grid: inout EditorGrid) {
        guard call.count >= 4,
              let row = call[1].intValue,
              let startColumn = call[2].intValue,
              let cells = call[3].arrayValue else { return }
        var column = startColumn
        for cell in cells {
            guard let parts = cell.arrayValue,
                  let text = parts.first?.stringValue else { continue }
            let repeatCount = parts.count >= 3 ? (parts[2].intValue ?? 1) : 1
            for _ in 0..<max(1, repeatCount) {
                grid.setCell(text, row: row, column: column)
                column += max(1, text.count)
            }
        }
    }

    private func applyGridCursor(_ call: [MessagePackValue], to grid: inout EditorGrid) {
        guard call.count >= 3,
              let row = call[1].intValue,
              let column = call[2].intValue else { return }
        grid.cursor = EditorGrid.Cursor(row: row, column: column)
    }

    private func applyGridScroll(_ call: [MessagePackValue], to grid: inout EditorGrid) {
        guard call.count >= 6,
              let top = call[1].intValue,
              let bottom = call[2].intValue,
              let left = call[3].intValue,
              let right = call[4].intValue,
              let rows = call[5].intValue else { return }
        grid.scroll(top: top, bottom: bottom, left: left, right: right, rows: rows)
    }

    private func applyModeChange(_ call: [MessagePackValue]) {
        guard let modeName = call.first?.stringValue else { return }
        mode = modeName
    }
}

struct VimFilename {
    static func escape(_ path: String) -> String {
        var escaped = ""
        for scalar in path.unicodeScalars {
            switch scalar {
            case " ", "\\", "\t", "\n", "\r", "|", "%", "#", "\"", "<", ">", "*", "[", "]", "$", "`":
                escaped.unicodeScalars.append("\\")
                escaped.unicodeScalars.append(scalar)
            default:
                escaped.unicodeScalars.append(scalar)
            }
        }
        return escaped
    }
}

struct NeovimInput {
    static func escapeLiteralText(_ text: String) -> String {
        text.replacingOccurrences(of: "<", with: "<lt>")
    }
}
