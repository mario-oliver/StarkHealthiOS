import Foundation

enum ActiveDogStore {
    private static let storageKey = "stark-active-dog-id"

    static func getActiveDogId() -> String? {
        UserDefaults.standard.string(forKey: storageKey)
    }

    static func setActiveDogId(_ id: String) {
        UserDefaults.standard.set(id, forKey: storageKey)
    }

    static func resolveDogId(dogs: [DogRecord]) -> String {
        guard !dogs.isEmpty else { fatalError("No dogs available") }
        if let active = getActiveDogId(), dogs.contains(where: { $0.id == active }) {
            return active
        }
        return dogs[0].id
    }
}
