import Foundation

struct EditorGrid: Equatable, Sendable {
    struct Cursor: Equatable, Sendable {
        var row: Int
        var column: Int
    }

    private(set) var columns: Int
    private(set) var rows: Int
    private(set) var cells: [[String]]
    var cursor = Cursor(row: 0, column: 0)

    static func blank(columns: Int, rows: Int) -> EditorGrid {
        EditorGrid(columns: columns, rows: rows)
    }

    init(columns: Int, rows: Int) {
        self.columns = max(1, columns)
        self.rows = max(1, rows)
        self.cells = Array(repeating: Array(repeating: " ", count: self.columns), count: self.rows)
    }

    mutating func resize(columns: Int, rows: Int) {
        let newColumns = max(1, columns)
        let newRows = max(1, rows)
        var next = Array(repeating: Array(repeating: " ", count: newColumns), count: newRows)
        for row in 0..<min(self.rows, newRows) {
            for column in 0..<min(self.columns, newColumns) {
                next[row][column] = cells[row][column]
            }
        }
        self.columns = newColumns
        self.rows = newRows
        self.cells = next
        cursor.row = min(cursor.row, newRows - 1)
        cursor.column = min(cursor.column, newColumns - 1)
    }

    mutating func clear() {
        cells = Array(repeating: Array(repeating: " ", count: columns), count: rows)
        cursor = Cursor(row: 0, column: 0)
    }

    mutating func setCell(_ text: String, row: Int, column: Int) {
        guard row >= 0, row < rows, column >= 0, column < columns else { return }
        cells[row][column] = text.isEmpty ? " " : text
    }

    mutating func scroll(top: Int, bottom: Int, left: Int, right: Int, rows delta: Int) {
        guard top >= 0, top <= bottom, bottom <= rows, left >= 0, left <= right, right <= columns, delta != 0 else { return }
        let rowRange = top..<bottom
        let columnRange = left..<right
        if delta > 0 {
            for row in rowRange {
                let source = row + delta
                for column in columnRange {
                    cells[row][column] = source < bottom ? cells[source][column] : " "
                }
            }
        } else {
            for row in rowRange.reversed() {
                let source = row + delta
                for column in columnRange {
                    cells[row][column] = source >= top ? cells[source][column] : " "
                }
            }
        }
    }

    func lineString(row: Int) -> String {
        guard row >= 0, row < rows else { return "" }
        return cells[row].joined()
    }
}
