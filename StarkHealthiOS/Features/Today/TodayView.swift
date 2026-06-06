import SwiftUI

struct TodayView: View {
    @Environment(SessionStore.self) private var session

    @State private var payload: TodayPayload?
    @State private var loading = true
    @State private var error: String?
    @State private var isTranscribing = false
    @State private var pollTask: Task<Void, Never>?
    @State private var voiceRecordId = UUID()

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
                DogHeroView(
                    dogId: dogId,
                    photoUrl: payload.dog.photoUrl,
                    name: payload.dog.name,
                    date: CareDisplay.formatDisplayDate(payload.date)
                )

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

                if let error {
                    Text(error).font(.caption).foregroundStyle(.red)
                }

                NavigationLink {
                    BucketDetailView(dogId: dogId, bucket: .activity)
                } label: {
                    BucketSummaryCardView(bucket: .activity, data: payload.buckets.activity)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    BucketDetailView(dogId: dogId, bucket: .mobility)
                } label: {
                    BucketSummaryCardView(bucket: .mobility, data: payload.buckets.mobility)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    BucketDetailView(dogId: dogId, bucket: .recovery)
                } label: {
                    BucketSummaryCardView(bucket: .recovery, data: payload.buckets.recovery)
                }
                .buttonStyle(.plain)

                if let recent = payload.dailyLog.voiceNotes.first {
                    sectionTitle("Recent note")
                    Text("\"\(recent.transcript.prefix(200))\(recent.transcript.count > 200 ? "…" : "")\"")
                        .font(.subheadline)
                        .foregroundStyle(StarkTheme.mutedForeground)
                }

                Text("Stark Health helps organize care notes and PT routines. It does not provide veterinary medical advice.")
                    .font(.caption2)
                    .foregroundStyle(StarkTheme.mutedForeground)
                    .padding(.top, 8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            registerVoiceRecord()
            startPollingIfNeeded(payload)
        }
        .onDisappear {
            session.voiceRecord.deactivate(id: voiceRecordId)
            pollTask?.cancel()
        }
        .onChange(of: isTranscribing) { _, _ in registerVoiceRecord() }
        .onChange(of: payload.dailyLog.voiceNotes.count) { _, _ in
            registerVoiceRecord()
            startPollingIfNeeded(payload)
        }
    }

    private func registerVoiceRecord() {
        guard payload != nil, dogId != nil else {
            session.voiceRecord.deactivate(id: voiceRecordId)
            return
        }
        session.voiceRecord.isProcessing = isTranscribing || (payload.map(hasProcessingNotes) ?? false)
        session.voiceRecord.activate(id: voiceRecordId) { data in
            guard let dogId else { return }
            await handleRecording(data, dogId: dogId)
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
        registerVoiceRecord()
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
                buckets: result.buckets,
                progress: result.progress
            )
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }
}
