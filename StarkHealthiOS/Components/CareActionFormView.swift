import SwiftUI

struct CareActionFormView: View {
    @Environment(\.dismiss) private var dismiss

    @State var name: String
    @State var description: String
    @State var category: CareActionCategory
    @State var frequency: CareActionFrequency
    @State var timeOfDay: CareActionTimeOfDay?
    @State var instructions: String

    let title: String
    let onSave: (CreateCareActionInput) async throws -> Void

    init(
        title: String,
        existing: CareActionRecord? = nil,
        onSave: @escaping (CreateCareActionInput) async throws -> Void
    ) {
        self.title = title
        self.onSave = onSave
        _name = State(initialValue: existing?.name ?? "")
        _description = State(initialValue: existing?.description ?? "")
        _category = State(initialValue: existing?.category ?? .stretch)
        _frequency = State(initialValue: existing?.frequency ?? .daily)
        _timeOfDay = State(initialValue: existing?.timeOfDay)
        _instructions = State(initialValue: existing?.instructions ?? "")
    }

    @State private var busy = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                    Picker("Category", selection: $category) {
                        ForEach(CareActionCategory.allCases, id: \.self) { value in
                            Text(value.rawValue.replacingOccurrences(of: "_", with: " ")).tag(value)
                        }
                    }
                    Picker("Frequency", selection: $frequency) {
                        ForEach(CareActionFrequency.allCases, id: \.self) { value in
                            Text(value.rawValue.replacingOccurrences(of: "_", with: " ")).tag(value)
                        }
                    }
                    Picker("Time of day", selection: $timeOfDay) {
                        Text("Anytime").tag(CareActionTimeOfDay?.none)
                        ForEach(CareActionTimeOfDay.allCases, id: \.self) { value in
                            Text(value.rawValue.capitalized).tag(Optional(value))
                        }
                    }
                    TextField("Instructions", text: $instructions, axis: .vertical)
                }

                if let error {
                    Section { Text(error).foregroundStyle(.red) }
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(busy || name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() async {
        busy = true
        error = nil
        defer { busy = false }
        do {
            try await onSave(
                CreateCareActionInput(
                    name: name.trimmingCharacters(in: .whitespaces),
                    description: description.nilIfEmpty,
                    category: category,
                    frequency: frequency,
                    timeOfDay: timeOfDay,
                    instructions: instructions.nilIfEmpty
                )
            )
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
