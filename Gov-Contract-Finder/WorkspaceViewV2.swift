import SwiftUI

private enum WorkspaceTabV2: String, CaseIterable, Identifiable {
    case tasks
    case notes
    case documents
    case activity

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }
}

struct WorkspaceViewV2: View {
    @Bindable var workspaceStore: WorkspaceStore

    @State private var selectedRecordID: String?
    @State private var activeTab: WorkspaceTabV2 = .tasks

    @State private var newTaskTitle: String = ""
    @State private var newNoteTitle: String = ""
    @State private var newNoteBody: String = ""
    @State private var newDocName: String = ""
    @State private var newDocURL: String = ""

    var body: some View {
        SafeEdgeScrollColumn {
            recordsSection

            if let record = selectedRecord {
                tabPicker
                tabContent(record: record)
            } else {
                NeoCard {
                    Text("No workspace selected")
                        .font(DesignTokensV2.Typography.section)
                        .foregroundStyle(DesignTokensV2.Colors.textPrimary)
                    BoundedBodyText(value: "Open an opportunity and tap Open Workspace, or select an existing record.")
                }
            }
        }
        .background(CyberpunkBackgroundV2())
        .navigationTitle("Workspace")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if selectedRecordID == nil {
                selectedRecordID = workspaceStore.records.first?.id
            }
        }
    }

    private var selectedRecord: WorkspaceRecord? {
        guard let selectedRecordID else { return nil }
        return workspaceStore.records.first(where: { $0.id == selectedRecordID })
    }

    private var recordsSection: some View {
        NeoCard {
            Text("Records")
                .font(DesignTokensV2.Typography.section)
                .foregroundStyle(DesignTokensV2.Colors.textPrimary)

            if workspaceStore.records.isEmpty {
                BoundedBodyText(value: "No records yet.")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignTokensV2.Spacing.xs) {
                        ForEach(workspaceStore.records) { record in
                            FilterChipV2(
                                title: record.opportunityTitle,
                                selected: selectedRecordID == record.id
                            ) {
                                selectedRecordID = record.id
                            }
                        }
                    }
                }
            }
        }
    }

    private var tabPicker: some View {
        HStack(spacing: DesignTokensV2.Spacing.xs) {
            ForEach(WorkspaceTabV2.allCases) { tab in
                FilterChipV2(title: tab.title, selected: activeTab == tab) {
                    withAnimation(DesignTokensV2.Animation.quick) {
                        activeTab = tab
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func tabContent(record: WorkspaceRecord) -> some View {
        switch activeTab {
        case .tasks:
            tasksView(record: record)
        case .notes:
            notesView(record: record)
        case .documents:
            documentsView(record: record)
        case .activity:
            activityView(record: record)
        }
    }

    private func tasksView(record: WorkspaceRecord) -> some View {
        NeoCard {
            Text("Tasks")
                .font(DesignTokensV2.Typography.section)
                .foregroundStyle(DesignTokensV2.Colors.textPrimary)

            InputFieldV2(title: "New Task", placeholder: "Write capability draft", text: $newTaskTitle)

            NeonButton(title: "Add Task", icon: "plus") {
                let title = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !title.isEmpty else { return }
                var updated = record
                updated.tasks.insert(
                    WorkspaceTask(id: UUID().uuidString, title: title, completed: false, dueDate: nil),
                    at: 0
                )
                updated.activity.insert(
                    WorkspaceActivity(id: UUID().uuidString, text: "Task added: \(title)", createdAt: Date()),
                    at: 0
                )
                updated.updatedAt = Date()
                workspaceStore.upsert(updated)
                newTaskTitle = ""
            }

            ForEach(record.tasks) { task in
                HStack {
                    Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(task.completed ? DesignTokensV2.Colors.success : DesignTokensV2.Colors.textSecondary)
                    BoundedBodyText(
                        value: task.title,
                        color: task.completed ? DesignTokensV2.Colors.textSecondary : DesignTokensV2.Colors.textPrimary
                    )
                    Spacer()
                    Button(task.completed ? "Undo" : "Done") {
                        var updated = record
                        guard let index = updated.tasks.firstIndex(where: { $0.id == task.id }) else { return }
                        updated.tasks[index].completed.toggle()
                        updated.activity.insert(
                            WorkspaceActivity(
                                id: UUID().uuidString,
                                text: "Task status changed: \(task.title)",
                                createdAt: Date()
                            ),
                            at: 0
                        )
                        updated.updatedAt = Date()
                        workspaceStore.upsert(updated)
                    }
                    .font(DesignTokensV2.Typography.caption)
                    .foregroundStyle(DesignTokensV2.Colors.accentCyan)
                }
            }
        }
    }

    private func notesView(record: WorkspaceRecord) -> some View {
        NeoCard {
            Text("Notes")
                .font(DesignTokensV2.Typography.section)
                .foregroundStyle(DesignTokensV2.Colors.textPrimary)

            InputFieldV2(title: "Note Title", placeholder: "Capture strategy", text: $newNoteTitle)
            InputFieldV2(title: "Note Body", placeholder: "Write notes...", text: $newNoteBody)

            NeonButton(title: "Add Note", icon: "square.and.pencil") {
                let title = newNoteTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                let body = newNoteBody.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !title.isEmpty || !body.isEmpty else { return }

                var updated = record
                updated.notes.insert(
                    WorkspaceNote(id: UUID().uuidString, title: title.ifEmpty("Untitled"), body: body, updatedAt: Date()),
                    at: 0
                )
                updated.activity.insert(
                    WorkspaceActivity(id: UUID().uuidString, text: "Note added: \(title.ifEmpty("Untitled"))", createdAt: Date()),
                    at: 0
                )
                updated.updatedAt = Date()
                workspaceStore.upsert(updated)
                newNoteTitle = ""
                newNoteBody = ""
            }

            ForEach(record.notes) { note in
                VStack(alignment: .leading, spacing: 4) {
                    BoundedBodyText(
                        value: note.title,
                        font: DesignTokensV2.Typography.bodyStrong,
                        color: DesignTokensV2.Colors.textPrimary
                    )
                    if !note.body.isEmpty {
                        BoundedBodyText(value: note.body)
                    }
                    BoundedBodyText(
                        value: RelativeDateTimeFormatter().localizedString(for: note.updatedAt, relativeTo: Date()),
                        font: DesignTokensV2.Typography.caption
                    )
                }
            }
        }
    }

    private func documentsView(record: WorkspaceRecord) -> some View {
        NeoCard {
            Text("Documents")
                .font(DesignTokensV2.Typography.section)
                .foregroundStyle(DesignTokensV2.Colors.textPrimary)

            InputFieldV2(title: "Document Name", placeholder: "Capability Statement", text: $newDocName)
            InputFieldV2(title: "Document URL", placeholder: "https://...", text: $newDocURL)

            NeonButton(title: "Add Document", icon: "doc") {
                let name = newDocName.trimmingCharacters(in: .whitespacesAndNewlines)
                let url = newDocURL.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty, !url.isEmpty else { return }

                var updated = record
                updated.documents.insert(
                    WorkspaceDocument(id: UUID().uuidString, name: name, url: url, addedAt: Date()),
                    at: 0
                )
                updated.activity.insert(
                    WorkspaceActivity(id: UUID().uuidString, text: "Document added: \(name)", createdAt: Date()),
                    at: 0
                )
                updated.updatedAt = Date()
                workspaceStore.upsert(updated)
                newDocName = ""
                newDocURL = ""
            }

            ForEach(record.documents) { document in
                VStack(alignment: .leading, spacing: 4) {
                    BoundedBodyText(
                        value: document.name,
                        font: DesignTokensV2.Typography.bodyStrong,
                        color: DesignTokensV2.Colors.textPrimary
                    )
                    if let url = URL(string: document.url) {
                        Link(destination: url) {
                            BoundedBodyText(value: document.url, color: DesignTokensV2.Colors.accentCyan)
                        }
                    } else {
                        BoundedBodyText(value: document.url)
                    }
                }
            }
        }
    }

    private func activityView(record: WorkspaceRecord) -> some View {
        NeoCard {
            Text("Activity")
                .font(DesignTokensV2.Typography.section)
                .foregroundStyle(DesignTokensV2.Colors.textPrimary)

            if record.activity.isEmpty {
                BoundedBodyText(value: "No activity yet.")
            } else {
                ForEach(record.activity) { activity in
                    VStack(alignment: .leading, spacing: 4) {
                        BoundedBodyText(value: activity.text, color: DesignTokensV2.Colors.textPrimary)
                        BoundedBodyText(
                            value: RelativeDateTimeFormatter().localizedString(for: activity.createdAt, relativeTo: Date()),
                            font: DesignTokensV2.Typography.caption
                        )
                    }
                }
            }
        }
    }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }
}
