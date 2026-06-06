import SwiftUI

struct FeatureCardView: View {
    let systemImage: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 28))
                .foregroundStyle(StarkTheme.primary)

            Text(title)
                .font(.headline)
                .foregroundStyle(StarkTheme.foreground)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(StarkTheme.mutedForeground)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    FeatureCardView(
        systemImage: "mic.fill",
        title: "Speak, don't tap",
        subtitle: "Record a care update in seconds instead of checking boxes."
    )
    .padding()
}
