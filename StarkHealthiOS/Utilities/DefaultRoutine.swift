import Foundation

enum DefaultRoutine {
    static let name = "Mobility & strength routine"

    struct Item: Identifiable {
        let id = UUID()
        let name: String
        let category: String
        let frequency: String
    }

    static let items: [Item] = [
        Item(name: "Morning stretch routine", category: "Stretch", frequency: "Daily · morning"),
        Item(name: "Evening stretch routine", category: "Stretch", frequency: "Daily · evening"),
        Item(name: "Assisted strength workout", category: "Strength", frequency: "Every other day"),
        Item(name: "Short controlled walk", category: "Mobility", frequency: "Daily"),
        Item(name: "Mobility/pain check", category: "Checkpoint", frequency: "Daily")
    ]
}
