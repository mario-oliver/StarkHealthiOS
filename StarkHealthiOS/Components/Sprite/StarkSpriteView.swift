import SwiftUI

struct StarkSpriteView: View {
    let animation: SpriteAnimation
    var size: SpriteSize = .medium
    var loop: Bool?
    var animated: Bool?
    var onComplete: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var completed = false

    private var definition: SpriteAnimationDefinition {
        SpriteAnimationCatalog.definition(for: animation)
    }

    private var shouldAnimate: Bool {
        if let animated { return animated }
        return !reduceMotion
    }

    private var shouldLoop: Bool {
        loop ?? definition.loops
    }

    var body: some View {
        Group {
            if shouldAnimate {
                TimelineView(.animation(minimumInterval: 1 / definition.fps)) { context in
                    spriteImage(at: context.date)
                }
            } else {
                spriteImage(at: .distantPast)
            }
        }
        .frame(width: size.points, height: size.points)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func spriteImage(at date: Date) -> some View {
        let index = frameIndex(at: date)
        Image(SpriteAnimationCatalog.frameAssetName(animation: animation, frameIndex: index))
            .resizable()
            .scaledToFit()
            .task(id: index) {
                guard !shouldLoop, index == definition.frameCount - 1, !completed else { return }
                completed = true
                onComplete?()
            }
    }

    private func frameIndex(at date: Date) -> Int {
        let elapsed = date.timeIntervalSinceReferenceDate
        let frameDuration = 1 / definition.fps
        let rawIndex = Int(elapsed / frameDuration)
        if shouldLoop {
            return rawIndex % definition.frameCount
        }
        return min(rawIndex, definition.frameCount - 1)
    }
}
