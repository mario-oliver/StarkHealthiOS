import SwiftUI

struct MonthCalendarView: View {
    let month: Date
    let selectedDate: Date
    let days: [CalendarDaySummary]
    let todayString: String
    let onSelectDate: (Date) -> Void
    let onMonthChange: (Date) -> Void

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button { shiftMonth(-1) } label: { Image(systemName: "chevron.left") }
                Spacer()
                Text(monthTitle).font(.headline)
                Spacer()
                Button { shiftMonth(1) } label: { Image(systemName: "chevron.right") }
            }

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol).font(.caption2).foregroundStyle(StarkTheme.mutedForeground)
                }

                ForEach(dayCells, id: \.self) { cell in
                    if let date = cell {
                        dayButton(for: date)
                    } else {
                        Color.clear.frame(height: 36)
                    }
                }
            }
        }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: month)
    }

    private var dayMap: [String: CalendarDaySummary] {
        Dictionary(uniqueKeysWithValues: days.map { ($0.date, $0) })
    }

    private var dayCells: [Date?] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else {
            return []
        }
        let weekday = calendar.component(.weekday, from: firstOfMonth)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        var cells: [Date?] = Array(repeating: nil, count: leading)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                cells.append(date)
            }
        }
        return cells
    }

    private func dayButton(for date: Date) -> some View {
        let dateString = CareDisplay.localDateString(from: date)
        let summary = dayMap[dateString]
        let status = CareDisplay.calendarDayStatus(summary)
        let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)

        return Button {
            onSelectDate(date)
        } label: {
            VStack(spacing: 4) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.subheadline.weight(isSelected ? .bold : .regular))
                Circle()
                    .fill(dotColor(for: status, dateString: dateString))
                    .frame(width: 6, height: 6)
                    .opacity(status == .none ? 0 : 1)
            }
            .frame(maxWidth: .infinity, minHeight: 36)
            .background(isSelected ? StarkTheme.primary.opacity(0.15) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func dotColor(for status: CalendarDayStatus, dateString: String) -> Color {
        switch status {
        case .complete: return StarkTheme.primary
        case .partial: return StarkTheme.primary.opacity(0.6)
        case .pending:
            return dateString < todayString ? Color.secondary : .clear
        case .none: return .clear
        }
    }

    private func shiftMonth(_ delta: Int) {
        guard let newMonth = Calendar.current.date(byAdding: .month, value: delta, to: month) else { return }
        onMonthChange(newMonth)
    }
}
