import Foundation

enum CareDisplay {
    static func localDateString(from date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func formatDisplayDate(_ dateStr: String) -> String {
        guard let date = parseDateString(dateStr) else { return dateStr }
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }

    static func shiftDateString(_ dateStr: String, days: Int) -> String {
        guard let date = parseDateString(dateStr) else { return dateStr }
        guard let shifted = Calendar.current.date(byAdding: .day, value: days, to: date) else { return dateStr }
        return localDateString(from: shifted)
    }

    static func monthString(from date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }

    static func parseDateString(_ dateStr: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateStr)
    }

    static func formatTimestamp(_ iso: String) -> String {
        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = parser.date(from: iso) ?? ISO8601DateFormatter().date(from: iso) ?? Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    static func caregiverName(_ user: UserSummary) -> String {
        let name = [user.firstName, user.lastName].compactMap { $0?.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }.joined(separator: " ")
        return name.isEmpty ? user.email : name
    }

    static func bucketLabel(_ bucket: CareBucket) -> String {
        switch bucket {
        case .activity: return "Activity"
        case .mobility: return "Mobility"
        case .recovery: return "Recovery"
        }
    }

    static func actionSourceLabel(_ source: DailyCareActionSource) -> String? {
        switch source {
        case .plan: return nil
        case .adHoc: return "Added manually"
        case .llmExtracted: return "From voice"
        case .planVariation: return "From voice · variation"
        }
    }

    static func statusLabel(_ status: DailyCareActionStatus) -> String {
        switch status {
        case .pending: return "Pending"
        case .completed: return "Done"
        case .skipped: return "Skipped"
        case .partiallyCompleted: return "Partial"
        case .unclear: return "Unclear"
        }
    }

    static func formatCountdown(totalSeconds: Int) -> String {
        let safe = max(0, totalSeconds)
        let minutes = safe / 60
        let seconds = safe % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    static func calendarDayStatus(_ day: CalendarDaySummary?) -> CalendarDayStatus {
        guard let day, day.totalActions > 0 else { return .none }
        if day.completedCount >= day.totalActions { return .complete }
        if day.completedCount > 0 { return .partial }
        return .pending
    }
}

enum CalendarDayStatus {
    case none, complete, partial, pending
}

enum MeasurementMode {
    case checklist, timer, reps, both

    static func from(targetReps: Int?, targetDurationSeconds: Int?) -> MeasurementMode {
        let hasReps = (targetReps ?? 0) > 0
        let hasTimer = (targetDurationSeconds ?? 0) > 0
        if hasTimer && hasReps { return .both }
        if hasTimer { return .timer }
        if hasReps { return .reps }
        return .checklist
    }
}
