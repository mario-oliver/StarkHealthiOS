import SwiftUI

struct VoiceRecordButton: View {
    var disabled = false
    var isProcessing = false
    let onRecordingComplete: (Data) async -> Void

    @AppStorage("hasSeenVoiceIntro") private var hasSeenVoiceIntro = false
    @State private var recorder = AudioRecorderService()
    @State private var isRecording = false
    @State private var showIntro = false

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
                    if hasSeenVoiceIntro {
                        beginRecording()
                    } else {
                        showIntro = true
                    }
                } label: {
                    Image(systemName: "mic.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(StarkTheme.primary)
                        .clipShape(Circle())
                }
                .disabled(disabled)
            }
        }
        .accessibilityLabel(isRecording ? "Stop recording" : "Record care update")
        .sheet(isPresented: $showIntro) {
            VoiceIntroSheet {
                hasSeenVoiceIntro = true
                showIntro = false
            }
        }
    }

    private func beginRecording() {
        do {
            try recorder.startRecording()
            isRecording = true
        } catch {
            print("Recording failed: \(error)")
        }
    }
}
