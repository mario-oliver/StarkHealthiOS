import SwiftUI

struct BucketSummaryCardView: View {
    let bucket: CareBucket
    let data: BucketPayload

    private static let cardHeight: CGFloat = 88

    private var title: String {
        switch bucket {
        case .activity: return "Activity"
        case .mobility: return "Mobility"
        case .recovery: return "Recovery"
        }
    }

    private var summary: String {
        switch bucket {
        case .recovery:
            if let score = data.score {
                return "\(score.score) · \(score.label)"
            }
            if !data.observations.isEmpty {
                return "\(data.observations.count) observation(s) today"
            }
            return "Record how Stark is feeling"
        case .mobility:
            if let obs = data.observations.first {
                return obs.note
            }
            if let progress = data.progress, progress.total > 0 {
                return "\(progress.completed) of \(progress.total) complete"
            }
            return "No mobility notes yet"
        case .activity:
            if let progress = data.progress, progress.total > 0 {
                return "\(progress.completed) of \(progress.total) complete"
            }
            let names = data.actions.prefix(3).map(\.nameSnapshot)
            return names.isEmpty ? "Nothing logged yet" : names.joined(separator: ", ")
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(StarkTheme.mutedForeground)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Image(systemName: "chevron.right")
                .foregroundStyle(StarkTheme.mutedForeground)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(height: Self.cardHeight)
        .background(StarkTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(StarkTheme.border))
    }
}
