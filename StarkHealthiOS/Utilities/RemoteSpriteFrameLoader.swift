import UIKit

/// Actor-backed cache for remote sprite frames.
/// Keyed by `{dogId}/{animation}/{frameKey}` to avoid cross-dog conflicts.
actor RemoteSpriteFrameLoader {
    private var cache: [String: UIImage] = [:]
    private var inflight: [String: Task<UIImage?, Never>] = [:]

    typealias FetchFrame = @Sendable (String, String) async throws -> Data

    /// Load a frame, returning from cache if available or fetching and caching.
    func load(
        dogId: String,
        animation: SpriteAnimation,
        frameKey: String,
        fetchFrame: FetchFrame
    ) async -> UIImage? {
        let cacheKey = "\(dogId)/\(animation.rawValue)/\(frameKey)"

        if let cached = cache[cacheKey] {
            return cached
        }

        if let existing = inflight[cacheKey] {
            return await existing.value
        }

        let task: Task<UIImage?, Never> = Task {
            do {
                let data = try await fetchFrame(animation.rawValue, frameKey)
                guard let image = UIImage(data: data) else { return nil }
                await self.store(cacheKey: cacheKey, image: image)
                return image
            } catch {
                return nil
            }
        }

        inflight[cacheKey] = task
        let result = await task.value
        inflight.removeValue(forKey: cacheKey)
        return result
    }

    private func store(cacheKey: String, image: UIImage) {
        cache[cacheKey] = image
    }

    /// Pre-fetch all frames for an animation to avoid flicker during playback.
    func prefetch(
        dogId: String,
        animation: SpriteAnimation,
        keys: [String],
        fetchFrame: FetchFrame
    ) async {
        await withTaskGroup(of: Void.self) { group in
            for key in keys {
                group.addTask {
                    _ = await self.load(
                        dogId: dogId,
                        animation: animation,
                        frameKey: key,
                        fetchFrame: fetchFrame
                    )
                }
            }
        }
    }

    func clear() {
        cache = [:]
    }
}

/// Global shared loader instance — shared across all sprite views.
@MainActor
final class SpriteFrameLoaderStore: ObservableObject {
    static let shared = SpriteFrameLoaderStore()

    let loader = RemoteSpriteFrameLoader()

    private init() {}
}
