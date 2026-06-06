import SwiftUI

struct CareActionCardView: View {
    let action: CareActionRecord
    let onEdit: () -> Void
    let onDeactivate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(action.name).font(.headline)
                Spacer()
                Menu {
                    Button("Edit", action: onEdit)
                    Button("Deactivate", role: .destructive, action: onDeactivate)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }

            HStack(spacing: 8) {
                Text(action.category.rawValue.replacingOccurrences(of: "_", with: " "))
                    .font(.caption)
                    .foregroundStyle(StarkTheme.mutedForeground)

                Text(CareDisplay.bucketLabel(action.bucket ?? .activity))
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(StarkTheme.primary.opacity(0.12))
                    .foregroundStyle(StarkTheme.primary)
                    .clipShape(Capsule())
            }

            Text("\(action.frequency.rawValue.replacingOccurrences(of: "_", with: " ")) · \(action.steps.count) movements")
                .font(.caption2)
                .foregroundStyle(StarkTheme.mutedForeground)

            if let description = action.description, !description.isEmpty {
                Text(description).font(.subheadline).foregroundStyle(StarkTheme.mutedForeground)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
