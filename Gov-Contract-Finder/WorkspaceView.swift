import SwiftUI

private enum WorkspaceTab: String, CaseIterable, Identifiable {
    case tasks
    case notes
    case documents
    case activity

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .tasks: return "checkmark.square"
        case .notes: return "note.text"
        case .documents: return "paperclip"
        case .activity: return "waveform.path.ecg"
        }
    }
}

struct WorkspaceView: View {
    @Bindable var workspaceStore: WorkspaceStore

    @State private var selectedRecordID: String?
    @State private var activeTab: WorkspaceTab = .tasks

    @State private var newTaskTitle = ""
    @State private var newNoteTitle = ""
    @State private var newNoteBody = ""
    @State private var newDocName = ""
    @State private var newDocURL = ""

    var body: some View {
        SafeEdgeScrollColumn(maxContentWidth: 860) {
            header
            recordsSection

            if let record = selectedRecord {
                summaryCard(record: record)
                tabPicker
                tabContent(record: record)
            } else {
                NeoCard {
                    Text("No workspace selected")
                        .font(DesignTokens.Typography.section)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                    BoundedBodyText(value: "Open an opportunity and tap Open Workspace, or select an existing record.")
                }
            }
        }
        .background(CyberpunkBackground())
        .navigationTitle("Workspace")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if selectedRecordID == nil {
                selectedRecordID = workspaceStore.records.first?.id
            }
        }
        .onChange(of: workspaceStore.records.map(\.id)) { _, recordIDs in
            guard let selectedRecordID else {
                self.selectedRecordID = recordIDs.first
                return
            }

            if !recordIDs.contains(selectedRecordID) {
                self.selectedRecordID = recordIDs.first
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text("Workspace")
                .font(DesignTokens.Typography.hero)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            BoundedBodyText(value: "Track execution for each saved opportunity.")
        }
    }

    private var selectedRecord: WorkspaceRecord? {
        guard let selectedRecordID else { return nil }
        return workspaceStore.records.first(where: { $0.id == selectedRecordID })
    }

