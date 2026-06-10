import SwiftUI

struct StarkSpriteView: View {
    let animation: SpriteAnimation
    var size: SpriteSize = .medium
    var loop: Bool?
    var animated: Bool?
    var onComplete: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.spriteSource) private var spriteSource
    @Environment(SessionStore.self) private var session
    @State private var completed = false
    @State private var remoteFrames: [Int: UIImage] = [:]
    @State private var prefetchTask: Task<Void, Never>?

    private var definition: SpriteAnimationDefinition {
        // If we have a remote manifest entry for this animation, use its frame count/fps
        if case .remote(let set) = spriteSource,
           let entry = set.manifest.animations[animation.rawValue] {
            return SpriteAnimationDefinition(
                frameCount: entry.frames,
                fps: entry.fps,
                loops: entry.loop
            )
        }
        return SpriteAnimationCatalog.definition(for: animation)
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
        .onChange(of: animation) { _, _ in startPrefetch() }
        .onChange(of: spriteSource.isRemote) { _, _ in startPrefetch() }
        .onAppear { startPrefetch() }
        .onDisappear { prefetchTask?.cancel() }
    }

    @ViewBuilder
    private func spriteImage(at date: Date) -> some View {
        let index = frameIndex(at: date)

        if case .remote(let set) = spriteSource,
           let entry = set.manifest.animations[animation.rawValue],
           entry.keys[safe: index] != nil,
           let uiImage = remoteFrames[index] {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .task(id: index, priority: .background) {
                    triggerComplete(index: index)
                }
        } else if case .remote = spriteSource {
            // Remote source but frame not yet loaded — show placeholder
            Rectangle()
                .fill(Color.clear)
                .frame(width: size.points, height: size.points)
        } else {
            Image(SpriteAnimationCatalog.frameAssetName(animation: animation, frameIndex: index))
                .resizable()
                .scaledToFit()
                .task(id: index) {
                    triggerComplete(index: index)
                }
        }
    }

    private func triggerComplete(index: Int) {
        guard !shouldLoop, index == definition.frameCount - 1, !completed else { return }
        completed = true
        onComplete?()
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

    private func startPrefetch() {
        guard case .remote(let set) = spriteSource,
              let entry = set.manifest.animations[animation.rawValue] else { return }

        prefetchTask?.cancel()
        let loader = SpriteFrameLoaderStore.shared.loader
        let dogId = set.dogId
        let animName = animation.rawValue
        let keys = entry.keys
        let apiClient = session.apiClient

        prefetchTask = Task {
            await withTaskGroup(of: (Int, UIImage?).self) { group in
                for (idx, key) in keys.enumerated() {
                    group.addTask {
                        let image = await loader.load(dogId: dogId, animation: SpriteAnimation(rawValue: animName)!, frameKey: key) {
                            anim, frameKey in
                            try await apiClient.fetchSpriteFrameData(dogId, animation: anim, frame: frameKey)
                        }
                        return (idx, image)
                    }
                }
                for await (idx, image) in group {
                    if let image, !Task.isCancelled {
                        await MainActor.run { remoteFrames[idx] = image }
                    }
                }
            }
        }
    }
}

// MARK: - Environment key for SpriteSource

private struct SpriteSourceKey: EnvironmentKey {
    static let defaultValue: SpriteSource = .bundled
}

extension EnvironmentValues {
    var spriteSource: SpriteSource {
        get { self[SpriteSourceKey.self] }
        set { self[SpriteSourceKey.self] = newValue }
    }
}


private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
