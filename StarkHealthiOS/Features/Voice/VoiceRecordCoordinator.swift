import Foundation
import Observation

@MainActor
@Observable
final class VoiceRecordCoordinator {
    var isProcessing = false

    private var handlers: [UUID: (Data) async -> Void] = [:]
    private var stack: [UUID] = []

    var isActive: Bool { !stack.isEmpty }

    func activate(id: UUID, handler: @escaping (Data) async -> Void) {
        handlers[id] = handler
        if !stack.contains(id) {
            stack.append(id)
        }
    }

    func deactivate(id: UUID) {
        handlers[id] = nil
        stack.removeAll { $0 == id }
    }

    func complete(_ data: Data) async {
        guard let id = stack.last, let handler = handlers[id] else { return }
        await handler(data)
    }
}
