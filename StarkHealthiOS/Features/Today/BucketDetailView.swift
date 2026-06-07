import SwiftUI

struct BucketDetailView: View {
    @Environment(SessionStore.self) private var session

    let dogId: String
    let bucket: CareBucket

    @State private var payload: TodayPayload?
    @State private var loading = true
    @State private var error: String?
    @State private var isTranscribing = false
    @State private var addingTask = false
    @State private var newTaskName = ""
    @State private var pollTask: Task<Void, Never>?
    @State private var voiceRecordId = UUID()

    private var date: String { CareDisplay.localDateString() }

    private var bucketData: BucketPayload? {
        guard let payload else { return nil }
        switch bucket {
        case .activity: return payload.buckets.activity
        case .mobility: return payload.buckets.mobility
        case .recovery: return payload.buckets.recovery
        }
    }

    private var title: String { CareDisplay.bucketLabel(bucket) }

    private var scoreTitle: String {
        switch bucket {
        case .activity: return "Activity score"
        case .mobility: return "Mobility score"
        case .recovery: return "Recovery score"
        }
    }

    private var scoreUpdating: Bool {
        guard let payload else { return false }
        let hasProcessing = payload.dailyLog.voiceNotes.contains {
            $0.processingStatus == .pending || $0.processingStatus == .transcribed
        }
        if hasProcessing { return true }
        guard
            let latestVoice = payload.dailyLog.latestVoiceNoteAt,
            let scoreComputed = payload.dailyLog.scoreComputedAt
        else { return false }
        return latestVoice > scoreComputed
    }

    var body: some View {
        Group {
            if loading && payload == nil {
                SpriteOverlayView(preset: .dailyPlanLoading)
            } else if let payload, let bucketData {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(CareDisplay.formatDisplayDate(payload.date))
                            .font(.subheadline)
                            .foregroundStyle(StarkTheme.mutedForeground)

                        if bucket != .recovery, let progress = bucketData.progress, progress.total > 0 {
                            Text("\(progress.completed) of \(progress.total) complete")
                                .font(.subheadline)
                                .foregroundStyle(StarkTheme.primary)
                        }

                        if let error {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }

                        if bucket == .recovery || bucket == .mobility || bucketData.score != nil {
                            BucketScoreCardView(
                                title: scoreTitle,
                                score: bucketData.score,
                                updating: scoreUpdating && bucket != .activity
                            )
                        }

                        Text("TASKS")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(StarkTheme.mutedForeground)

                        ForEach(bucketData.tasks) { task in
                            TaskRowView(
                                task: task,
                                dogId: dogId,
                                apiClient: session.apiClient,
                                onUpdated: { await loadToday() }
                            )
                        }

                        if bucketData.tasks.isEmpty {
                            Text("No tasks yet for this bucket.")
                                .font(.subheadline)
                                .foregroundStyle(StarkTheme.mutedForeground)
                        }

                        if !bucketData.observations.isEmpty {
                            Text("OBSERVATIONS")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(StarkTheme.mutedForeground)
                                .padding(.top, 8)

                            ForEach(bucketData.observations) { obs in
                                ObservationCardView(observation: obs)
                            }
                        }

                        if addingTask {
                            HStack(spacing: 8) {
                                TextField("Task name", text: $newTaskName)
                                    .textFieldStyle(.roundedBorder)
                                Button("Add") {
                                    Task { await addTask(logId: payload.dailyLog.id) }
                                }
                                .disabled(newTaskName.trimmingCharacters(in: .whitespaces).isEmpty)
                                Button("Cancel") {
                                    addingTask = false
                                    newTaskName = ""
                                }
                            }
                        } else {
                            Button("Add manually") {
                                addingTask = true
                            }
                            .font(.subheadline)
                        }
                    }
                    .padding()
                    .padding(.bottom, 24)
                }
                .onAppear {
                    registerVoiceRecord(payload: payload)
                    startPollingIfNeeded(payload)
                }
                .onDisappear {
                    session.voiceRecord.deactivate(id: voiceRecordId)
                }
                .onChange(of: isTranscribing) { _, _ in
                    registerVoiceRecord(payload: payload)
                }
                .onChange(of: payload.dailyLog.voiceNotes.count) { _, _ in
                    registerVoiceRecord(payload: payload)
                    startPollingIfNeeded(payload)
                }
            } else {
                Text(error ?? "Could not load bucket.")
                    .foregroundStyle(.red)
            }
        }
        .navigationTitle(title)
        .background(StarkTheme.background)
        .overlay {
            if isTranscribing || session.voiceRecord.isProcessing {
                SpriteOverlayView(preset: .voiceProcessing)
            }
        }
        .task { await loadToday() }
        .onDisappear { pollTask?.cancel() }
    }

    private func registerVoiceRecord(payload: TodayPayload) {
        session.voiceRecord.isProcessing = isTranscribing || hasProcessingNotes(payload)
        session.voiceRecord.activate(id: voiceRecordId) { data in
            await handleRecording(data)
        }
    }

    private func loadToday() async {
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

    private func addTask(logId: String) async {
        let name = newTaskName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        do {
            _ = try await session.apiClient.createDailyTask(
                dogId,
                input: CreateDailyTaskInput(
                    dailyCareLogId: logId,
                    bucket: bucket,
                    name: name
                )
            )
            newTaskName = ""
            addingTask = false
            await loadToday()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func handleRecording(_ data: Data) async {
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
}
