import SwiftUI

struct ExerciseMeasurementView: View {
    let targetReps: Int?
    let targetDurationSeconds: Int?
    let completed: Bool
    let busy: Bool
    let onMarkDone: () -> Void

    @State private var timer = CountdownTimer()
    @State private var reps = 0

    private var mode: MeasurementMode {
        MeasurementMode.from(targetReps: targetReps, targetDurationSeconds: targetDurationSeconds)
    }

    var body: some View {
        if completed {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 8) {
                switch mode {
                case .checklist:
                    Button("Mark done", action: onMarkDone)
                        .buttonStyle(.borderedProminent)
                        .tint(StarkTheme.primary)
                        .disabled(busy)
                case .timer:
                    timerView
                case .reps:
                    repsView
                case .both:
                    timerView
                    repsView
                }
            }
        }
    }

    private var timerView: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let targetDurationSeconds {
                Text("Hold: \(CareDisplay.formatCountdown(totalSeconds: timer.remainingSeconds > 0 ? timer.remainingSeconds : targetDurationSeconds))")
                    .font(.caption.monospacedDigit())
            }
            HStack {
                if timer.isRunning {
                    Button("Stop") { timer.stop() }
                } else {
                    Button("Start timer") {
                        timer.start(seconds: targetDurationSeconds ?? 0) {
                            onMarkDone()
                        }
                    }
                }
                Button("Mark done", action: onMarkDone)
                    .disabled(busy)
            }
            .buttonStyle(.bordered)
            .tint(StarkTheme.primary)
        }
    }

    private var repsView: some View {
        HStack {
            Button("-") { reps = max(0, reps - 1) }
            Text("\(reps)\(targetReps.map { " / \($0)" } ?? "")")
                .font(.body.monospacedDigit())
            Button("+") { reps += 1 }
            Button("Mark done") {
                if let targetReps, reps >= targetReps { onMarkDone() } else if targetReps == nil { onMarkDone() }
            }
            .disabled(busy)
        }
        .buttonStyle(.bordered)
        .tint(StarkTheme.primary)
    }
}
