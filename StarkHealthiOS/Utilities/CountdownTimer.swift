import Foundation
import Observation

@MainActor
@Observable
final class CountdownTimer {
    private(set) var remainingSeconds: Int = 0
    private var task: Task<Void, Never>?

    var isRunning: Bool { task != nil }

    func start(seconds: Int, onComplete: @escaping () -> Void) {
        stop()
        remainingSeconds = max(0, seconds)
        task = Task {
            while remainingSeconds > 0, !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                remainingSeconds -= 1
            }
            if remainingSeconds == 0 {
                onComplete()
            }
            task = nil
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    func reset(to seconds: Int) {
        stop()
        remainingSeconds = seconds
    }
}
