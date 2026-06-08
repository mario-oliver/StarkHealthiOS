import Foundation

/// The source from which sprite frames are resolved.
/// `.bundled` uses the asset catalog (default Stark frames).
/// `.remote` loads frames authenticated through the API.
enum SpriteSource: Sendable {
    case bundled
    case remote(spriteSet: SpriteSetPayload)
}

extension SpriteSource {
    /// Build the frame asset name for bundled lookup or the frame key for remote.
    func frameKey(animation: SpriteAnimation, frameIndex: Int) -> String {
        let padded = String(format: "%03d", frameIndex + 1)
        return "\(animation.rawValue)_\(padded)"
    }

    /// Return the remote frame identifier (e.g. "idle_001") for a given animation.
    /// Returns nil if this animation isn't in the remote manifest.
    func remoteFrameKey(animation: SpriteAnimation, frameIndex: Int) -> String? {
        guard case .remote(let spriteSet) = self else { return nil }
        let animEntry = spriteSet.manifest.animations[animation.rawValue]
        guard let entry = animEntry, frameIndex < entry.frames else { return nil }
        return entry.keys[safe: frameIndex] ?? frameKey(animation: animation, frameIndex: frameIndex)
    }

    var isRemote: Bool {
        if case .remote = self { return true }
        return false
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
