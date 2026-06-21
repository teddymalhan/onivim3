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

    private(set) var state: State = .stopped
    private(set) var mode: String = "normal"
    private(set) var status: String = "Neovim not started"
    private(set) var grid = EditorGrid.blank(columns: 100, rows: 36)
    private(set) var openedFileURL: URL?

    private var rpc: NeovimRPC?
    private var pendingColumns = 100
    private var pendingRows = 36

    func startIfNeeded() {
        guard state == .stopped else { return }
        state = .starting
        status = "Starting Neovim"

        do {
            let rpc = try NeovimRPC(onMessage: { [weak self] message in
                self?.handleMessage(message)
            }, onExit: { [weak self] reason in
                self?.state = .failed(reason)
                self?.status = reason
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

    func openFile(_ url: URL) {
        startIfNeeded()
        openedFileURL = url
        status = "Opened \(url.lastPathComponent)"
        rpc?.request(method: "nvim_command", params: [.string("edit " + VimFilename.escape(url.path))])
    }

    func save() {
        rpc?.request(method: "nvim_command", params: [.string("write")])
        status = "Saved \(openedFileURL?.lastPathComponent ?? "buffer")"
    }

    func sendInput(_ input: String) {
        startIfNeeded()
        guard !input.isEmpty else { return }
        rpc?.request(method: "nvim_input", params: [.string(input)])
    }

    func sendLiteralText(_ text: String) {
        sendInput(NeovimInput.escapeLiteralText(text))
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

    func applyRedraw(_ events: [MessagePackValue]) {
        var nextGrid = grid
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
            default:
                continue
            }
        }
        grid = nextGrid
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
