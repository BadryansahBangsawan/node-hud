import Combine
import Foundation

@MainActor
final class NodeStore: ObservableObject {
    @Published var tools: [ToolRow] = []
    @Published var projects: [ProjectRow] = []
    @Published var menuTitle = "Node HUD"
    @Published var persistenceError: String?
    @Published var errorMessage: String?
    @Published var isRefreshing = false

    private var projectRecords: [ProjectRecord] = []
    private var generation = 0

    init() {
        let loaded = ProjectPersistence.load()
        projectRecords = loaded.items
        persistenceError = loaded.error
    }

    func refresh() {
        generation += 1
        let gen = generation
        isRefreshing = true
        let records = projectRecords
        Task {
            let snapshot = await Task.detached(priority: .userInitiated) {
                let extra = ToolLocate.zshPathDirectories()
                let tools = ToolLocate.scan(extraPathDirectories: extra)
                let evaluated = PackageEngines.evaluate(records: records, tools: tools)
                return RefreshSnapshot(
                    tools: tools,
                    rows: evaluated.rows,
                    regexFailed: evaluated.regexFailed,
                    menuTitle: evaluated.menuTitle
                )
            }.value
            guard gen == generation else { return }
            tools = snapshot.tools
            projects = snapshot.rows
            errorMessage = snapshot.regexFailed ? "Internal regex failed." : nil
            menuTitle = snapshot.menuTitle
            isRefreshing = false
        }
    }

    func addProjects() {
        let selected = DirectoryPicker.select()
        var seen = Set(projectRecords.map { ($0.path as NSString).standardizingPath })
        var changed = false
        for path in selected {
            let standardized = (path as NSString).standardizingPath
            if seen.contains(standardized) { continue }
            seen.insert(standardized)
            projectRecords.append(ProjectRecord(path: standardized))
            changed = true
        }
        guard changed else { return }
        saveRecords()
        refresh()
    }

    func removeProject(_ row: ProjectRow) {
        let target = (row.path as NSString).standardizingPath
        projectRecords.removeAll { ($0.path as NSString).standardizingPath == target }
        projects.removeAll { ($0.path as NSString).standardizingPath == target }
        saveRecords()
    }

    private func saveRecords() {
        do {
            try ProjectPersistence.save(projectRecords)
            persistenceError = nil
        } catch {
            persistenceError = error.localizedDescription
        }
    }
}

private struct RefreshSnapshot: Sendable {
    var tools: [ToolRow]
    var rows: [ProjectRow]
    var regexFailed: Bool
    var menuTitle: String
}
