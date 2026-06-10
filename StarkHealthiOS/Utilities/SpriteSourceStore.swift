import Foundation
import Observation

/// Manages the resolved SpriteSource for the active dog.
/// Fetch the active sprite set from the API and provide a .remote source
/// when available; fall back to .bundled.
@MainActor
@Observable
final class SpriteSourceStore {
    var source: SpriteSource = .bundled

    private var currentDogId: String?

    func load(dogId: String, apiClient: APIClient) async {
        guard dogId != currentDogId || !source.isRemote else { return }
        currentDogId = dogId

        do {
            if let spriteSet = try await apiClient.getDogSpriteSet(dogId) {
                source = .remote(spriteSet: spriteSet)
            } else {
                source = .bundled
            }
        } catch {
            source = .bundled
        }
    }

    func reset() {
        source = .bundled
        currentDogId = nil
    }
}
