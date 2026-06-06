import Foundation

struct DogProfileFormValues {
    var name: String = ""
    var breed: String = ""
    var age: String = ""
    var sex: DogSex?
    var weightLbs: String = ""
    var condition: String = ""
    var vetName: String = ""
    var vetPhone: String = ""
    var notes: String = ""

    static func empty() -> DogProfileFormValues { DogProfileFormValues() }

    static func from(dog: DogRecord) -> DogProfileFormValues {
        DogProfileFormValues(
            name: dog.name,
            breed: dog.breed ?? "",
            age: dog.age.map(String.init) ?? "",
            sex: dog.sex,
            weightLbs: dog.weightLbs.map { String($0) } ?? "",
            condition: dog.condition ?? "",
            vetName: dog.vetName ?? "",
            vetPhone: dog.vetPhone ?? "",
            notes: dog.notes ?? ""
        )
    }

    func toCreatePayload(photoKey: String?) -> CreateDogInput {
        CreateDogInput(
            name: name.trimmingCharacters(in: .whitespaces),
            breed: optionalTrimmed(breed),
            age: Int(age.trimmingCharacters(in: .whitespaces)),
            sex: sex,
            weightLbs: Double(weightLbs.trimmingCharacters(in: .whitespaces)),
            condition: optionalTrimmed(condition),
            vetName: optionalTrimmed(vetName),
            vetPhone: optionalTrimmed(vetPhone),
            photoKey: photoKey,
            notes: optionalTrimmed(notes)
        )
    }

    func toUpdatePayload() -> UpdateDogInput {
        UpdateDogInput(
            name: name.trimmingCharacters(in: .whitespaces),
            breed: optionalTrimmed(breed),
            age: Int(age.trimmingCharacters(in: .whitespaces)),
            sex: sex,
            weightLbs: Double(weightLbs.trimmingCharacters(in: .whitespaces)),
            condition: optionalTrimmed(condition),
            vetName: optionalTrimmed(vetName),
            vetPhone: optionalTrimmed(vetPhone),
            notes: optionalTrimmed(notes)
        )
    }

    func validate() -> String? {
        if name.trimmingCharacters(in: .whitespaces).isEmpty { return "Name is required." }
        if !age.trimmingCharacters(in: .whitespaces).isEmpty {
            guard let value = Int(age), value >= 0 else { return "Enter a valid age in years." }
        }
        if !weightLbs.trimmingCharacters(in: .whitespaces).isEmpty {
            guard let value = Double(weightLbs), value > 0 else { return "Enter a valid weight in pounds." }
        }
        return nil
    }

    private func optionalTrimmed(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? nil : trimmed
    }
}

enum DogProfileFormSupport {
    static let sexOptions: [(DogSex, String)] = [
        (.male, "Male"),
        (.female, "Female"),
        (.unknown, "Unknown")
    ]

    static func formatDogSex(_ sex: DogSex?) -> String? {
        guard let sex else { return nil }
        return sexOptions.first(where: { $0.0 == sex })?.1 ?? sex.rawValue
    }
}
