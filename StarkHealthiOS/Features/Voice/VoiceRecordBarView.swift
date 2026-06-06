import SwiftUI

struct VoiceRecordBarView: View {
    var disabled = false
    var isProcessing = false
    var hint = "Tap to record a care update."
    let onRecordingComplete: (Data) async -> Void

    @State private var recorder = AudioRecorderService()
    @State private var isRecording = false

    var body: some View {
        VStack(spacing: 8) {
            if isRecording {
                Button {
                    isRecording = false
                    if let data = recorder.stopRecording() {
                        Task { await onRecordingComplete(data) }
                    }
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                        .frame(width: 64, height: 64)
                        .background(.red)
                        .clipShape(Circle())
                }
            } else {
                Button {
                    do {
                        try recorder.startRecording()
                        isRecording = true
                    } catch {
                        print("Recording failed: \(error)")
                    }
                } label: {
                    Image(systemName: "mic.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                        .frame(width: 64, height: 64)
                        .background(StarkTheme.primary)
                        .clipShape(Circle())
                }
                .disabled(disabled || isProcessing)
            }

            Text(isProcessing ? "Processing voice update…" : hint)
                .font(.caption)
                .foregroundStyle(StarkTheme.mutedForeground)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 24)
        .background(.ultraThinMaterial)
    }
}
