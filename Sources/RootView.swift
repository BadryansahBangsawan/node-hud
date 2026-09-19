import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: NodeStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: FunTheme.sectionSpacing) {
            Text("Node HUD")
                .font(.headline)

            if let persistenceError = store.persistenceError {
                Label(persistenceError, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let errorMessage = store.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: FunTheme.sectionSpacing) {
                    Text("Tools")
                        .font(.headline)

                    ForEach(store.tools) { tool in
                        ToolRowView(tool: tool)
                    }

                    Text("Projects")
                        .font(.headline)

                    if store.projects.isEmpty {
                        ExtraEmptyState(
                            title: "No projects",
                            detail: "Add a folder that contains package.json.",
                            actionTitle: "Add Project",
                            action: { store.addProjects() }
                        )
                    } else {
                        ForEach(store.projects) { project in
                            ProjectRowView(project: project) {
                                store.removeProject(project)
                            }
                        }
                    }
                }
            }

            HStack(spacing: FunTheme.innerSpacing) {
                Button("Refresh") {
                    store.refresh()
                }
                .buttonStyle(.bordered)
                .disabled(store.isRefreshing)

                if !store.projects.isEmpty {
                    Button("Add Project") {
                        store.addProjects()
                    }
                    .buttonStyle(.bordered)
                }
            }

            ExtraSettingsFooter()
        }
        .animation(reduceMotion ? nil : FunTheme.spring, value: store.tools)
        .animation(reduceMotion ? nil : FunTheme.spring, value: store.projects)
        .animation(reduceMotion ? nil : FunTheme.spring, value: store.errorMessage)
        .funPanel()
        .onAppear {
            store.refresh()
        }
    }
}

private struct ToolRowView: View {
    let tool: ToolRow

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(tool.name)
                    .font(.headline)
                Spacer(minLength: FunTheme.innerSpacing)
                if let error = tool.error {
                    Text(error)
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(tool.version)
                        .font(.system(.body, design: .monospaced))
                }
            }
            if !tool.path.isEmpty {
                Text(PathDisplay.abbreviate(tool.path))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .extraRowSurface()
    }
}

private struct ProjectRowView: View {
    let project: ProjectRow
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FunTheme.innerSpacing) {
            HStack(alignment: .firstTextBaseline) {
                Text(project.name ?? URL(fileURLWithPath: project.path).lastPathComponent)
                    .font(.headline)
                Spacer(minLength: FunTheme.innerSpacing)
                Button("Remove", action: onRemove)
                    .buttonStyle(.bordered)
            }
            Text(PathDisplay.abbreviate(project.path))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if let error = project.error {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(project.warnings, id: \.self) { warning in
                Label(warning, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .extraRowSurface()
    }
}
