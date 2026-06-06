import SwiftUI

struct MarketingHeroView<Actions: View>: View {
    let eyebrow: String
    let headline: Text
    let subheadline: String
    @ViewBuilder let actions: () -> Actions

    var body: some View {
        ZStack(alignment: .bottom) {
            Image("StarkHero")
                .resizable()
                .scaledToFill()
                .frame(minHeight: 520)
                .clipped()
                .overlay {
                    LinearGradient(
                        colors: [
                            StarkTheme.background.opacity(0.35),
                            .clear,
                            StarkTheme.background
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }

            VStack(spacing: 24) {
                Text(eyebrow.uppercased())
                    .font(.subheadline.weight(.medium))
                    .tracking(2)
                    .foregroundStyle(StarkTheme.primary.opacity(0.9))

                headline
                    .font(.system(size: 34, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(StarkTheme.foreground)
                    .frame(maxWidth: 560)

                Text(subheadline)
                    .font(.title3)
                    .foregroundStyle(StarkTheme.mutedForeground)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 480)

                actions()
            }
            .padding(.horizontal, 24)
            .padding(.top, 72)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    MarketingHeroView(
        eyebrow: "Voice-first dog PT care",
        headline: Text("Coordinate Stark's daily PT by talking to the app"),
        subheadline: "Caregivers speak naturally about stretches, walks, and how your dog is doing."
    ) {
        Button("Get started") {}
            .buttonStyle(.borderedProminent)
    }
}
