import ClerkKit
import SwiftUI

struct LandingView: View {
    @Environment(Clerk.self) private var clerk
    @Environment(SessionStore.self) private var session
    @State private var showAuth = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                landingHeader

                MarketingHeroView(
                    eyebrow: "Voice-first dog PT care",
                    headline: headline,
                    subheadline: "Caregivers speak naturally about stretches, walks, and how your dog is doing. Stark Health transcribes your voice, maps it to today's PT plan, and keeps everyone on the same page."
                ) {
                    VStack(spacing: 12) {
                        Button("Get started") { showAuth = true }
                            .buttonStyle(PrimaryCTAStyle())
                        Button("Sign in") { showAuth = true }
                            .buttonStyle(SecondaryCTAStyle())
                    }
                    .frame(maxWidth: 320)
                }

                featureSection

                Text("Stark Health helps organize care notes and PT routines. It does not provide veterinary medical advice.")
                    .font(.caption)
                    .foregroundStyle(StarkTheme.mutedForeground)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 32)
            }
        }
        .background(StarkTheme.background)
        .sheet(isPresented: $showAuth, onDismiss: handleAuthDismiss) {
            AuthSheetView()
        }
    }

    private var landingHeader: some View {
        HStack {
            Text("Stark Health")
                .font(.headline.weight(.semibold))
                .foregroundStyle(StarkTheme.primary)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var headline: Text {
        Text("Coordinate ")
        + Text("Stark's daily PT").foregroundStyle(StarkTheme.primary)
        + Text(" by talking to the app")
    }

    private var featureSection: some View {
        VStack(spacing: 28) {
            FeatureCardView(systemImage: "mic.fill", title: "Speak, don't tap", subtitle: "Record a care update in seconds instead of checking boxes.")
            FeatureCardView(systemImage: "list.clipboard.fill", title: "Daily PT plan", subtitle: "Configurable stretches, workouts, and checkpoints.")
            FeatureCardView(systemImage: "heart.fill", title: "Shared care log", subtitle: "Family and walkers see the same structured status.")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
    }

    private func handleAuthDismiss() {
        guard clerk.user != nil else { return }
        Task {
            session.configure(clerk: clerk)
            await UserSyncService(apiClient: session.apiClient).syncCurrentUser(clerk: clerk)
            await session.bootstrap()
        }
    }
}

private struct PrimaryCTAStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(StarkTheme.primary)
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

private struct SecondaryCTAStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 48)
            .overlay { Capsule().stroke(StarkTheme.primary, lineWidth: 1) }
            .foregroundStyle(StarkTheme.primary)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}
