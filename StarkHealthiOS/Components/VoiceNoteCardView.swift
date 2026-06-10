import SwiftUI

struct VoiceNoteCardView: View {
    let note: VoiceNoteRecord
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(note.transcript.isEmpty ? "(no transcript)" : note.transcript)
                    .font(.subheadline)
                    .lineLimit(expanded ? nil : 2)
                Spacer()
                Text(note.processingStatus.rawValue.lowercased())
                    .font(.caption2)
                    .foregroundStyle(StarkTheme.mutedForeground)
            }

            Text("\(CareDisplay.caregiverName(note.user)) · \(CareDisplay.formatTimestamp(note.createdAt))")
                .font(.caption2)
                .foregroundStyle(StarkTheme.mutedForeground)

            Button(expanded ? "Hide details" : "View transcript") {
                expanded.toggle()
            }
            .font(.caption)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ObservationCardView: View {
    let observation: HealthObservationRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(observation.type.rawValue.replacingOccurrences(of: "_", with: " "))
                .font(.subheadline.weight(.medium))
            Text(observation.note)
                .font(.subheadline)
                .foregroundStyle(StarkTheme.mutedForeground)
            Text("\(CareDisplay.caregiverName(observation.user)) · \(CareDisplay.formatTimestamp(observation.observedAt ?? observation.createdAt))")
                .font(.caption2)
                .foregroundStyle(StarkTheme.mutedForeground)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
