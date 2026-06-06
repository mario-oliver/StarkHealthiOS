import SwiftUI

struct DogSwitcherMenu: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        Menu {
            ForEach(session.dogs) { dog in
                Button(dog.name) {
                    session.selectDog(dog.id)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(session.activeDog?.name ?? "Dog")
                    .font(.subheadline.weight(.medium))
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .foregroundStyle(StarkTheme.primary)
        }
    }
}
