import SwiftUI

struct BucketScoreCardView: View {
    let title: String
    let score: BucketScore?
    var updating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title.uppercased())
                    .font(.caption.weight(.medium))
                    .foregroundStyle(StarkTheme.mutedForeground)
                Spacer()
                if updating {
                    Text("Updating…")
                        .font(.caption)
                        .foregroundStyle(StarkTheme.primary)
                }
            }

            if let score {
                Text("\(score.score) · \(score.label)")
                    .font(.title2.weight(.semibold))
                Text(score.summary)
                    .font(.subheadline)
                    .foregroundStyle(StarkTheme.mutedForeground)

                if !score.reasons.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(score.reasons.enumerated()), id: \.offset) { _, reason in
                            HStack(alignment: .top, spacing: 6) {
                                Text("·")
                                    .foregroundStyle(StarkTheme.primary)
                                Text(reason)
                                    .font(.caption)
                                    .foregroundStyle(StarkTheme.mutedForeground)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            } else if !updating {
                Text("No score yet — record a voice update.")
                    .font(.subheadline)
                    .foregroundStyle(StarkTheme.mutedForeground)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(StarkTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(StarkTheme.border))
    }
}
