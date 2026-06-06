import AVFoundation
import Foundation

@MainActor
final class AudioRecorderService: NSObject, Observable {
    private var recorder: AVAudioRecorder?
    private(set) var outputURL: URL?

    func startRecording() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true)

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("recording-\(UUID().uuidString).wav")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]

        recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder?.record()
        outputURL = url
    }

    func stopRecording() -> Data? {
        recorder?.stop()
        recorder = nil
        defer { try? AVAudioSession.sharedInstance().setActive(false) }

        guard let url = outputURL else { return nil }
        return try? Data(contentsOf: url)
    }
}
