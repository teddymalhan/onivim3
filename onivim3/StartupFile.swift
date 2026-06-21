import Foundation

enum StartupFile {
    static func fromProcessArguments() -> URL? {
        fromLaunchArguments(CommandLine.arguments)
    }

    static func fromLaunchArguments(_ arguments: [String], fileManager: FileManager = .default) -> URL? {
        guard arguments.count > 1 else { return nil }

        var skipsNextOptionValue = false
        for argument in arguments.dropFirst() {
            if skipsNextOptionValue {
                skipsNextOptionValue = false
                continue
            }

            if argument.hasPrefix("-") {
                skipsNextOptionValue = true
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
