import Foundation

struct ToolRow: Equatable, Identifiable, Sendable {
    var name: String
    var path: String
    var version: String
    var error: String?

    var id: String { name }
}

enum ToolLocate {
    static let toolNames = ["node", "npm", "pnpm", "bun", "yarn", "fnm", "volta"]

    private final class TimeoutState: @unchecked Sendable {
        var didTimeout = false
    }

    struct RunResult: Sendable {
        var status: Int32
        var stdout: String
        var stderr: String
        var timedOut: Bool
        var launchError: String?
    }

    static func zshPathDirectories() -> [String] {
        let result = run(executable: "/bin/zsh", arguments: ["-lic", "printenv PATH"])
        if result.launchError != nil { return [] }
        if result.timedOut { return [] }
        if result.status != 0 { return [] }
        let trimmed = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return [] }
        return trimmed.split(separator: ":").map(String.init)
    }

    static func scan(extraPathDirectories: [String]) -> [ToolRow] {
        toolNames.map { name in
            locate(name: name, extraPathDirectories: extraPathDirectories)
        }
    }

    static func locate(name: String, extraPathDirectories: [String]) -> ToolRow {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser.path
        var candidates: [String] = [
            "/opt/homebrew/bin/\(name)",
            "/usr/local/bin/\(name)",
            "\(home)/.volta/bin/\(name)",
            "\(home)/.asdf/shims/\(name)",
            "\(home)/.local/bin/\(name)",
            "\(home)/.local/share/fnm/aliases/default/bin/\(name)"
        ]
        if let path = ProcessInfo.processInfo.environment["PATH"] {
            for item in path.split(separator: ":") {
                candidates.append("\(item)/\(name)")
            }
        }
        for item in extraPathDirectories {
            candidates.append("\(item)/\(name)")
        }

        var seen = Set<String>()
        var foundPath: String?
        for raw in candidates {
            let path = (raw as NSString).standardizingPath
            if seen.contains(path) { continue }
            seen.insert(path)
            if fm.isExecutableFile(atPath: path) {
                foundPath = path
                break
            }
        }

        guard let foundPath else {
            return ToolRow(name: name, path: "", version: "", error: "not found")
        }

        let result = run(executable: foundPath, arguments: ["--version"])
        if let launchError = result.launchError {
            return ToolRow(name: name, path: foundPath, version: "", error: launchError)
        }
        if result.status != 0 {
            let trimmed = result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            let message = trimmed.isEmpty ? "version failed" : trimmed
            return ToolRow(name: name, path: foundPath, version: "", error: message)
        }
        let firstLine: String
        if let newline = result.stdout.firstIndex(of: "\n") {
            firstLine = result.stdout[..<newline].trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            firstLine = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return ToolRow(name: name, path: foundPath, version: firstLine, error: nil)
    }

    static func run(executable: String, arguments: [String], timeout: TimeInterval = 3) -> RunResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardInput = FileHandle.nullDevice
        let out = Pipe()
        let err = Pipe()
        process.standardOutput = out
        process.standardError = err

        do {
            try process.run()
        } catch {
            return RunResult(
                status: -1,
                stdout: "",
                stderr: error.localizedDescription,
                timedOut: false,
                launchError: error.localizedDescription
            )
        }

        let state = TimeoutState()
        let timeoutWork = DispatchWorkItem {
            if process.isRunning {
                state.didTimeout = true
                process.terminate()
            }
        }
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + timeout, execute: timeoutWork)
        process.waitUntilExit()
        timeoutWork.cancel()

        let outData: Data
        let errData: Data
        do {
            outData = (try out.fileHandleForReading.readToEnd()) ?? Data()
            errData = (try err.fileHandleForReading.readToEnd()) ?? Data()
        } catch {
            return RunResult(
                status: process.terminationStatus,
                stdout: "",
                stderr: error.localizedDescription,
                timedOut: state.didTimeout,
                launchError: nil
            )
        }

        let stdout = String(data: outData, encoding: .utf8) ?? String(decoding: outData, as: UTF8.self)
        let stderr = String(data: errData, encoding: .utf8) ?? String(decoding: errData, as: UTF8.self)
        return RunResult(
            status: process.terminationStatus,
            stdout: stdout,
            stderr: stderr,
            timedOut: state.didTimeout,
            launchError: nil
        )
    }
}
