import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var session = NeovimSession()
    @State private var isOpeningFile = false

    var body: some View {
        VStack(spacing: 0) {
            EditorGridRepresentable(session: session, grid: session.grid)
                .frame(minWidth: 720, minHeight: 420)

            Divider()

            statusBar
        }
        .toolbar {
            ToolbarItemGroup {
                Button("Open File", systemImage: "doc") {
                    isOpeningFile = true
                }

                Button("Save", systemImage: "square.and.arrow.down") {
                    session.save()
                }
                .disabled(session.state != .running)
            }
        }
        .fileImporter(
            isPresented: $isOpeningFile,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                _ = url.startAccessingSecurityScopedResource()
                session.openFile(url)
            }
        }
        .onAppear {
            session.startIfNeeded()
        }
        .onDisappear {
            session.stop()
        }
    }

    private var statusBar: some View {
        HStack(spacing: 12) {
            Text(session.mode)
                .font(.system(.caption, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.quaternary)
                .clipShape(.rect(cornerRadius: 4))

            Text(session.status)
                .font(.caption)
                .lineLimit(1)

            Spacer()

            Text("\(session.grid.columns)×\(session.grid.rows)")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }
}

#Preview {
    ContentView()
}
