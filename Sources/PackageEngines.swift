import AppKit
import Foundation

struct ProjectRecord: Codable, Identifiable, Equatable, Sendable {
    var path: String
    var id: String { path }
}

struct PackageJSON: Decodable {
    var name: String?
    var engines: Engines?
    var packageManager: String?

    struct Engines: Decodable {
        var node, npm, pnpm, bun, yarn: String?
    }
}

struct ProjectRow: Equatable, Identifiable, Sendable {
    var path: String
    var name: String?
    var error: String?
    var warnings: [String]

    var id: String { path }
}

enum ProjectPersistence {
    static let displayName = "Node HUD"

    static var directory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/\(displayName)", isDirectory: true)
    }

    static var fileURL: URL {
        directory.appendingPathComponent("projects.json")
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private static let decoder = JSONDecoder()

    static func load() -> (items: [ProjectRecord], error: String?) {
        let url = fileURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            return ([], nil)
        }
        do {
            let data = try Data(contentsOf: url)
            let items = try decoder.decode([ProjectRecord].self, from: data)
            return (items, nil)
        } catch {
            return ([], error.localizedDescription)
        }
    }

    static func save(_ items: [ProjectRecord]) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try encoder.encode(items)
        try data.write(to: fileURL, options: .atomic)
    }
}

enum PackageEngines {
    static func evaluate(records: [ProjectRecord], tools: [ToolRow]) -> (rows: [ProjectRow], regexFailed: Bool, menuTitle: String) {
        let regex: NSRegularExpression?
        var regexFailed = false
        do {
            regex = try NSRegularExpression(pattern: "(\\d+)")
        } catch {
            regex = nil
            regexFailed = true
        }

        var versions: [String: String] = [:]
        for tool in tools {
            if !tool.version.isEmpty {
                versions[tool.name] = tool.version
            }
        }

        let rows = records.map { record in
            inspect(record: record, versions: versions, regex: regex)
        }
        return (rows, regexFailed, menuTitle(tools: tools, regex: regex))
    }

    static func menuTitle(tools: [ToolRow], regex: NSRegularExpression?) -> String {
        guard let node = tools.first(where: { $0.name == "node" }), !node.path.isEmpty else {
            return "Node HUD"
        }
        if let major = firstMajor(node.version, regex: regex) {
            return "node \(major)"
        }
        return "node"
    }

    static func firstMajor(_ text: String, regex: NSRegularExpression?) -> String? {
        guard let regex else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              match.numberOfRanges >= 2,
              let swiftRange = Range(match.range(at: 1), in: text)
        else {
            return nil
        }
        return String(text[swiftRange])
    }

    private static func inspect(
        record: ProjectRecord,
        versions: [String: String],
        regex: NSRegularExpression?
    ) -> ProjectRow {
        let packageURL = URL(fileURLWithPath: record.path).appendingPathComponent("package.json")
        guard FileManager.default.fileExists(atPath: packageURL.path) else {
            return ProjectRow(path: record.path, name: nil, error: "No package.json", warnings: [])
        }
        let package: PackageJSON
        do {
            let data = try Data(contentsOf: packageURL)
            package = try JSONDecoder().decode(PackageJSON.self, from: data)
        } catch {
            return ProjectRow(path: record.path, name: nil, error: error.localizedDescription, warnings: [])
        }

        var warnings: [String] = []
        if let engines = package.engines {
            let specs: [(String, String?)] = [
                ("node", engines.node),
                ("npm", engines.npm),
                ("pnpm", engines.pnpm),
                ("bun", engines.bun),
                ("yarn", engines.yarn)
            ]
            for (tool, spec) in specs {
                guard let spec, let version = versions[tool] else { continue }
                guard let specMajor = firstMajor(spec, regex: regex),
                      let versionMajor = firstMajor(version, regex: regex)
                else { continue }
                if specMajor != versionMajor {
                    warnings.append("engines.\(tool) \(spec) vs \(tool) \(version)")
                }
            }
        }

        if let manager = package.packageManager {
            let parts = manager.split(separator: "@", maxSplits: 1, omittingEmptySubsequences: false)
            let tool = String(parts[0]).trimmingCharacters(in: .whitespacesAndNewlines)
            if parts.count > 1, let version = versions[tool] {
                let afterAt = String(parts[1])
                if let specMajor = firstMajor(afterAt, regex: regex),
                   let versionMajor = firstMajor(version, regex: regex),
                   specMajor != versionMajor
                {
                    warnings.append("packageManager \(manager) vs \(tool) \(version)")
                }
            }
        }

        return ProjectRow(path: record.path, name: package.name, error: nil, warnings: warnings)
    }
}

enum DirectoryPicker {
    static func select() -> [String] {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.canCreateDirectories = false
        panel.prompt = "Add"
        panel.message = "Choose a project folder with package.json"
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK else { return [] }
        return panel.urls.map { $0.standardizedFileURL.path }
    }
}

enum PathDisplay {
    static func abbreviate(_ path: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if path == home { return "~" }
        if path.hasPrefix(home + "/") {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
}
