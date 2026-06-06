import SwiftUI

struct VoiceIntroSheet: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(StarkTheme.primary)

            Text("Voice-first care logging")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text("Tap the microphone and say what happened today — walks, exercises, mood, mobility notes. AI organizes everything into the right buckets for you.")
                .font(.body)
                .foregroundStyle(StarkTheme.mutedForeground)
                .multilineTextAlignment(.center)

            Text("You can also log tasks manually anytime.")
                .font(.subheadline)
                .foregroundStyle(StarkTheme.mutedForeground)
                .multilineTextAlignment(.center)

            Button("Got it") {
                onContinue()
            }
            .buttonStyle(.borderedProminent)
            .tint(StarkTheme.primary)
            .padding(.top, 8)
        }
        .padding(28)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
