import SwiftUI

struct CalendarView: View {
    @Environment(SessionStore.self) private var session

    @State private var selectedDate = Date()
    @State private var visibleMonth = Date()
    @State private var days: [CalendarDaySummary] = []
    @State private var loading = false

    private var dogId: String? { session.activeDogId }
    private var todayString: String { CareDisplay.localDateString() }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Browse past days and track progress")
                    .font(.caption)
                    .foregroundStyle(StarkTheme.mutedForeground)

                legend

                ZStack {
                    MonthCalendarView(
                        month: visibleMonth,
                        selectedDate: selectedDate,
                        days: days,
                        todayString: todayString,
                        onSelectDate: { selectedDate = $0 },
                        onMonthChange: { visibleMonth = $0; Task { await loadCalendar() } }
                    )
                    if loading {
                        SpriteOverlayView(preset: .dailyPlanLoading, mode: .inline, size: .small)
                            .frame(maxWidth: .infinity, minHeight: 200)
                            .background(StarkTheme.background.opacity(0.6))
                    }
                }

                if let dogId {
                    CalendarDayPanelView(
                        dogId: dogId,
                        date: CareDisplay.localDateString(from: selectedDate),
                        apiClient: session.apiClient,
                        onUpdated: { await loadCalendar() }
                    )
                }
            }
            .padding(16)
        }
        .background(StarkTheme.background)
        .onAppear {
            if let preset = session.calendarSelectedDate,
               let date = CareDisplay.parseDateString(preset) {
                selectedDate = date
                visibleMonth = date
                session.calendarSelectedDate = nil
            }
        }
        .task(id: dogId) { await loadCalendar() }
        .onChange(of: visibleMonth) { _, _ in Task { await loadCalendar() } }
    }

    private var legend: some View {
        HStack(spacing: 16) {
            legendItem(color: StarkTheme.primary, label: "All done")
            legendItem(color: StarkTheme.primary.opacity(0.6), label: "Partial")
            legendItem(color: .secondary, label: "Missed")
        }
        .font(.caption2)
        .foregroundStyle(StarkTheme.mutedForeground)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
        }
    }

    private func loadCalendar() async {
        guard let dogId else { return }
        loading = true
        defer { loading = false }
        let month = CareDisplay.monthString(from: visibleMonth)
        do {
            let payload = try await session.apiClient.getCalendar(dogId, month: month)
            days = payload.days
        } catch {
            days = []
        }
    }
}
