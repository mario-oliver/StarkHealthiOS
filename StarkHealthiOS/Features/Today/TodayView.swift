import SwiftUI

struct TodayView: View {
    @Environment(SessionStore.self) private var session

    @State private var payload: TodayPayload?
    @State private var loading = true
    @State private var error: String?
    @State private var isTranscribing = false
    @State private var pollTask: Task<Void, Never>?

    private var dogId: String? { session.activeDogId }
    private var date: String { CareDisplay.localDateString() }

    var body: some View {
        Group {
            if loading && payload == nil {
                ProgressView("Loading today's care…")
            } else if let payload, let dogId {
                content(payload: payload, dogId: dogId)
            } else {
                VStack(spacing: 12) {
                    Text(error ?? "Could not load today's care.")
                        .foregroundStyle(.red)
                    Button("Retry") { Task { await loadToday() } }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(StarkTheme.background)
        .task(id: dogId) {
            await loadToday()
        }
        .onDisappear {
            pollTask?.cancel()
        }
    }

    @ViewBuilder
    private func content(payload: TodayPayload, dogId: String) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(spacing: 8) {
                    Text("CARE")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(StarkTheme.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    DogHeroView(dogId: dogId, photoUrl: payload.dog.photoUrl, name: payload.dog.name)

                    Text(CareDisplay.formatDisplayDate(payload.date))
                        .font(.subheadline)
                        .foregroundStyle(StarkTheme.mutedForeground)

                    Text("\(payload.progress.completed) of \(payload.progress.total) exercises done")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(StarkTheme.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(StarkTheme.primary.opacity(0.12))
                        .clipShape(Capsule())

                    if let summary = payload.dailyLog.summary {
                        Text(summary)
                            .font(.subheadline)
                            .foregroundStyle(StarkTheme.mutedForeground)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 12)
                            .overlay(alignment: .leading) {
                                Rectangle().fill(StarkTheme.primary).frame(width: 2)
                            }
                    }
                }

                if let error {
                    Text(error).font(.caption).foregroundStyle(.red)
                }

                sectionTitle("Exercises today")
                Text("Speak your update below — tap an exercise to expand and see details.")
                    .font(.caption)
                    .foregroundStyle(StarkTheme.mutedForeground)

                ForEach(payload.dailyLog.dailyCareActions) { action in
                    ExerciseCardView(
                        action: action,
                        dogId: dogId,
                        apiClient: session.apiClient,
                        onUpdated: { await loadToday() }
                    )
                }

                if !payload.dailyLog.healthObservations.isEmpty {
                    sectionTitle("Observations")
                    ForEach(payload.dailyLog.healthObservations) { obs in
                        ObservationCardView(observation: obs)
                    }
                }

                if !payload.dailyLog.voiceNotes.isEmpty {
                    sectionTitle("Voice updates")
                    ForEach(payload.dailyLog.voiceNotes) { note in
                        VoiceNoteCardView(note: note)
                    }
                }

                Text("Stark Health helps organize care notes and PT routines. It does not provide veterinary medical advice.")
                    .font(.caption2)
                    .foregroundStyle(StarkTheme.mutedForeground)
                    .padding(.top, 8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 120)
        }
        .safeAreaInset(edge: .bottom) {
            VoiceRecordBarView(
                isProcessing: isTranscribing || hasProcessingNotes(payload),
                hint: "Record Update — say what Stark did today.",
                onRecordingComplete: { data in
                    await handleRecording(data, dogId: dogId)
                }
            )
        }
        .onAppear { startPollingIfNeeded(payload) }
        .onChange(of: payload.dailyLog.voiceNotes.count) { _, _ in
            startPollingIfNeeded(payload)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption.weight(.medium))
            .tracking(1)
            .foregroundStyle(StarkTheme.mutedForeground)
    }

    private func loadToday() async {
        guard let dogId else { return }
        loading = payload == nil
        do {
            payload = try await session.apiClient.getToday(dogId, date: date)
            error = nil
            if let payload { startPollingIfNeeded(payload) }
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }

    private func hasProcessingNotes(_ payload: TodayPayload) -> Bool {
        payload.dailyLog.voiceNotes.contains {
            $0.processingStatus == .pending || $0.processingStatus == .transcribed
        }
    }

    private func startPollingIfNeeded(_ payload: TodayPayload) {
        pollTask?.cancel()
        guard hasProcessingNotes(payload) else { return }
        pollTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                await loadToday()
                if let payload = self.payload, !hasProcessingNotes(payload) { break }
            }
        }
    }

    private func handleRecording(_ data: Data, dogId: String) async {
        isTranscribing = true
        defer { isTranscribing = false }
        do {
            let result = try await session.apiClient.transcribeVoiceNote(dogId, wavData: data, date: date)
            payload = TodayPayload(
                dog: result.dog,
                date: result.date,
                dailyLog: result.dailyLog,
                progress: result.progress
            )
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }
}
