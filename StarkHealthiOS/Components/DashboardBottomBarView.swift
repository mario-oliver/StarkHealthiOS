import SwiftUI

struct DashboardBottomBarView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                tabItem(.care, title: "Care", systemImage: "heart.text.square")
                tabItem(.exercises, title: "Exercises", systemImage: "list.clipboard")
                tabItem(.profile, title: "Profile", systemImage: "dog")
            }
            .padding(4)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(StarkTheme.border.opacity(0.5)))

            if session.voiceRecord.isActive {
                VoiceRecordButton(
                    isProcessing: session.voiceRecord.isProcessing,
                    onRecordingComplete: { data in
                        await session.voiceRecord.complete(data)
                    }
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private func tabItem(_ tab: DashboardTab, title: String, systemImage: String) -> some View {
        let selected = session.selectedTab == tab
        Button {
            session.selectedTab = tab
        } label: {
            VStack(spacing: 2) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: selected ? .semibold : .regular))
                Text(title)
                    .font(.caption2)
            }
            .foregroundStyle(selected ? StarkTheme.foreground : StarkTheme.mutedForeground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(selected ? Color(.tertiarySystemFill) : Color.clear)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
