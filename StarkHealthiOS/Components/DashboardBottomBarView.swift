import SwiftUI

struct DashboardBottomBarView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                if session.selectedTab == .care {
                    careTabItem(.today, title: "Today", systemImage: "sun.max")
                    careTabItem(.calendar, title: "Calendar", systemImage: "calendar")
                    careTabItem(.history, title: "History", systemImage: "clock")
                } else {
                    mainTabItem(.care, title: "Care", systemImage: "heart.text.square")
                }
                mainTabItem(.exercises, title: "Exercises", systemImage: "list.clipboard")
                mainTabItem(.profile, title: "Profile", systemImage: "dog")
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
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func mainTabItem(_ tab: DashboardTab, title: String, systemImage: String) -> some View {
        let selected = session.selectedTab == tab
        Button {
            session.selectedTab = tab
            if tab == .care {
                session.careSubTab = .today
            }
        } label: {
            tabLabel(title: title, systemImage: systemImage, selected: selected)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func careTabItem(_ tab: CareSubTab, title: String, systemImage: String) -> some View {
        let selected = session.careSubTab == tab
        Button {
            session.selectedTab = .care
            session.careSubTab = tab
        } label: {
            tabLabel(title: title, systemImage: systemImage, selected: selected)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func tabLabel(title: String, systemImage: String, selected: Bool) -> some View {
        VStack(spacing: 2) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: selected ? .semibold : .regular))
            Text(title)
                .font(.caption2)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(selected ? StarkTheme.foreground : StarkTheme.mutedForeground)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 2)
        .background(selected ? Color(.tertiarySystemFill) : Color.clear)
        .clipShape(Capsule())
    }
}
