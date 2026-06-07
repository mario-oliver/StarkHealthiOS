import SwiftUI

struct SpriteCompletionFlashView: View {
    let visible: Bool
    let seed: String
    var duration: Duration = .seconds(2.5)
    var onDismiss: (() -> Void)?

    var body: some View {
        Group {
            if visible {
                SpriteOverlayView(
                    animation: SpriteCompletionAnimation.pick(seed: seed),
                    message: "Nice work.",
                    subtext: "Logged for today.",
                    mode: .inline,
                    size: .small
                )
                .padding(.vertical, 8)
                .task {
                    try? await Task.sleep(for: duration)
                    onDismiss?()
                }
            }
        }
    }
}
