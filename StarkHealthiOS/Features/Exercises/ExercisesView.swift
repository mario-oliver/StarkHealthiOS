import SwiftUI

struct ExercisesView: View {
    @Environment(SessionStore.self) private var session

    @State private var tab: ExercisesTab = .routine
    @State private var routineBucket: CareBucket = .activity
    @State private var plan: CarePlanPayload?
    @State private var schedulePayload: TodayPayload?
    @State private var scheduleDate = CareDisplay.localDateString()
    @State private var loading = true
    @State private var error: String?
    @State private var showCreateForm = false
    @State private var showAgent = false
    @State private var editingAction: CareActionRecord?
    @State private var deactivatingAction: CareActionRecord?
    @State private var busy = false

    private enum ExercisesTab: String, CaseIterable {
        case routine = "Routine"
        case schedule = "Daily schedule"
    }

    private var dogId: String? { session.activeDogId }

    var body: some View {
        @Bindable var session = session

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Picker("Tab", selection: $tab) {
                    ForEach(ExercisesTab.allCases, id: \.self) { value in
                        Text(value.rawValue).tag(value)
                    }
                }
                .pickerStyle(.segmented)

                if let error {
                    Text(error).font(.caption).foregroundStyle(.red)
                }

                if loading {
                    SpriteOverlayView(preset: .dailyPlanLoading, mode: .inline, size: .small)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                } else {
                    switch tab {
                    case .routine:
                        routineTab
                    case .schedule:
                        scheduleTab
                    }
                }
            }
            .padding(16)
        }
        .background(StarkTheme.background)
        .task(id: dogId) { await loadAll() }
        .onChange(of: tab) { _, _ in Task { await loadAll() } }
        .sheet(isPresented: $showAgent) {
            if let dogId {
                ExerciseAgentView(dogId: dogId) {
                    await loadAll()
                }
            }
        }
        .sheet(isPresented: $showCreateForm) {
            if let dogId {
                CareActionFormView(title: "New exercise") { input in
                    _ = try await session.apiClient.createCareAction(dogId, input: input)
                    await loadAll()
                }
            }
        }
        .sheet(item: $editingAction) { action in
            if let dogId {
                CareActionFormView(title: "Edit exercise", existing: action) { input in
                    _ = try await session.apiClient.updateCareAction(
                        dogId,
                        actionId: action.id,
                        input: UpdateCareActionInput(
                            name: input.name,
                            description: input.description,
                            category: input.category,
                            bucket: input.bucket,
                            frequency: input.frequency,
                            timeOfDay: input.timeOfDay,
                            instructions: input.instructions
                        )
                    )
                    await loadAll()
                }
            }
        }
        .alert("Deactivate exercise?", isPresented: .init(
            get: { deactivatingAction != nil },
            set: { if !$0 { deactivatingAction = nil } }
        )) {
            Button("Deactivate", role: .destructive) {
                if let dogId, let action = deactivatingAction {
                    Task { await deactivate(dogId: dogId, action: action) }
                }
            }
            Button("Cancel", role: .cancel) { deactivatingAction = nil }
        }
    }

    private var filteredRoutineActions: [CareActionRecord] {
        (plan?.actions.filter(\.isActive) ?? []).filter { ($0.bucket ?? .activity) == routineBucket }
    }

    private var routineTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(plan?.name ?? "Care plan")
                    .font(.headline)
                Spacer()
                Button("Create with AI") { showAgent = true }
                    .font(.subheadline)
                    .foregroundStyle(StarkTheme.primary)
                Button("Add exercise") { showCreateForm = true }
                    .font(.subheadline)
            }

            Picker("Bucket", selection: $routineBucket) {
                ForEach(CareBucket.allCases, id: \.self) { bucket in
                    Text(CareDisplay.bucketLabel(bucket)).tag(bucket)
                }
            }
            .pickerStyle(.segmented)

            ForEach(filteredRoutineActions) { action in
                CareActionCardView(
                    action: action,
                    onEdit: { editingAction = action },
                    onDeactivate: { deactivatingAction = action }
                )
            }

            if filteredRoutineActions.isEmpty {
                SpriteOverlayView(preset: .emptyState, mode: .inline, size: .small)
            }
        }
    }

    private var scheduleTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button { shiftSchedule(-1) } label: { Image(systemName: "chevron.left") }
                Spacer()
                Text(CareDisplay.formatDisplayDate(scheduleDate))
                    .font(.subheadline.weight(.medium))
                Spacer()
                Button { shiftSchedule(1) } label: { Image(systemName: "chevron.right") }
            }

            if let schedulePayload, let dogId {
                let tasks = allScheduleTasks(from: schedulePayload)
                if tasks.isEmpty {
                    SpriteOverlayView(preset: .emptyState, mode: .inline, size: .small)
                } else {
                    ForEach(tasks) { task in
                        TaskRowView(
                            task: task,
                            dogId: dogId,
                            apiClient: session.apiClient,
                            onUpdated: { await loadSchedule() }
                        )
                    }
                }
            }
        }
    }

    private func allScheduleTasks(from payload: TodayPayload) -> [DailyTaskRecord] {
        payload.buckets.activity.tasks
            + payload.buckets.mobility.tasks
            + payload.buckets.recovery.tasks
    }

    private func loadAll() async {
        guard let dogId else { return }
        loading = plan == nil
        error = nil
        do {
            plan = try await session.apiClient.getCarePlan(dogId)
            await loadSchedule()
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }

    private func loadSchedule() async {
        guard let dogId else { return }
        do {
            schedulePayload = try await session.apiClient.getToday(dogId, date: scheduleDate)
        } catch {
            schedulePayload = nil
        }
    }

    private func shiftSchedule(_ days: Int) {
        scheduleDate = CareDisplay.shiftDateString(scheduleDate, days: days)
        Task { await loadSchedule() }
    }

    private func deactivate(dogId: String, action: CareActionRecord) async {
        busy = true
        defer { busy = false }
        do {
            _ = try await session.apiClient.deactivateCareAction(dogId, actionId: action.id)
            deactivatingAction = nil
            await loadAll()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

extension CareActionRecord: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
    public static func == (lhs: CareActionRecord, rhs: CareActionRecord) -> Bool { lhs.id == rhs.id }
}
