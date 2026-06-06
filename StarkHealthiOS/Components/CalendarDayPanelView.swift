import SwiftUI

struct CalendarDayPanelView: View {
    let dogId: String
    let date: String
    let apiClient: APIClient
    let onUpdated: () async -> Void

    @State private var payload: TodayPayload?
    @State private var loading = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(CareDisplay.formatDisplayDate(date))
                .font(.headline)

            if loading {
                ProgressView()
            } else if let payload {
                Text("\(payload.progress.completed) of \(payload.progress.total) exercises done")
                    .font(.caption)
                    .foregroundStyle(StarkTheme.primary)

                ForEach(payload.dailyLog.dailyCareActions) { action in
                    ExerciseCardView(
                        action: action,
                        dogId: dogId,
                        apiClient: apiClient,
                        onUpdated: reload
                    )
                }
            }
        }
        .padding(.top, 16)
        .task(id: date) { await reload() }
    }

    private func reload() async {
        loading = true
        defer { loading = false }
        do {
            payload = try await apiClient.getToday(dogId, date: date)
            await onUpdated()
        } catch {
            payload = nil
        }
    }
}
