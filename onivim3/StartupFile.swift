import Foundation

enum StartupFile {
    static func fromProcessArguments() -> URL? {
        fromLaunchArguments(CommandLine.arguments)
    }

    static func fromLaunchArguments(_ arguments: [String], fileManager: FileManager = .default) -> URL? {
        guard arguments.count > 1 else { return nil }

        for argument in arguments.dropFirst() {
            if argument.hasPrefix("-") {
                continue
            }

            let path = (argument as NSString).expandingTildeInPath
            let url = URL(fileURLWithPath: path).standardizedFileURL
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory), !isDirectory.boolValue else {
                continue
            }
            return url
        }

        return nil
    }
}
