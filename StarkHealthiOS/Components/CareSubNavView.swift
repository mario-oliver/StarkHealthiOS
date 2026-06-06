import SwiftUI

struct CareSubNavView: View {
    @Binding var selection: CareSubTab

    var body: some View {
        HStack(spacing: 8) {
            ForEach(CareSubTab.allCases, id: \.self) { tab in
                Button(tab.rawValue) {
                    selection = tab
                }
                .font(.subheadline.weight(selection == tab ? .semibold : .regular))
                .foregroundStyle(selection == tab ? StarkTheme.primary : StarkTheme.mutedForeground)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(selection == tab ? StarkTheme.primary.opacity(0.12) : Color.clear)
                .clipShape(Capsule())
            }
            Spacer()
        }
        .padding(.bottom, 8)
    }
}
