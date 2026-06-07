import SwiftUI

struct HistoryView: View {
    @Environment(SessionStore.self) private var session

    @State private var logs: [HistoryLogSummary] = []
    @State private var loading = true

    private var dogId: String? { session.activeDogId }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Past daily care logs")
                    .font(.caption)
                    .foregroundStyle(StarkTheme.mutedForeground)

                if loading {
                    SpriteOverlayView(preset: .dailyPlanLoading, mode: .inline, size: .small)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                } else if logs.isEmpty {
                    SpriteOverlayView(preset: .emptyState, mode: .inline, size: .small)
                } else {
                    ForEach(logs) { log in
                        Button {
                            openLog(log)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(displayDate(log.date))
                                    .font(.headline)
                                    .foregroundStyle(StarkTheme.foreground)
                                Text("\(log.completedCount)/\(log.totalActions) exercises")
                                    .font(.subheadline)
                                    .foregroundStyle(StarkTheme.mutedForeground)
                                if let summary = log.summary {
                                    Text(summary)
                                        .font(.caption)
                                        .foregroundStyle(StarkTheme.mutedForeground)
                                        .lineLimit(2)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
        }
        .background(StarkTheme.background)
        .task(id: dogId) { await loadHistory() }
    }

    private func loadHistory() async {
        guard let dogId else { return }
        loading = true
        defer { loading = false }
        do {
            let payload = try await session.apiClient.getHistory(dogId)
            logs = payload.logs
        } catch {
            logs = []
        }
    }

    private func openLog(_ log: HistoryLogSummary) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = formatter.date(from: log.date) ?? ISO8601DateFormatter().date(from: log.date) ?? Date()
        session.openCalendarDate(CareDisplay.localDateString(from: date))
    }

    private func displayDate(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = formatter.date(from: iso) ?? ISO8601DateFormatter().date(from: iso) ?? Date()
        return CareDisplay.formatDisplayDate(CareDisplay.localDateString(from: date))
    }
}
