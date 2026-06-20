import AppKit
import SwiftUI

struct EditorGridRepresentable: NSViewRepresentable {
    let session: NeovimSession
    let grid: EditorGrid

    func makeNSView(context: Context) -> EditorGridView {
        let view = EditorGridView(session: session)
        view.grid = grid
        DispatchQueue.main.async { view.window?.makeFirstResponder(view) }
        return view
    }

    func updateNSView(_ nsView: EditorGridView, context: Context) {
        nsView.session = session
        nsView.grid = grid
        nsView.needsDisplay = true
        nsView.updateNeovimSize()
    }
}

@MainActor
final class EditorGridView: NSView, NSTextInputClient {
    var session: NeovimSession
    var grid = EditorGrid.blank(columns: 100, rows: 36)

    private let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
    private lazy var attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.textColor
    ]
    private var cellSize = CGSize(width: 8, height: 16)
    private var markedText = NSAttributedString(string: "")

    init(session: NeovimSession) {
        self.session = session
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
        cellSize = measureCellSize()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
        updateNeovimSize()
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        updateNeovimSize()
    }

    func updateNeovimSize() {
        guard bounds.width > 0, bounds.height > 0 else { return }
        let columns = max(20, Int(bounds.width / max(1, cellSize.width)))
        let rows = max(5, Int(bounds.height / max(1, cellSize.height)))
        session.resize(columns: columns, rows: rows)
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.textBackgroundColor.setFill()
        dirtyRect.fill()

        for row in 0..<grid.rows {
            let baseline = bounds.height - CGFloat(row + 1) * cellSize.height
            let point = CGPoint(x: 0, y: baseline)
            grid.lineString(row: row).draw(at: point, withAttributes: attributes)
        }

        drawCursor()
    }

    override func keyDown(with event: NSEvent) {
        if sendSpecialKey(event) { return }
        inputContext?.handleEvent(event)
    }

    private func sendSpecialKey(_ event: NSEvent) -> Bool {
        if event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.command) {
            switch event.charactersIgnoringModifiers?.lowercased() {
            case "s":
                session.sendInput("<D-s>")
                return true
            case "o":
                session.sendInput("<D-o>")
                return true
            default:
                return false
            }
        }

        switch event.keyCode {
        case 36:
            session.sendInput("<CR>")
        case 48:
            session.sendInput("<Tab>")
        case 51:
            session.sendInput("<BS>")
        case 53:
            session.sendInput("<Esc>")
        case 123:
            session.sendInput("<Left>")
        case 124:
            session.sendInput("<Right>")
        case 125:
            session.sendInput("<Down>")
        case 126:
            session.sendInput("<Up>")
        default:
            return false
        }
        return true
    }

    private func drawCursor() {
        guard grid.cursor.row >= 0,
              grid.cursor.row < grid.rows,
              grid.cursor.column >= 0,
              grid.cursor.column < grid.columns else { return }
        let rect = CGRect(
            x: CGFloat(grid.cursor.column) * cellSize.width,
            y: bounds.height - CGFloat(grid.cursor.row + 1) * cellSize.height,
            width: max(1, cellSize.width),
            height: max(1, cellSize.height)
        )
        NSColor.controlAccentColor.withAlphaComponent(0.45).setFill()
        rect.fill()
    }

    private func measureCellSize() -> CGSize {
        let sample = ("W" as NSString).size(withAttributes: [.font: font])
        return CGSize(width: ceil(sample.width), height: ceil(font.ascender - font.descender + font.leading))
    }

    func hasMarkedText() -> Bool { markedText.length > 0 }

    func markedRange() -> NSRange {
        hasMarkedText() ? NSRange(location: 0, length: markedText.length) : NSRange(location: NSNotFound, length: 0)
    }

    func selectedRange() -> NSRange { NSRange(location: 0, length: 0) }

    func validAttributesForMarkedText() -> [NSAttributedString.Key] { [] }

    func insertText(_ string: Any, replacementRange: NSRange) {
        markedText = NSAttributedString(string: "")
        if let attributed = string as? NSAttributedString {
            session.sendLiteralText(attributed.string)
        } else if let string = string as? String {
            session.sendLiteralText(string)
        }
    }

    func setMarkedText(_ string: Any, selectedRange: NSRange, replacementRange: NSRange) {
        if let attributed = string as? NSAttributedString {
            markedText = attributed
        } else if let string = string as? String {
            markedText = NSAttributedString(string: string)
        }
    }

    func unmarkText() {
        markedText = NSAttributedString(string: "")
    }

    func attributedSubstring(forProposedRange range: NSRange, actualRange: NSRangePointer?) -> NSAttributedString? {
        nil
    }

    func characterIndex(for point: NSPoint) -> Int {
        let localPoint = convert(point, from: nil)
        let row = max(0, min(grid.rows - 1, Int((bounds.height - localPoint.y) / max(1, cellSize.height))))
        let column = max(0, min(grid.columns - 1, Int(localPoint.x / max(1, cellSize.width))))
        return row * grid.columns + column
    }

    func firstRect(forCharacterRange range: NSRange, actualRange: NSRangePointer?) -> NSRect {
        actualRange?.pointee = range
        let rect = CGRect(
            x: CGFloat(grid.cursor.column) * cellSize.width,
            y: bounds.height - CGFloat(grid.cursor.row + 1) * cellSize.height,
            width: cellSize.width,
            height: cellSize.height
        )
        return window?.convertToScreen(convert(rect, to: nil)) ?? rect
    }

    override func doCommand(by selector: Selector) {
        switch selector {
        case #selector(cancelOperation(_:)):
            session.sendInput("<Esc>")
        case #selector(insertNewline(_:)):
            session.sendInput("<CR>")
        case #selector(deleteBackward(_:)):
            session.sendInput("<BS>")
        case #selector(moveLeft(_:)):
            session.sendInput("<Left>")
        case #selector(moveRight(_:)):
            session.sendInput("<Right>")
        case #selector(moveUp(_:)):
            session.sendInput("<Up>")
        case #selector(moveDown(_:)):
            session.sendInput("<Down>")
        default:
            break
        }
    }
}
