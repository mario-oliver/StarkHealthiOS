import SwiftUI

struct DogProfileFieldsView: View {
    @Binding var form: DogProfileFormValues

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            field("Name", text: $form.name)
            field("Breed", text: $form.breed)
            field("Age (years)", text: $form.age, keyboard: .numberPad)

            VStack(alignment: .leading, spacing: 6) {
                Text("Sex").font(.caption).foregroundStyle(StarkTheme.mutedForeground)
                Picker("Sex", selection: $form.sex) {
                    Text("Not set").tag(DogSex?.none)
                    ForEach(DogSex.allCases, id: \.self) { sex in
                        Text(DogProfileFormSupport.formatDogSex(sex) ?? sex.rawValue).tag(Optional(sex))
                    }
                }
                .pickerStyle(.menu)
            }

            field("Weight (lbs)", text: $form.weightLbs, keyboard: .decimalPad)
            field("Condition / diagnosis", text: $form.condition)
            field("Vet name", text: $form.vetName)
            field("Vet phone", text: $form.vetPhone, keyboard: .phonePad)
            multilineField("Notes", text: $form.notes)
        }
    }

    private func field(_ label: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption).foregroundStyle(StarkTheme.mutedForeground)
            TextField(label, text: text)
                .keyboardType(keyboard)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func multilineField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption).foregroundStyle(StarkTheme.mutedForeground)
            TextField(label, text: text, axis: .vertical)
                .lineLimit(3 ... 6)
                .textFieldStyle(.roundedBorder)
        }
    }
}
