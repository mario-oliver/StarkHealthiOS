import SwiftUI

struct MovementRowView: View {
    let movement: DailyCareActionStepRecord
    let dogId: String
    let apiClient: APIClient
    let onUpdated: () async -> Void

    @State private var busy = false
    @State private var note = ""
    @State private var editingNote = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(movement.nameSnapshot)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(CareDisplay.statusLabel(movement.status))
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(StarkTheme.primary.opacity(movement.status == .completed ? 0.15 : 0.05))
                    .clipShape(Capsule())
            }

            if let instructions = movement.instructions, !instructions.isEmpty {
                Text(instructions).font(.caption).foregroundStyle(StarkTheme.mutedForeground)
            }

            if movement.status != .completed {
                ExerciseMeasurementView(
                    targetReps: movement.targetReps,
                    targetDurationSeconds: movement.targetDurationSeconds,
                    completed: false,
                    busy: busy,
                    onMarkDone: { Task { await update(status: .completed) } }
                )
            }

            if let mediaUrl = movement.mediaUrl, let url = URL(string: mediaUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    ProgressView()
                }
                .frame(maxHeight: 160)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(12)
        .background(StarkTheme.primary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onAppear { note = movement.notes ?? "" }
    }

    private func update(status: DailyCareActionStatus) async {
        busy = true
        defer { busy = false }
        do {
            _ = try await apiClient.updateDailyActionStep(
                dogId,
                stepId: movement.id,
                body: UpdateDailyActionStepBody(status: status, notes: note.nilIfEmpty)
            )
            await onUpdated()
        } catch {
            print("Movement update failed: \(error)")
        }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