    private var recordsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                ForEach(workspaceStore.records) { record in
                    FilterChip(
                        title: record.opportunityTitle,
                        selected: selectedRecordID == record.id
                    ) {
                        selectedRecordID = record.id
                    }
                }
            }
        }
    }

    private func summaryCard(record: WorkspaceRecord) -> some View {
        let total = max(record.tasks.count, 1)
        let completed = record.tasks.filter { $0.completed }.count
        let progress = CGFloat(completed) / CGFloat(total)
        let percent = Int(progress * 100)

        return NeoCard {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.s) {
                BoundedBodyText(
                    value: record.opportunityTitle,
                    font: DesignTokens.Typography.title,
                    color: DesignTokens.Colors.textPrimary
                )

                Spacer()

                ActionPill(
                    title: "Remove From Workflow",
                    tint: DesignTokens.Colors.danger,
                    confirmation: ActionConfirmation(
                        title: "Remove this contract?",
                        message: "This removes the contract from your workspace workflow. Watchlist and alerts stay untouched.",
                        confirmLabel: "Remove",
                        role: .destructive
                    )
                ) {
                    removeRecord(record)
                }
            }

            BoundedBodyText(
                value: "Manage tasks, notes, documents, and activity for this contract.",
                font: DesignTokens.Typography.caption
            )

            BoundedBodyText(value: "Completion Progress", font: DesignTokens.Typography.bodyStrong, color: DesignTokens.Colors.textSecondary)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(DesignTokens.Colors.bg800.opacity(0.8))
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [DesignTokens.Colors.accentCyan, DesignTokens.Colors.accentViolet],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(14, proxy.size.width * progress))
                }
            }
            .frame(height: 12)

            HStack {
                Text("\(completed)/\(record.tasks.count) tasks complete")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                Spacer()
                Text("\(percent)%")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
            }
        }
    }

    private var tabPicker: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            ForEach(WorkspaceTab.allCases) { tab in
                Button {
                    withAnimation(DesignTokens.Animation.quick) {
                        activeTab = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                        Text(tab.title)
                    }
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(activeTab == tab ? DesignTokens.Colors.bg900 : DesignTokens.Colors.textPrimary)
                    .padding(.horizontal, DesignTokens.Spacing.s)
                    .padding(.vertical, DesignTokens.Spacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.button, style: .continuous)
                            .fill(activeTab == tab ? DesignTokens.Colors.accentCyan : DesignTokens.Colors.surface2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.button, style: .continuous)
                            .stroke((activeTab == tab ? DesignTokens.Colors.accentCyan : DesignTokens.Colors.border).opacity(0.8), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
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
            HStack {
                Text("Tasks (\(record.tasks.count))")
                    .font(DesignTokens.Typography.section)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                Spacer()
                Button {
                    addTask(record: record)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("Add Task")
                    }
                    .font(DesignTokens.Typography.bodyStrong)
                    .foregroundStyle(DesignTokens.Colors.bg900)
                    .padding(.horizontal, DesignTokens.Spacing.s)
                    .padding(.vertical, DesignTokens.Spacing.xs)
                    .background(
                        Capsule(style: .continuous)
                            .fill(DesignTokens.Colors.accentCyan)
                    )
                }
                .buttonStyle(.plain)
            }

            InputField(title: "Task Name", placeholder: "Review technical requirements", text: $newTaskTitle)

            if record.tasks.isEmpty {
                BoundedBodyText(value: "No tasks yet.")
            } else {
                ForEach(record.tasks) { task in
                    HStack(spacing: DesignTokens.Spacing.s) {
                        Button {
                            toggleTask(record: record, task: task)
                        } label: {
                            Image(systemName: task.completed ? "checkmark.square.fill" : "square")
                                .foregroundStyle(task.completed ? DesignTokens.Colors.success : DesignTokens.Colors.textSecondary)
                        }
                        .buttonStyle(.plain)

                        BoundedBodyText(
                            value: task.title,
                            color: task.completed ? DesignTokens.Colors.textSecondary : DesignTokens.Colors.textPrimary
                        )

                        Spacer()

                        if let dueDate = task.dueDate {
                            BoundedBodyText(value: shortDate(dueDate), font: DesignTokens.Typography.caption)
                        }
                    }
                    .padding(DesignTokens.Spacing.s)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.button, style: .continuous)
                            .fill(DesignTokens.Colors.surface2.opacity(0.5))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.button, style: .continuous)
                            .stroke(DesignTokens.Colors.border.opacity(0.65), lineWidth: 1)
                    )
                }
            }
        }
    }

    private func notesView(record: WorkspaceRecord) -> some View {
        NeoCard {
            HStack {
                Text("Notes")
                    .font(DesignTokens.Typography.section)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                Spacer()
                Button {
                    addNote(record: record)
                } label: {
                    Text("Add Note")
                        .font(DesignTokens.Typography.bodyStrong)
                        .foregroundStyle(DesignTokens.Colors.bg900)
                        .padding(.horizontal, DesignTokens.Spacing.s)
                        .padding(.vertical, DesignTokens.Spacing.xs)
                        .background(
                            Capsule(style: .continuous)
                                .fill(DesignTokens.Colors.accentCyan)
                        )
                }
                .buttonStyle(.plain)
            }

            InputField(title: "Title", placeholder: "Capture strategy", text: $newNoteTitle)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.button, style: .continuous)
                    .fill(DesignTokens.Colors.bg800.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.button, style: .continuous)
                            .stroke(DesignTokens.Colors.border, lineWidth: 1)
                    )

                TextEditor(text: $newNoteBody)
                    .scrollContentBackground(.hidden)
                    .font(DesignTokens.Typography.body)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .padding(DesignTokens.Spacing.xs)

                if newNoteBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Add a note... Use @mention to notify team members")
                        .font(DesignTokens.Typography.body)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.top, 14)
                        .allowsHitTesting(false)
                }
            }
            .frame(minHeight: 132)

            ForEach(record.notes) { note in
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    BoundedBodyText(
                        value: note.title,
                        font: DesignTokens.Typography.bodyStrong,
                        color: DesignTokens.Colors.textPrimary
                    )
                    if !note.body.isEmpty {
                        BoundedBodyText(value: note.body)
                    }
                    BoundedBodyText(value: relativeDate(note.updatedAt), font: DesignTokens.Typography.caption)
                }
                .padding(DesignTokens.Spacing.s)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.button, style: .continuous)
                        .fill(DesignTokens.Colors.surface2.opacity(0.5))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.button, style: .continuous)
                        .stroke(DesignTokens.Colors.border.opacity(0.8), lineWidth: 1)
                )
            }
        }
    }

    private func documentsView(record: WorkspaceRecord) -> some View {
        NeoCard {
            HStack {
                Text("Documents (\(record.documents.count))")
                    .font(DesignTokens.Typography.section)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Spacer()

                Button {
                    addDocument(record: record)
                } label: {
                    Label("Upload", systemImage: "plus")
                        .font(DesignTokens.Typography.bodyStrong)
                        .foregroundStyle(DesignTokens.Colors.bg900)
                        .padding(.horizontal, DesignTokens.Spacing.s)
                        .padding(.vertical, DesignTokens.Spacing.xs)
                        .background(
                            Capsule(style: .continuous)
                                .fill(DesignTokens.Colors.accentCyan)
                        )
                }
                .buttonStyle(.plain)
            }

            InputField(title: "Document Name", placeholder: "Capability Statement", text: $newDocName)
            InputField(title: "Document URL", placeholder: "https://...", text: $newDocURL)

            ForEach(record.documents) { document in
                if let url = URL(string: document.url) {
                    Link(destination: url) {
                        HStack(spacing: DesignTokens.Spacing.s) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(DesignTokens.Colors.accentCyan)

                            VStack(alignment: .leading, spacing: 2) {
                                BoundedBodyText(
                                    value: document.name,
                                    font: DesignTokens.Typography.bodyStrong,
                                    color: DesignTokens.Colors.textPrimary
                                )
                                BoundedBodyText(value: url.pathExtension.isEmpty ? "FILE" : url.pathExtension.uppercased(), font: DesignTokens.Typography.caption)
                            }

                            Spacer()

                            Image(systemName: "arrow.down.to.line")
                                .foregroundStyle(DesignTokens.Colors.accentCyan)
                        }
                        .padding(DesignTokens.Spacing.s)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.button, style: .continuous)
                                .fill(DesignTokens.Colors.surface2.opacity(0.5))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.button, style: .continuous)
                                .stroke(DesignTokens.Colors.border.opacity(0.8), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    private func activityView(record: WorkspaceRecord) -> some View {
        NeoCard {
            Text("Recent Activity")
                .font(DesignTokens.Typography.section)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            if record.activity.isEmpty {
                BoundedBodyText(value: "No activity yet.")
            } else {
                ForEach(Array(record.activity.prefix(8)).indices, id: \.self) { index in
                    let activity = record.activity[index]
                    HStack(alignment: .top, spacing: DesignTokens.Spacing.s) {
                        VStack(spacing: 2) {
                            Circle()
                                .fill(DesignTokens.Colors.accentCyan)
                                .frame(width: 9, height: 9)
                            if index < min(record.activity.count, 8) - 1 {
                                Rectangle()
                                    .fill(DesignTokens.Colors.accentCyan.opacity(0.35))
                                    .frame(width: 1)
                            }
                        }
                        .frame(width: 10)

                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                            BoundedBodyText(value: activity.text, color: DesignTokens.Colors.textPrimary)
                            BoundedBodyText(value: shortDate(activity.createdAt), font: DesignTokens.Typography.caption)
                        }
                    }
                }
            }
        }
    }

    private func addTask(record: WorkspaceRecord) {
        let title = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).ifEmpty("New Task")
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

    private func toggleTask(record: WorkspaceRecord, task: WorkspaceTask) {
        var updated = record
        guard let index = updated.tasks.firstIndex(where: { $0.id == task.id }) else { return }
        updated.tasks[index].completed.toggle()
        updated.activity.insert(
            WorkspaceActivity(id: UUID().uuidString, text: "Task status changed: \(task.title)", createdAt: Date()),
            at: 0
        )
        updated.updatedAt = Date()
        workspaceStore.upsert(updated)
    }

    private func addNote(record: WorkspaceRecord) {
        let title = newNoteTitle.trimmingCharacters(in: .whitespacesAndNewlines).ifEmpty("Untitled")
        let body = newNoteBody.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty || !body.isEmpty else { return }
        var updated = record
        updated.notes.insert(WorkspaceNote(id: UUID().uuidString, title: title, body: body, updatedAt: Date()), at: 0)
        updated.activity.insert(WorkspaceActivity(id: UUID().uuidString, text: "Note added: \(title)", createdAt: Date()), at: 0)
        updated.updatedAt = Date()
        workspaceStore.upsert(updated)
        newNoteTitle = ""
        newNoteBody = ""
    }

    private func addDocument(record: WorkspaceRecord) {
        let name = newDocName.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = newDocURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !url.isEmpty else { return }
        var updated = record
        updated.documents.insert(WorkspaceDocument(id: UUID().uuidString, name: name, url: url, addedAt: Date()), at: 0)
        updated.activity.insert(WorkspaceActivity(id: UUID().uuidString, text: "Document added: \(name)", createdAt: Date()), at: 0)
        updated.updatedAt = Date()
        workspaceStore.upsert(updated)
        newDocName = ""
        newDocURL = ""
    }

    private func removeRecord(_ record: WorkspaceRecord) {
        workspaceStore.remove(recordID: record.id)
        selectedRecordID = workspaceStore.records.first?.id
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }
}
