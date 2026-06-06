import SwiftUI

struct VoiceRecordButton: View {
    var disabled = false
    var isProcessing = false
    let onRecordingComplete: (Data) async -> Void

    @State private var recorder = AudioRecorderService()
    @State private var isRecording = false

    var body: some View {
        Group {
            if isProcessing {
                ProgressView()
                    .tint(.white)
                    .frame(width: 56, height: 56)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            } else if isRecording {
                Button {
                    isRecording = false
                    if let data = recorder.stopRecording() {
                        Task { await onRecordingComplete(data) }
                    }
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
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
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(StarkTheme.primary)
                        .clipShape(Circle())
                }
                .disabled(disabled)
            }
        }
        .accessibilityLabel(isRecording ? "Stop recording" : "Record care update")
    }
}
