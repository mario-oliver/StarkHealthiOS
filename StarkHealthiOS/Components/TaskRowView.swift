import SwiftUI

struct TaskRowView: View {
    let task: DailyTaskRecord
    let dogId: String
    let apiClient: APIClient
    let onUpdated: () async -> Void

    @State private var busy = false
    @State private var editingNote = false
    @State private var note = ""

    private var isCompleted: Bool { task.status == .completed }
    private var isSkipped: Bool { task.status == .skipped }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                Task { await toggleComplete() }
            } label: {
                Image(systemName: isCompleted ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(isCompleted ? StarkTheme.primary : StarkTheme.mutedForeground)
            }
            .buttonStyle(.plain)
            .disabled(busy || isSkipped)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(task.nameSnapshot)
                        .font(.body.weight(.medium))
                        .strikethrough(isCompleted)
                        .foregroundStyle(isCompleted || isSkipped ? StarkTheme.mutedForeground : StarkTheme.foreground)

                    if let badge = CareDisplay.taskSourceLabel(task.source) {
                        Text(badge)
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(Capsule())
                    }

                    if task.needsReview {
                        Text("Review")
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                    }
                }

                if let sub = task.substitutedFor {
                    Text("Substituted for \(sub.nameSnapshot)")
                        .font(.caption)
                        .foregroundStyle(StarkTheme.mutedForeground)
                }

                if let description = task.descriptionSnapshot, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(StarkTheme.mutedForeground)
                }

                if let instructions = task.instructionsSnapshot, !instructions.isEmpty {
                    Text(instructions)
                        .font(.caption)
                        .foregroundStyle(StarkTheme.mutedForeground)
                }

                if let notes = task.notes, !editingNote {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(StarkTheme.mutedForeground)
                }

                if task.completedBy != nil || task.completedAt != nil {
                    Text(completionLine)
                        .font(.caption2)
                        .foregroundStyle(StarkTheme.mutedForeground)
                }

                HStack(spacing: 12) {
                    if !isCompleted && !isSkipped {
                        Button("Skip") {
                            Task { await update(status: .skipped) }
                        }
                        .font(.caption)
                        .disabled(busy)
                    }

                    Button(editingNote ? "Cancel" : "Note") {
                        if editingNote {
                            editingNote = false
                        } else {
                            note = task.notes ?? ""
                            editingNote = true
                        }
                    }
                    .font(.caption)

                    if task.needsReview {
                        Button("Confirm") {
                            Task { await update(status: task.status, needsReview: false) }
                        }
                        .font(.caption.weight(.medium))
                        .disabled(busy)
                    }
                }
                .padding(.top, 4)

                if editingNote {
                    HStack(spacing: 8) {
                        TextField("Add a note", text: $note)
                            .textFieldStyle(.roundedBorder)
                        Button("Save") {
                            Task {
                                await update(notes: note)
                                editingNote = false
                            }
                        }
                        .font(.caption.weight(.medium))
                        .disabled(busy)
                    }
                }
            }
        }
        .padding()
        .background(StarkTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(StarkTheme.border))
        .opacity(isSkipped ? 0.6 : (isCompleted ? 0.85 : 1))
    }

    private var completionLine: String {
        var parts: [String] = []
        if let user = task.completedBy {
            parts.append("By \(CareDisplay.caregiverName(user))")
        }
        if let completedAt = task.completedAt {
            parts.append(CareDisplay.formatTimestamp(completedAt))
        }
        return parts.joined(separator: " · ")
    }

    private func toggleComplete() async {
        if isCompleted {
            await update(status: .pending)
        } else {
            await update(status: .completed, needsReview: false)
        }
    }

    private func update(
        status: DailyCareActionStatus? = nil,
        notes: String? = nil,
        needsReview: Bool? = nil
    ) async {
        busy = true
        defer { busy = false }
        do {
            _ = try await apiClient.updateDailyTask(
                dogId,
                taskId: task.id,
                body: UpdateDailyTaskBody(status: status, notes: notes, needsReview: needsReview)
            )
            await onUpdated()
        } catch {
            // Parent handles errors via refresh
        }
    }
}
