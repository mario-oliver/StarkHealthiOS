import ClerkKitUI
import SwiftUI

struct DashboardHeaderView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        HStack {
            Text("Stark Health")
                .font(.headline.weight(.semibold))
                .foregroundStyle(StarkTheme.primary)

            Spacer()

            if session.dogs.count > 1 {
                DogSwitcherMenu()
            }

            UserButton()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(StarkTheme.background.opacity(0.92))
    }
}
