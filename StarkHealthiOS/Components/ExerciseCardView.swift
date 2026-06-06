import SwiftUI

struct ExerciseCardView: View {
    let action: DailyCareActionRecord
    let dogId: String
    let apiClient: APIClient
    let onUpdated: () async -> Void

    @State private var isExpanded = false
    @State private var busy = false

    private var hasMovements: Bool { !(action.steps.isEmpty) }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation { isExpanded.toggle() }
            } label: {
                HStack {
                    Text(action.nameSnapshot)
                        .font(.headline)
                        .foregroundStyle(StarkTheme.foreground)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .foregroundStyle(StarkTheme.mutedForeground)
                }
                .padding()
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(action.categorySnapshot.replacingOccurrences(of: "_", with: " "))
                            .font(.caption)
                            .foregroundStyle(StarkTheme.mutedForeground)
                        Spacer()
                        Text(CareDisplay.statusLabel(action.status))
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(StarkTheme.primary.opacity(0.12))
                            .clipShape(Capsule())
                    }

                    if let progress = action.movementProgress, hasMovements {
                        Text("\(progress.completed) of \(progress.total) movements")
                            .font(.caption)
                            .foregroundStyle(StarkTheme.primary)
                    }

                    if hasMovements {
                        ForEach(action.steps) { movement in
                            MovementRowView(
                                movement: movement,
                                dogId: dogId,
                                apiClient: apiClient,
                                onUpdated: onUpdated
                            )
                        }
                    } else {
                        ExerciseMeasurementView(
                            targetReps: action.targetReps,
                            targetDurationSeconds: action.targetDurationSeconds,
                            completed: action.status == .completed,
                            busy: busy,
                            onMarkDone: { Task { await updateExercise(.completed) } }
                        )
                    }

                    if hasMovements {
                        HStack {
                            if action.status != .completed {
                                Button("Mark entire exercise done") {
                                    Task { await updateExercise(.completed) }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(StarkTheme.primary)
                            }
                            if action.status != .skipped {
                                Button("Skip") {
                                    Task { await updateExercise(.skipped) }
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
                .padding([.horizontal, .bottom])
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func updateExercise(_ status: DailyCareActionStatus) async {
        busy = true
        defer { busy = false }
        do {
            _ = try await apiClient.updateDailyAction(
                dogId,
                actionId: action.id,
                body: UpdateDailyActionBody(status: status)
            )
            await onUpdated()
        } catch {
            print("Exercise update failed: \(error)")
        }
    }
}
