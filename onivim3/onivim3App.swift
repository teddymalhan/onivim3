import SwiftUI

@main
struct onivim3App: App {
    private let startupFile = StartupFile.fromProcessArguments()

    var body: some Scene {
        WindowGroup {
            ContentView(startupFile: startupFile)
        }
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
